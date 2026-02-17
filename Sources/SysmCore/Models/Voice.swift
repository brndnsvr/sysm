import Foundation

public struct VoiceInfo: Codable, Sendable {
    public let name: String
    public let language: String
    public let identifier: String

    public init(name: String, language: String, identifier: String) {
        self.name = name
        self.language = language
        self.identifier = identifier
    }
}
