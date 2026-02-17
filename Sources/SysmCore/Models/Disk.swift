import Foundation

public struct VolumeInfo: Codable, Sendable {
    public let name: String
    public let mountPoint: String
    public let fileSystem: String?
    public let totalSize: Int64
    public let totalSizeFormatted: String
    public let freeSpace: Int64
    public let freeSpaceFormatted: String
    public let usedSpace: Int64
    public let usedSpaceFormatted: String
    public let usedPercent: Double
    public let isRemovable: Bool
    public let isInternal: Bool

    public init(name: String, mountPoint: String, fileSystem: String?, totalSize: Int64,
                totalSizeFormatted: String, freeSpace: Int64, freeSpaceFormatted: String,
                usedSpace: Int64, usedSpaceFormatted: String, usedPercent: Double,
                isRemovable: Bool, isInternal: Bool) {
        self.name = name
        self.mountPoint = mountPoint
        self.fileSystem = fileSystem
        self.totalSize = totalSize
        self.totalSizeFormatted = totalSizeFormatted
        self.freeSpace = freeSpace
        self.freeSpaceFormatted = freeSpaceFormatted
        self.usedSpace = usedSpace
        self.usedSpaceFormatted = usedSpaceFormatted
        self.usedPercent = usedPercent
        self.isRemovable = isRemovable
        self.isInternal = isInternal
    }
}

public struct DirectorySize: Codable, Sendable {
    public let path: String
    public let size: Int64
    public let sizeFormatted: String
    public let fileCount: Int

    public init(path: String, size: Int64, sizeFormatted: String, fileCount: Int) {
        self.path = path
        self.size = size
        self.sizeFormatted = sizeFormatted
        self.fileCount = fileCount
    }
}
