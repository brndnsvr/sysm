import Foundation

/// Represents a photo album from the macOS Photos library.
public struct PhotoAlbum: Codable, Sendable {
    public let id: String
    public let title: String
    public let count: Int
    public let type: String

    public init(id: String, title: String, count: Int, type: String) {
        self.id = id
        self.title = title
        self.count = count
        self.type = type
    }

    public func formatted() -> String {
        return "\(title) (\(count) photos) [\(type)]"
    }
}
