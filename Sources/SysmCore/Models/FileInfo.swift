import Foundation

public struct FileInfo: Codable, Sendable {
    public let path: String
    public let name: String
    public let kind: String
    public let size: Int64
    public let sizeFormatted: String
    public let created: Date?
    public let modified: Date?
    public let isDirectory: Bool
    public let isHidden: Bool

    public init(path: String, name: String, kind: String, size: Int64,
                sizeFormatted: String, created: Date?, modified: Date?,
                isDirectory: Bool, isHidden: Bool) {
        self.path = path
        self.name = name
        self.kind = kind
        self.size = size
        self.sizeFormatted = sizeFormatted
        self.created = created
        self.modified = modified
        self.isDirectory = isDirectory
        self.isHidden = isHidden
    }
}
