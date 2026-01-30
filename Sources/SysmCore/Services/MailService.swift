import Foundation

// MARK: - Serialization Protocol
// AppleScript results use text delimiters:
// - "|||" separates fields within a record
// - "###" separates multiple records
// - "|||FIELD|||" for fields that may contain "|||"

public struct MailService: MailServiceProtocol {

    // MARK: - Constants

    private static let unreadScanMultiplier = 5
    private static let searchScanMultiplier = 10

    // MARK: - Accounts

    public func getAccounts() throws -> [MailAccount] {
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

    public func getInboxMessages(accountName: String? = nil, limit: Int = 20) throws -> [MailMessage] {
        let inboxSource: String
        if let accountName = accountName {
            let escapedName = escapeForAppleScript(accountName)
            inboxSource = "inbox of (first account whose name is \"\(escapedName)\")"
        } else {
            inboxSource = "inbox"
        }

        let script = """
        tell application "Mail"
            set messageList to ""
            set msgCount to 0
            repeat with msg in (messages of \(inboxSource))
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

    public func getUnreadMessages(accountName: String? = nil, limit: Int = 50) throws -> [MailMessage] {
        let inboxSource: String
        if let accountName = accountName {
            let escapedName = escapeForAppleScript(accountName)
            inboxSource = "inbox of (first account whose name is \"\(escapedName)\")"
        } else {
            inboxSource = "inbox"
        }

        // Use paginated approach to avoid timeout with large inboxes
        // The `whose` clause forces Mail to enumerate ALL messages before filtering,
        // which causes -1712 timeout errors. Instead, iterate by index and check read status.
        let scanLimit = limit * Self.unreadScanMultiplier
        let script = """
        tell application "Mail"
            set messageList to ""
            set foundCount to 0
            set theInbox to \(inboxSource)
            set msgTotal to count of messages of theInbox
            repeat with i from 1 to msgTotal
                if foundCount >= \(limit) then exit repeat
                if i > \(scanLimit) then exit repeat
                try
                    set msg to message i of theInbox
                    if read status of msg is false then
                        set foundCount to foundCount + 1
                        set msgId to (id of msg) as string
                        set msgSubject to subject of msg
                        set msgFrom to sender of msg
                        set msgDate to (date received of msg) as string
                        set messageList to messageList & msgId & "|||" & msgSubject & "|||" & msgFrom & "|||" & msgDate & "###"
                    end if
                on error
                    -- Intentionally skip: message may be corrupt, locked, or inaccessible
                end try
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

    public func getMessage(id: String) throws -> MailMessageDetail? {
        let script = """
        tell application "Mail"
            try
                set msg to first message of inbox whose id is \(id)
                set msgSubject to subject of msg
                set msgFrom to sender of msg
                set msgTo to (address of to recipients of msg) as string
                set msgDate to (date received of msg) as string
                set msgContent to content of msg
                set msgIsRead to (read status of msg) as string
                set msgIsFlagged to (flagged status of msg) as string

                -- Get CC recipients
                set msgCc to ""
                try
                    set ccList to address of cc recipients of msg
                    if (count of ccList) > 0 then
                        set msgCc to ccList as string
                    end if
                end try

                -- Get reply-to
                set msgReplyTo to ""
                try
                    set msgReplyTo to reply to of msg
                end try

                -- Get date sent
                set msgDateSent to ""
                try
                    set msgDateSent to (date sent of msg) as string
                end try

                -- Get mailbox and account info
                set msgMailbox to ""
                set msgAccount to ""
                try
                    set mb to mailbox of msg
                    set msgMailbox to name of mb
                    set msgAccount to name of account of mb
                end try

                -- Get attachment info
                set attachmentInfo to ""
                try
                    repeat with att in mail attachments of msg
                        set attName to name of att
                        set attMime to MIME type of att
                        set attSize to file size of att
                        set attachmentInfo to attachmentInfo & attName & "||ATT||" & attMime & "||ATT||" & (attSize as string) & "||ATTLIST||"
                    end repeat
                end try

                return msgSubject & "|||FIELD|||" & msgFrom & "|||FIELD|||" & msgTo & "|||FIELD|||" & msgDate & "|||FIELD|||" & msgContent & "|||FIELD|||" & msgIsRead & "|||FIELD|||" & msgIsFlagged & "|||FIELD|||" & msgCc & "|||FIELD|||" & msgReplyTo & "|||FIELD|||" & msgDateSent & "|||FIELD|||" & msgMailbox & "|||FIELD|||" & msgAccount & "|||FIELD|||" & attachmentInfo
            on error
                -- Intentionally skip: message may be corrupt, locked, or inaccessible
                return ""
            end try
        end tell
        """

        let result = try runAppleScript(script)
        if result.isEmpty { return nil }

        let parts = result.components(separatedBy: "|||FIELD|||")
        guard parts.count >= 5 else { return nil }

        // Parse attachments
        var attachments: [MailAttachment] = []
        if parts.count >= 13 && !parts[12].isEmpty {
            let attachmentItems = parts[12].components(separatedBy: "||ATTLIST||")
            for item in attachmentItems where !item.isEmpty {
                let attParts = item.components(separatedBy: "||ATT||")
                if attParts.count >= 3 {
                    attachments.append(MailAttachment(
                        name: attParts[0],
                        mimeType: attParts[1],
                        size: Int(attParts[2]) ?? 0
                    ))
                }
            }
        }

        return MailMessageDetail(
            id: id,
            subject: parts[0],
            from: parts[1],
            to: parts[2],
            cc: parts.count > 7 && !parts[7].isEmpty ? parts[7] : nil,
            bcc: nil,  // BCC not available for received messages
            replyTo: parts.count > 8 && !parts[8].isEmpty ? parts[8] : nil,
            dateReceived: parts[3],
            dateSent: parts.count > 9 && !parts[9].isEmpty ? parts[9] : nil,
            content: parts[4],
            isRead: parts.count > 5 ? parts[5] == "true" : true,
            isFlagged: parts.count > 6 ? parts[6] == "true" : false,
            mailbox: parts.count > 10 && !parts[10].isEmpty ? parts[10] : nil,
            accountName: parts.count > 11 && !parts[11].isEmpty ? parts[11] : nil,
            attachments: attachments
        )
    }

    // MARK: - Draft

    public func createDraft(to: String?, subject: String?, body: String?) throws {
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

    // MARK: - Mark Read/Unread

    public func markMessage(id: String, read: Bool) throws {
        let script = """
        tell application "Mail"
            try
                set msg to first message of inbox whose id is \(id)
                set read status of msg to \(read)
                return "ok"
            on error errMsg
                return "error:" & errMsg
            end try
        end tell
        """

        let result = try runAppleScript(script)
        if result.hasPrefix("error:") {
            throw MailError.messageNotFound(id)
        }
    }

    // MARK: - Delete Message

    public func deleteMessage(id: String) throws {
        let script = """
        tell application "Mail"
            try
                set msg to first message of inbox whose id is \(id)
                delete msg
                return "ok"
            on error errMsg
                return "error:" & errMsg
            end try
        end tell
        """

        let result = try runAppleScript(script)
        if result.hasPrefix("error:") {
            throw MailError.messageNotFound(id)
        }
    }

    // MARK: - Mailboxes

    public func getMailboxes(accountName: String? = nil) throws -> [MailMailbox] {
        let script: String
        if let accountName = accountName {
            let escapedName = escapeForAppleScript(accountName)
            script = """
            tell application "Mail"
                set mailboxList to ""
                try
                    set acc to first account whose name is "\(escapedName)"
                    set accName to name of acc
                    repeat with mb in mailboxes of acc
                        set mbName to name of mb
                        set mbUnread to unread count of mb
                        set mbTotal to count of messages of mb
                        set mailboxList to mailboxList & mbName & "|||" & accName & "|||" & (mbUnread as string) & "|||" & (mbTotal as string) & "|||" & mbName & "###"
                    end repeat
                on error errMsg
                    return "error:" & errMsg
                end try
                return mailboxList
            end tell
            """
        } else {
            script = """
            tell application "Mail"
                set mailboxList to ""
                repeat with acc in accounts
                    set accName to name of acc
                    repeat with mb in mailboxes of acc
                        set mbName to name of mb
                        set mbUnread to unread count of mb
                        set mbTotal to count of messages of mb
                        set fullPath to accName & "/" & mbName
                        set mailboxList to mailboxList & mbName & "|||" & accName & "|||" & (mbUnread as string) & "|||" & (mbTotal as string) & "|||" & fullPath & "###"
                    end repeat
                end repeat
                return mailboxList
            end tell
            """
        }

        let result = try runAppleScript(script)
        if result.hasPrefix("error:") {
            throw MailError.accountNotFound(accountName ?? "")
        }
        if result.isEmpty { return [] }

        return result.components(separatedBy: "###").compactMap { item -> MailMailbox? in
            let parts = item.components(separatedBy: "|||")
            guard parts.count >= 5 else { return nil }
            return MailMailbox(
                name: parts[0],
                accountName: parts[1],
                unreadCount: Int(parts[2]) ?? 0,
                messageCount: Int(parts[3]) ?? 0,
                fullPath: parts[4]
            )
        }
    }

    // MARK: - Move Message

    public func moveMessage(id: String, toMailbox: String, accountName: String? = nil) throws {
        let escapedMailbox = escapeForAppleScript(toMailbox)
        let targetMailbox: String
        if let accountName = accountName {
            let escapedAccount = escapeForAppleScript(accountName)
            targetMailbox = "mailbox \"\(escapedMailbox)\" of account \"\(escapedAccount)\""
        } else {
            targetMailbox = "mailbox \"\(escapedMailbox)\""
        }

        let script = """
        tell application "Mail"
            try
                set msg to first message of inbox whose id is \(id)
                set targetMb to \(targetMailbox)
                move msg to targetMb
                return "ok"
            on error errMsg
                return "error:" & errMsg
            end try
        end tell
        """

        let result = try runAppleScript(script)
        if result.hasPrefix("error:") {
            let errorMsg = String(result.dropFirst(6))
            if errorMsg.contains("message") {
                throw MailError.messageNotFound(id)
            } else {
                throw MailError.mailboxNotFound(toMailbox)
            }
        }
    }

    // MARK: - Flag/Unflag

    public func flagMessage(id: String, flagged: Bool) throws {
        let script = """
        tell application "Mail"
            try
                set msg to first message of inbox whose id is \(id)
                set flagged status of msg to \(flagged)
                return "ok"
            on error errMsg
                return "error:" & errMsg
            end try
        end tell
        """

        let result = try runAppleScript(script)
        if result.hasPrefix("error:") {
            throw MailError.messageNotFound(id)
        }
    }

    // MARK: - Enhanced Search

    public func searchMessages(
        accountName: String? = nil,
        query: String? = nil,
        bodyQuery: String? = nil,
        afterDate: Date? = nil,
        beforeDate: Date? = nil,
        limit: Int = 30
    ) throws -> [MailMessage] {
        // Validate date range
        if let after = afterDate, let before = beforeDate, after > before {
            throw MailError.invalidDateRange
        }

        let inboxSource: String
        if let accountName = accountName {
            let escapedName = escapeForAppleScript(accountName)
            inboxSource = "inbox of (first account whose name is \"\(escapedName)\")"
        } else {
            inboxSource = "inbox"
        }

        // Build conditional checks for AppleScript
        var conditionalChecks: [String] = []

        if let after = afterDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMMM d, yyyy 'at' h:mm:ss a"
            let dateStr = formatter.string(from: after)
            conditionalChecks.append("""
                        set afterDate to date "\(dateStr)"
                        if msgDate < afterDate then
                            set matchesDate to false
                        end if
            """)
        }

        if let before = beforeDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMMM d, yyyy 'at' h:mm:ss a"
            let dateStr = formatter.string(from: before)
            conditionalChecks.append("""
                        set beforeDate to date "\(dateStr)"
                        if msgDate > beforeDate then
                            set matchesDate to false
                        end if
            """)
        }

        if let query = query, !query.isEmpty {
            let escapedQuery = escapeForAppleScript(query)
            conditionalChecks.append("""
                        set searchQuery to "\(escapedQuery)"
                        if not (msgSubject contains searchQuery or msgFrom contains searchQuery) then
                            set matchesQuery to false
                        end if
            """)
        }

        if let bodyQuery = bodyQuery, !bodyQuery.isEmpty {
            let escapedBody = escapeForAppleScript(bodyQuery)
            conditionalChecks.append("""
                        set bodySearch to "\(escapedBody)"
                        try
                            set msgBody to content of msg
                            if msgBody does not contain bodySearch then
                                set matchesBody to false
                            end if
                        on error
                            set matchesBody to false
                        end try
            """)
        }

        let checksCode = conditionalChecks.joined(separator: "\n")
        let scanLimit = limit * Self.searchScanMultiplier

        let script = """
        tell application "Mail"
            set messageList to ""
            set foundCount to 0
            set theInbox to \(inboxSource)
            set msgTotal to count of messages of theInbox
            repeat with i from 1 to msgTotal
                if foundCount >= \(limit) then exit repeat
                if i > \(scanLimit) then exit repeat
                try
                    set msg to message i of theInbox
                    set msgSubject to subject of msg
                    set msgFrom to sender of msg
                    set msgDate to date received of msg
                    set matchesDate to true
                    set matchesQuery to true
                    set matchesBody to true
        \(checksCode)
                    if matchesDate and matchesQuery and matchesBody then
                        set foundCount to foundCount + 1
                        set msgId to (id of msg) as string
                        set msgDateStr to msgDate as string
                        set isRead to (read status of msg) as string
                        set messageList to messageList & msgId & "|||" & msgSubject & "|||" & msgFrom & "|||" & msgDateStr & "|||" & isRead & "###"
                    end if
                on error
                    -- Intentionally skip: message may be corrupt, locked, or inaccessible
                end try
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

    // MARK: - Send Mail

    public func sendMessage(
        to: String,
        cc: String? = nil,
        bcc: String? = nil,
        subject: String,
        body: String,
        accountName: String? = nil
    ) throws {
        if to.isEmpty {
            throw MailError.noRecipientsSpecified
        }

        let escapedTo = escapeForAppleScript(to)
        let escapedSubject = escapeForAppleScript(subject)
        let escapedBody = escapeForAppleScript(body)

        var recipientSetup = """
                make new to recipient at end of to recipients with properties {address:"\(escapedTo)"}
        """

        if let cc = cc, !cc.isEmpty {
            let escapedCc = escapeForAppleScript(cc)
            recipientSetup += """

                    make new cc recipient at end of cc recipients with properties {address:"\(escapedCc)"}
            """
        }

        if let bcc = bcc, !bcc.isEmpty {
            let escapedBcc = escapeForAppleScript(bcc)
            recipientSetup += """

                    make new bcc recipient at end of bcc recipients with properties {address:"\(escapedBcc)"}
            """
        }

        var accountSetup = ""
        if let accountName = accountName {
            let escapedAccount = escapeForAppleScript(accountName)
            accountSetup = ", sender:\"\(escapedAccount)\""
        }

        let script = """
        tell application "Mail"
            try
                set newMessage to make new outgoing message with properties {subject:"\(escapedSubject)", content:"\(escapedBody)", visible:false\(accountSetup)}
                tell newMessage
        \(recipientSetup)
                end tell
                send newMessage
                return "ok"
            on error errMsg
                return "error:" & errMsg
            end try
        end tell
        """

        let result = try runAppleScript(script)
        if result.hasPrefix("error:") {
            let errorMsg = String(result.dropFirst(6))
            throw MailError.sendFailed(errorMsg)
        }
    }

    // MARK: - Private Helpers

    private func runAppleScript(_ script: String) throws -> String {
        do {
            return try AppleScriptRunner.run(script, identifier: "mail")
        } catch AppleScriptError.executionFailed(let message) {
            if message.contains("not running") {
                throw MailError.mailNotRunning
            }
            throw MailError.appleScriptError(message)
        }
    }

    private func escapeForAppleScript(_ string: String) -> String {
        AppleScriptRunner.escape(string)
    }
}

// MARK: - Models

public struct MailAccount: Codable {
    public let id: String
    public let name: String
    public let email: String
}

public struct MailMessage: Codable {
    public let id: String
    public let subject: String
    public let from: String
    public let dateReceived: String
    public let isRead: Bool
}

public struct MailMessageDetail: Codable {
    public let id: String
    public let subject: String
    public let from: String
    public let to: String
    public let cc: String?
    public let bcc: String?
    public let replyTo: String?
    public let dateReceived: String
    public let dateSent: String?
    public let content: String
    public let isRead: Bool
    public let isFlagged: Bool
    public let mailbox: String?
    public let accountName: String?
    public let attachments: [MailAttachment]
}

public struct MailAttachment: Codable {
    public let name: String
    public let mimeType: String
    public let size: Int
}

public struct MailMailbox: Codable {
    public let name: String
    public let accountName: String
    public let unreadCount: Int
    public let messageCount: Int
    public let fullPath: String
}

// MARK: - Errors

public enum MailError: LocalizedError {
    case appleScriptError(String)
    case mailNotRunning
    case messageNotFound(String)
    case mailboxNotFound(String)
    case accountNotFound(String)
    case sendFailed(String)
    case invalidDateRange
    case noRecipientsSpecified

    public var errorDescription: String? {
        switch self {
        case .appleScriptError(let message):
            return "AppleScript error: \(message)"
        case .mailNotRunning:
            return "Mail app is not running"
        case .messageNotFound(let id):
            return "Message '\(id)' not found"
        case .mailboxNotFound(let name):
            return "Mailbox '\(name)' not found"
        case .accountNotFound(let name):
            return "Account '\(name)' not found"
        case .sendFailed(let reason):
            return "Failed to send message: \(reason)"
        case .invalidDateRange:
            return "Invalid date range specified"
        case .noRecipientsSpecified:
            return "No recipients specified"
        }
    }
}
