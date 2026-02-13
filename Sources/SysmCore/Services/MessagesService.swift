import Foundation

public struct MessagesService: MessagesServiceProtocol {

    private var appleScript: any AppleScriptRunnerProtocol { Services.appleScriptRunner() }

    public init() {}

    // MARK: - Send Message

    public func sendMessage(to recipient: String, message: String) throws {
        let escapedRecipient = escapeForAppleScript(recipient)
        let escapedMessage = escapeForAppleScript(message)

        let script = """
        tell application "Messages"
            set targetService to 1st account whose service type = iMessage
            set targetBuddy to participant "\(escapedRecipient)" of targetService
            send "\(escapedMessage)" to targetBuddy
        end tell
        """

        _ = try runAppleScript(script)
    }

    // MARK: - Recent Conversations

    public func getRecentConversations(limit: Int = 20) throws -> [Conversation] {
        let script = """
        tell application "Messages"
            set convList to ""
            set convCount to 0
            repeat with c in chats
                if convCount >= \(limit) then exit repeat
                set convCount to convCount + 1
                try
                    set convId to id of c
                    set convName to name of c
                    if convName is missing value then set convName to "Unknown"
                    set participantList to ""
                    repeat with p in participants of c
                        if participantList is not "" then set participantList to participantList & ", "
                        set participantList to participantList & (handle of p)
                    end repeat
                    set convList to convList & convId & "|||" & convName & "|||" & participantList & "###"
                end try
            end repeat
            return convList
        end tell
        """

        let result = try runAppleScript(script)
        if result.isEmpty { return [] }

        return result.components(separatedBy: "###").compactMap { item -> Conversation? in
            let parts = item.components(separatedBy: "|||")
            guard parts.count >= 3 else { return nil }
            return Conversation(
                id: parts[0],
                name: parts[1],
                participants: parts[2]
            )
        }
    }

    // MARK: - Read Conversation

    public func getMessages(conversationId: String, limit: Int = 30) throws -> [Message] {
        let script = """
        tell application "Messages"
            set msgList to ""
            set msgCount to 0
            try
                set targetChat to chat id "\(escapeForAppleScript(conversationId))"
                repeat with m in (messages of targetChat)
                    if msgCount >= \(limit) then exit repeat
                    set msgCount to msgCount + 1
                    try
                        set msgDate to (date of m) as string
                        set msgContent to text of m
                        set msgSender to handle of sender of m
                        set msgList to msgList & msgDate & "|||" & msgSender & "|||" & msgContent & "###"
                    end try
                end repeat
            end try
            return msgList
        end tell
        """

        let result = try runAppleScript(script)
        if result.isEmpty { return [] }

        return result.components(separatedBy: "###").compactMap { item -> Message? in
            let parts = item.components(separatedBy: "|||")
            guard parts.count >= 3 else { return nil }
            return Message(
                date: parts[0],
                sender: parts[1],
                content: parts[2]
            )
        }
    }

    // MARK: - Private Helpers

    private func runAppleScript(_ script: String) throws -> String {
        do {
            return try appleScript.run(script, identifier: "messages")
        } catch AppleScriptError.executionFailed(let message) {
            throw MessagesError.appleScriptError(message)
        }
    }

    private func escapeForAppleScript(_ string: String) -> String {
        appleScript.escape(string)
    }
}

// MARK: - Models

public struct Conversation: Codable {
    public let id: String
    public let name: String
    public let participants: String
}

public struct Message: Codable {
    public let date: String
    public let sender: String
    public let content: String
}

// MARK: - Errors

public enum MessagesError: LocalizedError {
    case appleScriptError(String)
    case messagesNotRunning
    case sendFailed(String)

    public var errorDescription: String? {
        switch self {
        case .appleScriptError(let message):
            return "AppleScript error: \(message)"
        case .messagesNotRunning:
            return "Messages app is not running"
        case .sendFailed(let message):
            return "Failed to send message: \(message)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .appleScriptError:
            return """
            Grant automation permission:
            1. Open System Settings
            2. Navigate to Privacy & Security > Automation
            3. Find Terminal and enable Messages
            4. Restart sysm
            """
        case .messagesNotRunning:
            return """
            Messages app must be running.

            Try:
            1. Open Messages: open -a Messages
            2. Sign in to iMessage if needed
            3. Run the command again
            """
        case .sendFailed:
            return """
            Message send failed.

            Try:
            - Verify recipient phone number or iMessage email
            - Ensure Messages is signed in to iMessage
            - Check internet connection
            - Verify automation permission is granted
            """
        }
    }
}
