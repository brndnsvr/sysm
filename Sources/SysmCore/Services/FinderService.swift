import AppKit
import Foundation

public struct FinderService: FinderServiceProtocol {
    private var appleScript: any AppleScriptRunnerProtocol { Services.appleScriptRunner() }

    public init() {}

    public func open(path: String) throws {
        let url = URL(fileURLWithPath: expandPath(path))
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw FinderError.pathNotFound(path)
        }
        NSWorkspace.shared.open(url)
    }

    public func reveal(path: String) throws {
        let url = URL(fileURLWithPath: expandPath(path))
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw FinderError.pathNotFound(path)
        }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    public func getInfo(path: String) throws -> FileInfo {
        let expanded = expandPath(path)
        let url = URL(fileURLWithPath: expanded)
        let fm = FileManager.default

        guard fm.fileExists(atPath: expanded) else {
            throw FinderError.pathNotFound(path)
        }

        let attrs = try fm.attributesOfItem(atPath: expanded)
        let name = url.lastPathComponent
        let size = (attrs[.size] as? Int64) ?? 0
        let created = attrs[.creationDate] as? Date
        let modified = attrs[.modificationDate] as? Date
        let fileType = attrs[.type] as? FileAttributeType
        let isDirectory = fileType == .typeDirectory
        let isHidden = url.lastPathComponent.hasPrefix(".")

        let kind: String
        if isDirectory {
            kind = "Folder"
        } else {
            kind = url.pathExtension.isEmpty ? "Document" : url.pathExtension.uppercased()
        }

        return FileInfo(
            path: expanded,
            name: name,
            kind: kind,
            size: size,
            sizeFormatted: OutputFormatter.formatFileSize(size),
            created: created,
            modified: modified,
            isDirectory: isDirectory,
            isHidden: isHidden
        )
    }

    public func trash(path: String) throws {
        let expanded = expandPath(path)
        let url = URL(fileURLWithPath: expanded)

        guard FileManager.default.fileExists(atPath: expanded) else {
            throw FinderError.pathNotFound(path)
        }

        try FileManager.default.trashItem(at: url, resultingItemURL: nil)
    }

    public func emptyTrash() throws {
        let script = """
        tell application "Finder"
            empty the trash
        end tell
        """
        _ = try appleScript.run(script, identifier: "finder-empty-trash")
    }

    // MARK: - Private

    private func expandPath(_ path: String) -> String {
        (path as NSString).expandingTildeInPath
    }
}

public enum FinderError: LocalizedError {
    case pathNotFound(String)
    case operationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .pathNotFound(let path):
            return "Path not found: \(path)"
        case .operationFailed(let msg):
            return "Finder operation failed: \(msg)"
        }
    }
}
