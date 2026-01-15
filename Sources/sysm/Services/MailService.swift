import Foundation

struct MailService {

    // MARK: - Accounts

    func getAccounts() throws -> [MailAccount] {
        let script = """
        tell application "Mail"
            set accountList to ""
            repeat with acc in accounts
                set accountList to accountList & (id of acc) & "|||" & (name of acc) & "|||" & (user name of acc) & "###"
            end repeat
            return accountList
        end tell
        """

        let result = try runAppleScript(script)
        if result.isEmpty { return [] }

        return result.components(separatedBy: "###").compactMap { item -> MailAccount? in
            let parts = item.components(separatedBy: "|||")
            guard parts.count >= 3 else { return nil }
            return MailAccount(id: parts[0], name: parts[1], email: parts[2])
        }
    }

    // MARK: - Inbox

    func getInboxMessages(limit: Int = 20) throws -> [MailMessage] {
        let script = """
        tell application "Mail"
            set messageList to ""
            set msgCount to 0
            repeat with msg in (messages of inbox)
                if msgCount >= \(limit) then exit repeat
                set msgCount to msgCount + 1
                set msgId to (id of msg) as string
                set msgSubject to subject of msg
                set msgFrom to sender of msg
                set msgDate to (date received of msg) as string
                set isRead to (read status of msg) as string
                set messageList to messageList & msgId & "|||" & msgSubject & "|||" & msgFrom & "|||" & msgDate & "|||" & isRead & "###"
            end repeat
            return messageList
        end tell
        """

        let result = try runAppleScript(script)
        if result.isEmpty { return [] }

        return result.components(separatedBy: "###").compactMap { item -> MailMessage? in
            let parts = item.components(separatedBy: "|||")
            guard parts.count >= 5 else { return nil }
            return MailMessage(
                id: parts[0],
                subject: parts[1],
                from: parts[2],
                dateReceived: parts[3],
                isRead: parts[4] == "true"
            )
        }
    }

    // MARK: - Unread

    func getUnreadMessages(limit: Int = 50) throws -> [MailMessage] {
        let script = """
        tell application "Mail"
            set messageList to ""
            set msgCount to 0
            repeat with msg in (messages of inbox whose read status is false)
                if msgCount >= \(limit) then exit repeat
                set msgCount to msgCount + 1
                set msgId to (id of msg) as string
                set msgSubject to subject of msg
                set msgFrom to sender of msg
                set msgDate to (date received of msg) as string
                set messageList to messageList & msgId & "|||" & msgSubject & "|||" & msgFrom & "|||" & msgDate & "###"
            end repeat
            return messageList
        end tell
        """

        let result = try runAppleScript(script)
        if result.isEmpty { return [] }

        return result.components(separatedBy: "###").compactMap { item -> MailMessage? in
            let parts = item.components(separatedBy: "|||")
            guard parts.count >= 4 else { return nil }
            return MailMessage(
                id: parts[0],
                subject: parts[1],
                from: parts[2],
                dateReceived: parts[3],
                isRead: false
            )
        }
    }

    // MARK: - Read Message

    func getMessage(id: String) throws -> MailMessageDetail? {
        let script = """
        tell application "Mail"
            try
                set msg to first message of inbox whose id is \(id)
                set msgSubject to subject of msg
                set msgFrom to sender of msg
                set msgTo to (address of to recipients of msg) as string
                set msgDate to (date received of msg) as string
                set msgContent to content of msg
                return msgSubject & "|||FIELD|||" & msgFrom & "|||FIELD|||" & msgTo & "|||FIELD|||" & msgDate & "|||FIELD|||" & msgContent
            on error
                return ""
            end try
        end tell
        """

        let result = try runAppleScript(script)
        if result.isEmpty { return nil }

        let parts = result.components(separatedBy: "|||FIELD|||")
        guard parts.count >= 5 else { return nil }

        return MailMessageDetail(
            id: id,
            subject: parts[0],
            from: parts[1],
            to: parts[2],
            dateReceived: parts[3],
            content: parts[4]
        )
    }

    // MARK: - Search

    func searchMessages(query: String, limit: Int = 30) throws -> [MailMessage] {
        let escapedQuery = escapeForAppleScript(query)
        let script = """
        tell application "Mail"
            set messageList to ""
            set msgCount to 0
            repeat with msg in (messages of inbox whose subject contains "\(escapedQuery)" or sender contains "\(escapedQuery)")
                if msgCount >= \(limit) then exit repeat
                set msgCount to msgCount + 1
                set msgId to (id of msg) as string
                set msgSubject to subject of msg
                set msgFrom to sender of msg
                set msgDate to (date received of msg) as string
                set isRead to (read status of msg) as string
                set messageList to messageList & msgId & "|||" & msgSubject & "|||" & msgFrom & "|||" & msgDate & "|||" & isRead & "###"
            end repeat
            return messageList
        end tell
        """

        let result = try runAppleScript(script)
        if result.isEmpty { return [] }

        return result.components(separatedBy: "###").compactMap { item -> MailMessage? in
            let parts = item.components(separatedBy: "|||")
            guard parts.count >= 5 else { return nil }
            return MailMessage(
                id: parts[0],
                subject: parts[1],
                from: parts[2],
                dateReceived: parts[3],
                isRead: parts[4] == "true"
            )
        }
    }

    // MARK: - Draft

    func createDraft(to: String?, subject: String?, body: String?) throws {
        var scriptParts: [String] = []

        if let to = to {
            scriptParts.append("set theTo to \"\(escapeForAppleScript(to))\"")
        }
        if let subject = subject {
            scriptParts.append("set theSubject to \"\(escapeForAppleScript(subject))\"")
        }
        if let body = body {
            scriptParts.append("set theBody to \"\(escapeForAppleScript(body))\"")
        }

        var makeNewParts: [String] = []
        if to != nil { makeNewParts.append("to recipient theTo") }
        if subject != nil { makeNewParts.append("subject theSubject") }
        if body != nil { makeNewParts.append("content theBody") }

        let makeNew = makeNewParts.isEmpty ? "" : " with properties {\(makeNewParts.joined(separator: ", "))}"

        let script = """
        tell application "Mail"
            \(scriptParts.joined(separator: "\n            "))
            set newMessage to make new outgoing message\(makeNew)
            set visible of newMessage to true
            activate
        end tell
        """

        _ = try runAppleScript(script)
    }

    // MARK: - Private Helpers

    private func runAppleScript(_ script: String) throws -> String {
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("sysm-mail-\(UUID().uuidString).scpt")
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
            throw MailError.appleScriptError(errorMessage)
        }

        return String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func escapeForAppleScript(_ string: String) -> String {
        return string.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}

// MARK: - Models

struct MailAccount: Codable {
    let id: String
    let name: String
    let email: String
}

struct MailMessage: Codable {
    let id: String
    let subject: String
    let from: String
    let dateReceived: String
    let isRead: Bool
}

struct MailMessageDetail: Codable {
    let id: String
    let subject: String
    let from: String
    let to: String
    let dateReceived: String
    let content: String
}

// MARK: - Errors

enum MailError: LocalizedError {
    case appleScriptError(String)
    case mailNotRunning
    case messageNotFound(String)

    var errorDescription: String? {
        switch self {
        case .appleScriptError(let message):
            return "AppleScript error: \(message)"
        case .mailNotRunning:
            return "Mail app is not running"
        case .messageNotFound(let id):
            return "Message '\(id)' not found"
        }
    }
}
