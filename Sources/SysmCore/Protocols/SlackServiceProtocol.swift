import Foundation

public protocol SlackServiceProtocol: Sendable {
    func isConfigured() -> Bool
    func setToken(_ token: String) throws
    func removeToken() throws
    func sendMessage(channel: String, text: String) async throws -> SlackMessageResult
    func setStatus(text: String, emoji: String?) async throws
    func listChannels(limit: Int) async throws -> [SlackChannel]
}
