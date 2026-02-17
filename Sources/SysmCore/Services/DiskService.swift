import AppKit
import Foundation

public struct DiskService: DiskServiceProtocol {
    public init() {}

    public func listVolumes() throws -> [VolumeInfo] {
        let fm = FileManager.default
        let keys: [URLResourceKey] = [
            .volumeNameKey, .volumeTotalCapacityKey, .volumeAvailableCapacityKey,
            .volumeIsRemovableKey, .volumeIsInternalKey, .volumeLocalizedFormatDescriptionKey,
        ]

        guard let urls = fm.mountedVolumeURLs(includingResourceValuesForKeys: keys,
                                               options: [.skipHiddenVolumes]) else {
            return []
        }

        return urls.compactMap { url in
            try? buildVolumeInfo(url: url, keys: keys)
        }
    }

    public func getVolume(path: String) throws -> VolumeInfo {
        let expanded = (path as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: expanded)
        let keys: [URLResourceKey] = [
            .volumeNameKey, .volumeTotalCapacityKey, .volumeAvailableCapacityKey,
            .volumeIsRemovableKey, .volumeIsInternalKey, .volumeLocalizedFormatDescriptionKey,
        ]

        guard let volumeURL = try? url.resourceValues(forKeys: [.volumeURLKey]).volume else {
            throw DiskError.volumeNotFound(path)
        }

        return try buildVolumeInfo(url: volumeURL, keys: keys)
    }

    public func getDirectorySize(path: String) throws -> DirectorySize {
        let expanded = (path as NSString).expandingTildeInPath
        let fm = FileManager.default

        guard fm.fileExists(atPath: expanded) else {
            throw DiskError.pathNotFound(path)
        }

        // Use du for fast directory size
        let output = try Shell.run("/usr/bin/du", args: ["-sk", expanded])
        let parts = output.split(separator: "\t")
        let sizeKB = Int64(parts.first ?? "0") ?? 0
        let sizeBytes = sizeKB * 1024

        // Count files
        let countOutput = try Shell.run("/usr/bin/find", args: [expanded, "-type", "f"])
        let fileCount = countOutput.split(separator: "\n").count

        return DirectorySize(
            path: expanded,
            size: sizeBytes,
            sizeFormatted: OutputFormatter.formatFileSize(sizeBytes),
            fileCount: fileCount
        )
    }

    public func ejectVolume(name: String) throws {
        let fm = FileManager.default
        let keys: [URLResourceKey] = [.volumeNameKey]

        guard let urls = fm.mountedVolumeURLs(includingResourceValuesForKeys: keys,
                                               options: [.skipHiddenVolumes]) else {
            throw DiskError.volumeNotFound(name)
        }

        for url in urls {
            if let volName = try? url.resourceValues(forKeys: [.volumeNameKey]).volumeName,
               volName == name {
                try NSWorkspace.shared.unmountAndEjectDevice(at: url)
                return
            }
        }

        throw DiskError.volumeNotFound(name)
    }

    // MARK: - Private

    private func buildVolumeInfo(url: URL, keys: [URLResourceKey]) throws -> VolumeInfo {
        let values = try url.resourceValues(forKeys: Set(keys))
        let name = values.volumeName ?? url.lastPathComponent
        let total = Int64(values.volumeTotalCapacity ?? 0)
        let free = Int64(values.volumeAvailableCapacity ?? 0)
        let used = total - free
        let usedPercent = total > 0 ? Double(used) / Double(total) * 100 : 0

        return VolumeInfo(
            name: name,
            mountPoint: url.path,
            fileSystem: values.volumeLocalizedFormatDescription,
            totalSize: total,
            totalSizeFormatted: OutputFormatter.formatFileSize(total),
            freeSpace: free,
            freeSpaceFormatted: OutputFormatter.formatFileSize(free),
            usedSpace: used,
            usedSpaceFormatted: OutputFormatter.formatFileSize(used),
            usedPercent: usedPercent,
            isRemovable: values.volumeIsRemovable ?? false,
            isInternal: values.volumeIsInternal ?? true
        )
    }
}

public enum DiskError: LocalizedError {
    case volumeNotFound(String)
    case pathNotFound(String)
    case ejectFailed(String)

    public var errorDescription: String? {
        switch self {
        case .volumeNotFound(let name):
            return "Volume not found: \(name)"
        case .pathNotFound(let path):
            return "Path not found: \(path)"
        case .ejectFailed(let msg):
            return "Eject failed: \(msg)"
        }
    }
}
