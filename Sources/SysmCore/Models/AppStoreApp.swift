import Foundation

public struct AppStoreApp: Codable, Sendable {
    public let id: String
    public let name: String
    public let version: String?

    public init(id: String, name: String, version: String? = nil) {
        self.id = id
        self.name = name
        self.version = version
    }
}
