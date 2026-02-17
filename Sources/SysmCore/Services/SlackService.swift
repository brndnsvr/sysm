import Foundation
import Security

public actor SlackService: SlackServiceProtocol {

    private static let keychainService = "com.brndnsvr.sysm.slack"
    private static let keychainAccount = "bot-token"
    private static let baseURL = "https://slack.com/api"

    public init() {}

    // MARK: - Token Management

    public nonisolated func isConfigured() -> Bool {
        (try? getToken()) != nil
    }

    public nonisolated func setToken(_ token: String) throws {
        try deleteKeychainItem()

        let tokenData = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
            kSecValueData as String: tokenData,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SlackError.apiError("Failed to save token to Keychain (status: \(status))")
        }
    }

    public nonisolated func removeToken() throws {
        try deleteKeychainItem()
    }

    // MARK: - Messaging

    public func sendMessage(channel: String, text: String) async throws -> SlackMessageResult {
        let token = try requireToken()

        let resolvedChannel: String
        if channel.hasPrefix("#") {
            resolvedChannel = String(channel.dropFirst())
        } else {
            resolvedChannel = channel
        }

        let body: [String: Any] = [
            "channel": resolvedChannel,
            "text": text,
        ]

        let response = try await apiRequest("chat.postMessage", token: token, body: body)

        guard let ok = response["ok"] as? Bool, ok else {
            let error = response["error"] as? String ?? "Unknown error"
            if error == "channel_not_found" || error == "not_in_channel" {
                throw SlackError.channelNotFound(channel)
            }
            if error == "invalid_auth" || error == "token_revoked" {
                throw SlackError.invalidToken
            }
            throw SlackError.apiError(error)
        }

        return SlackMessageResult(
            channel: response["channel"] as? String ?? resolvedChannel,
            timestamp: response["ts"] as? String ?? "",
            ok: true
        )
    }

    // MARK: - Status

    public func setStatus(text: String, emoji: String?) async throws {
        let token = try requireToken()

        let statusEmoji = emoji ?? ""
        let profile: [String: Any] = [
            "status_text": text,
            "status_emoji": statusEmoji,
        ]
        let body: [String: Any] = [
            "profile": profile,
        ]

        let response = try await apiRequest("users.profile.set", token: token, body: body)

        guard let ok = response["ok"] as? Bool, ok else {
            let error = response["error"] as? String ?? "Unknown error"
            if error == "invalid_auth" || error == "token_revoked" {
                throw SlackError.invalidToken
            }
            throw SlackError.apiError(error)
        }
    }

    // MARK: - Channels

    public func listChannels(limit: Int) async throws -> [SlackChannel] {
        let token = try requireToken()

        let body: [String: Any] = [
            "limit": limit,
            "types": "public_channel,private_channel",
            "exclude_archived": true,
        ]

        let response = try await apiRequest("conversations.list", token: token, body: body)

        guard let ok = response["ok"] as? Bool, ok else {
            let error = response["error"] as? String ?? "Unknown error"
            if error == "invalid_auth" || error == "token_revoked" {
                throw SlackError.invalidToken
            }
            throw SlackError.apiError(error)
        }

        guard let channels = response["channels"] as? [[String: Any]] else {
            return []
        }

        return channels.compactMap { ch -> SlackChannel? in
            guard let id = ch["id"] as? String,
                  let name = ch["name"] as? String else { return nil }
            return SlackChannel(
                id: id,
                name: name,
                isPrivate: ch["is_private"] as? Bool ?? false,
                memberCount: ch["num_members"] as? Int,
                topic: (ch["topic"] as? [String: Any])?["value"] as? String
            )
        }
    }

    // MARK: - Private

    private nonisolated func getToken() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw SlackError.notConfigured
        }
        return token
    }

    private nonisolated func requireToken() throws -> String {
        try getToken()
    }

    private nonisolated func deleteKeychainItem() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            throw SlackError.apiError("Failed to delete Keychain item (status: \(status))")
        }
    }

    private func apiRequest(_ method: String, token: String, body: [String: Any]) async throws -> [String: Any] {
        let url = URL(string: "\(Self.baseURL)/\(method)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw SlackError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SlackError.networkError("Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            throw SlackError.apiError("HTTP \(httpResponse.statusCode)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SlackError.apiError("Invalid JSON response")
        }

        return json
    }
}
