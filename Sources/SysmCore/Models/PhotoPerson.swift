import Foundation

/// Represents a person detected in the Photos library.
public struct PhotoPerson: Codable {
    public let id: String
    public let name: String?
    public let photoCount: Int

    public init(id: String, name: String?, photoCount: Int) {
        self.id = id
        self.name = name
        self.photoCount = photoCount
    }

    public var displayName: String {
        name ?? "Unnamed Person"
    }

    public func formatted() -> String {
        "\(displayName) (\(photoCount) photos)"
    }
}
