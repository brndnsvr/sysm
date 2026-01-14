import Foundation

struct MessagesService {

    // MARK: - Send Message

    func sendMessage(to recipient: String, message: String) throws {
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

    func getRecentConversations(limit: Int = 20) throws -> [Conversation] {
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

    func getMessages(conversationId: String, limit: Int = 30) throws -> [Message] {
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
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("sysm-messages-\(UUID().uuidString).scpt")
        try script.write(to: tempFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempFile) }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = [tempFile.path]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe

        try task.run()
        task.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        if task.terminationStatus != 0 {
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw MessagesError.appleScriptError(errorMessage)
        }

        return String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func escapeForAppleScript(_ string: String) -> String {
        return string.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}

// MARK: - Models

struct Conversation: Codable {
    let id: String
    let name: String
    let participants: String
}

struct Message: Codable {
    let date: String
    let sender: String
    let content: String
}

// MARK: - Errors

enum MessagesError: LocalizedError {
    case appleScriptError(String)
    case messagesNotRunning
    case sendFailed(String)

    var errorDescription: String? {
        switch self {
        case .appleScriptError(let message):
            return "AppleScript error: \(message)"
        case .messagesNotRunning:
            return "Messages app is not running"
        case .sendFailed(let message):
            return "Failed to send message: \(message)"
        }
    }
}
