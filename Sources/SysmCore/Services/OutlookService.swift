import Foundation

public struct OutlookService: OutlookServiceProtocol {

    private enum Delimiters {
        static let field = "|||"
        static let record = "###"
    }

    private var appleScript: any AppleScriptRunnerProtocol { Services.appleScriptRunner() }

    /// AppleScript handler that formats an `email address` record as `Name <addr>`.
    /// Outlook's `sender` returns an `email address` record; a recipient's
    /// `email address` property also returns the record (not text). Either of
    /// `name` / `address` may be empty (Exchange "EX" senders often lack
    /// `address`), so we fall back gracefully.
    private static let emailFormatterHandler = """
    on _sysmFormatEmail(emRec)
        set theName to ""
        set theAddr to ""
        try
            set theName to (name of emRec) as string
        end try
        try
            set theAddr to (address of emRec) as string
        end try
        if theName is missing value then set theName to ""
        if theAddr is missing value then set theAddr to ""
        if theName is "" and theAddr is "" then return ""
        if theName is "" then return theAddr
        if theAddr is "" then return theName
        return theName & " <" & theAddr & ">"
    end _sysmFormatEmail
    """

    public init() {}

    public func isAvailable() -> Bool {
        FileManager.default.fileExists(atPath: "/Applications/Microsoft Outlook.app")
    }

    // MARK: - Inbox

    public func getInbox(limit: Int) throws -> [OutlookMessage] {
        let script = """
        \(Self.emailFormatterHandler)
        tell application "Microsoft Outlook"
            set msgList to ""
            set msgs to messages of inbox
            set maxCount to \(limit)
            set counter to 0
            repeat with msg in msgs
                if counter >= maxCount then exit repeat
                set msgId to id of msg as string
                set msgSubject to subject of msg
                set msgFrom to ""
                try
                    set msgFrom to my _sysmFormatEmail(sender of msg)
                end try
                set msgDate to time received of msg as string
                set msgRead to is read of msg as string
                set msgList to msgList & msgId & "|||" & msgSubject & "|||" & msgFrom & "|||" & msgDate & "|||" & msgRead & "###"
                set counter to counter + 1
            end repeat
            return msgList
        end tell
        """

        let result = try runAppleScript(script)
        if result.isEmpty { return [] }
        return parseMessages(from: result)
    }

    // MARK: - Unread

    public func getUnread(limit: Int) throws -> [OutlookMessage] {
        let script = """
        \(Self.emailFormatterHandler)
        tell application "Microsoft Outlook"
            set msgList to ""
            set msgs to messages of inbox
            set maxCount to \(limit)
            set counter to 0
            repeat with msg in msgs
                if counter >= maxCount then exit repeat
                if is read of msg is false then
                    set msgId to id of msg as string
                    set msgSubject to subject of msg
                    set msgFrom to ""
                    try
                        set msgFrom to my _sysmFormatEmail(sender of msg)
                    end try
                    set msgDate to time received of msg as string
                    set msgList to msgList & msgId & "|||" & msgSubject & "|||" & msgFrom & "|||" & msgDate & "|||false###"
                    set counter to counter + 1
                end if
            end repeat
            return msgList
        end tell
        """

        let result = try runAppleScript(script)
        if result.isEmpty { return [] }
        return parseMessages(from: result)
    }

    // MARK: - Search

    public func searchMessages(query: String, limit: Int) throws -> [OutlookMessage] {
        let safeQuery = escapeForAppleScript(query)
        let script = """
        \(Self.emailFormatterHandler)
        tell application "Microsoft Outlook"
            set msgList to ""
            set msgs to messages of inbox
            set maxCount to \(limit)
            set counter to 0
            repeat with msg in msgs
                if counter >= maxCount then exit repeat
                set msgSubject to subject of msg
                set msgContent to ""
                try
                    set msgContent to plain text content of msg
                end try
                if msgSubject contains "\(safeQuery)" or msgContent contains "\(safeQuery)" then
                    set msgId to id of msg as string
                    set msgFrom to ""
                    try
                        set msgFrom to my _sysmFormatEmail(sender of msg)
                    end try
                    set msgDate to time received of msg as string
                    set msgRead to is read of msg as string
                    set msgList to msgList & msgId & "|||" & msgSubject & "|||" & msgFrom & "|||" & msgDate & "|||" & msgRead & "###"
                    set counter to counter + 1
                end if
            end repeat
            return msgList
        end tell
        """

        let result = try runAppleScript(script)
        if result.isEmpty { return [] }
        return parseMessages(from: result)
    }

    // MARK: - Read Message

    public func getMessage(id: String) throws -> OutlookMessageDetail? {
        let safeId = try sanitizedId(id)
        let script = """
        \(Self.emailFormatterHandler)
        tell application "Microsoft Outlook"
            try
                set msg to message id \(safeId)
                set msgSubject to subject of msg
                set msgFrom to ""
                try
                    set msgFrom to my _sysmFormatEmail(sender of msg)
                end try
                set msgTo to ""
                try
                    set toRecips to to recipients of msg
                    repeat with r in toRecips
                        set rFmt to my _sysmFormatEmail(email address of r)
                        if rFmt is not "" then
                            if msgTo is not "" then set msgTo to msgTo & ", "
                            set msgTo to msgTo & rFmt
                        end if
                    end repeat
                end try
                set msgCc to ""
                try
                    set ccRecips to cc recipients of msg
                    repeat with r in ccRecips
                        set rFmt to my _sysmFormatEmail(email address of r)
                        if rFmt is not "" then
                            if msgCc is not "" then set msgCc to msgCc & ", "
                            set msgCc to msgCc & rFmt
                        end if
                    end repeat
                end try
                set msgDate to time received of msg as string
                set msgBody to ""
                try
                    set msgBody to plain text content of msg
                end try
                set msgRead to is read of msg as string
                return (id of msg as string) & "|||FIELD|||" & msgSubject & "|||FIELD|||" & msgFrom & "|||FIELD|||" & msgTo & "|||FIELD|||" & msgCc & "|||FIELD|||" & msgDate & "|||FIELD|||" & msgBody & "|||FIELD|||" & msgRead
            on error
                return ""
            end try
        end tell
        """

        let result = try runAppleScript(script)
        if result.isEmpty { return nil }

        let parts = result.components(separatedBy: "|||FIELD|||")
        guard parts.count >= 8 else { return nil }

        return OutlookMessageDetail(
            id: parts[0],
            subject: parts[1],
            from: parts[2],
            to: parts[3],
            cc: parts[4].isEmpty ? nil : parts[4],
            dateReceived: parts[5],
            body: parts[6],
            isRead: parts[7].lowercased() == "true"
        )
    }

    // MARK: - Send

    public func send(to: [String], cc: [String], subject: String, body: String) throws {
        guard !to.isEmpty else { throw OutlookError.noRecipientsSpecified }

        let safeSubject = escapeForAppleScript(subject)
        let safeBody = escapeForAppleScript(body)

        var recipientScript = ""
        for addr in to {
            let safeAddr = escapeForAppleScript(addr)
            recipientScript += """
            make new to recipient at newMsg with properties {email address:{address:"\(safeAddr)"}}\n
            """
        }
        for addr in cc {
            let safeAddr = escapeForAppleScript(addr)
            recipientScript += """
            make new cc recipient at newMsg with properties {email address:{address:"\(safeAddr)"}}\n
            """
        }

        let script = """
        tell application "Microsoft Outlook"
            set newMsg to make new outgoing message with properties {subject:"\(safeSubject)", plain text content:"\(safeBody)"}
            \(recipientScript)
            send newMsg
        end tell
        """

        _ = try runAppleScript(script)
    }

    // MARK: - Calendar

    public func getCalendarEvents(days: Int) throws -> [OutlookCalendarEvent] {
        // Outlook 16 dictionary: the boolean property on `calendar event` is
        // `all day flag` (not `is all day event` — AppleScript parses `is` as
        // a comparison operator and fails). `default calendar` is a property
        // of an account, so query `calendar events` directly on the app.
        let script = """
        tell application "Microsoft Outlook"
            set eventList to ""
            set startDate to current date
            set endDate to startDate + (\(days) * days)
            set calEvents to (every calendar event whose start time >= startDate and start time <= endDate)
            repeat with evt in calEvents
                set evtId to id of evt as string
                set evtSubject to subject of evt
                set evtStart to start time of evt as string
                set evtEnd to end time of evt as string
                set evtLocation to ""
                try
                    set evtLocation to location of evt
                end try
                set evtAllDay to "false"
                try
                    set evtAllDay to (all day flag of evt) as string
                end try
                set eventList to eventList & evtId & "|||" & evtSubject & "|||" & evtStart & "|||" & evtEnd & "|||" & evtLocation & "|||" & evtAllDay & "###"
            end repeat
            return eventList
        end tell
        """

        let result = try runAppleScript(script)
        if result.isEmpty { return [] }

        return result.components(separatedBy: Delimiters.record).compactMap { item -> OutlookCalendarEvent? in
            let trimmed = item.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            let parts = trimmed.components(separatedBy: Delimiters.field)
            guard parts.count >= 6 else { return nil }
            return OutlookCalendarEvent(
                id: parts[0],
                subject: parts[1],
                startTime: parts[2],
                endTime: parts[3],
                location: parts[4].isEmpty ? nil : parts[4],
                isAllDay: parts[5].lowercased() == "true"
            )
        }
    }

    // MARK: - Tasks

    public func getTasks(priority: String?) throws -> [OutlookTask] {
        // Outlook 16 priority enum values are `priority high|normal|low`
        // (not `high priority`). Task class has no `completed` boolean — only
        // `completed date` (date) inherited from `todoable object`; presence
        // of that date indicates the task is complete.
        var filterClause = ""
        if let priority = priority {
            let outlookPriority: String
            switch priority.lowercased() {
            case "high": outlookPriority = "priority is priority high"
            case "low": outlookPriority = "priority is priority low"
            default: outlookPriority = "priority is priority normal"
            }
            filterClause = "whose \(outlookPriority)"
        }

        let script = """
        tell application "Microsoft Outlook"
            set taskList to ""
            set allTasks to tasks \(filterClause)
            repeat with t in allTasks
                set tId to id of t as string
                set tName to name of t
                set tDue to ""
                try
                    set dd to due date of t
                    if dd is not missing value then set tDue to dd as string
                end try
                set tPriority to ""
                try
                    set tPriority to (priority of t) as string
                end try
                -- Strip "priority " prefix from AppleScript enum representation
                if tPriority starts with "priority " then
                    set tPriority to text 10 thru -1 of tPriority
                end if
                set tComplete to "false"
                try
                    set cd to completed date of t
                    if cd is not missing value then set tComplete to "true"
                end try
                set taskList to taskList & tId & "|||" & tName & "|||" & tDue & "|||" & tPriority & "|||" & tComplete & "###"
            end repeat
            return taskList
        end tell
        """

        let result = try runAppleScript(script)
        if result.isEmpty { return [] }

        return result.components(separatedBy: Delimiters.record).compactMap { item -> OutlookTask? in
            let trimmed = item.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            let parts = trimmed.components(separatedBy: Delimiters.field)
            guard parts.count >= 5 else { return nil }
            return OutlookTask(
                id: parts[0],
                name: parts[1],
                dueDate: parts[2].isEmpty ? nil : parts[2],
                priority: parts[3],
                isComplete: parts[4].lowercased() == "true"
            )
        }
    }

    // MARK: - Private

    private func parseMessages(from result: String) -> [OutlookMessage] {
        result.components(separatedBy: Delimiters.record).compactMap { item -> OutlookMessage? in
            let trimmed = item.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            let parts = trimmed.components(separatedBy: Delimiters.field)
            guard parts.count >= 5 else { return nil }
            return OutlookMessage(
                id: parts[0],
                subject: parts[1],
                from: parts[2],
                dateReceived: parts[3],
                isRead: parts[4].lowercased() == "true"
            )
        }
    }

    private func sanitizedId(_ id: String) throws -> String {
        guard Int(id) != nil else {
            throw OutlookError.messageNotFound(id)
        }
        return id
    }

    private func runAppleScript(_ script: String) throws -> String {
        guard isAvailable() else { throw OutlookError.outlookNotInstalled }
        do {
            return try appleScript.run(script, identifier: "outlook")
        } catch AppleScriptError.executionFailed(let message) {
            if message.contains("not running") || message.contains("is not open") {
                throw OutlookError.outlookNotRunning
            }
            throw OutlookError.appleScriptError(message)
        }
    }

    private func escapeForAppleScript(_ string: String) -> String {
        appleScript.escape(string)
    }
}
