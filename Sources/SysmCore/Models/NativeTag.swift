import Foundation

/// Represents a native Reminders tag (hashtag label) from the Core Data database.
public struct NativeTag: Codable, Sendable {
    public let name: String
    public let canonicalName: String
    public let count: Int

    public init(name: String, canonicalName: String, count: Int = 0) {
        self.name = name
        self.canonicalName = canonicalName
        self.count = count
    }

    public func formatted() -> String {
        return "#\(name) (\(count) reminder\(count == 1 ? "" : "s"))"
    }
}
