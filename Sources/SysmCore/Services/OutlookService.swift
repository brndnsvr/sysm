import Foundation

public struct OutlookService: OutlookServiceProtocol {

    private enum Delimiters {
        static let field = "|||"
        static let record = "###"
    }

    private var appleScript: any AppleScriptRunnerProtocol { Services.appleScriptRunner() }

    public init() {}

    public func isAvailable() -> Bool {
        FileManager.default.fileExists(atPath: "/Applications/Microsoft Outlook.app")
    }

    // MARK: - Inbox

    public func getInbox(limit: Int) throws -> [OutlookMessage] {
        let script = """
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
                    set msgFrom to address of sender of msg
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
                        set msgFrom to address of sender of msg
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
                        set msgFrom to address of sender of msg
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
        tell application "Microsoft Outlook"
            try
                set msg to message id \(safeId)
                set msgSubject to subject of msg
                set msgFrom to ""
                try
                    set msgFrom to address of sender of msg
                end try
                set msgTo to ""
                try
                    set toRecips to to recipients of msg
                    repeat with r in toRecips
                        if msgTo is not "" then set msgTo to msgTo & ", "
                        set msgTo to msgTo & email address of r
                    end repeat
                end try
                set msgCc to ""
                try
                    set ccRecips to cc recipients of msg
                    repeat with r in ccRecips
                        if msgCc is not "" then set msgCc to msgCc & ", "
                        set msgCc to msgCc & email address of r
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
        let script = """
        tell application "Microsoft Outlook"
            set eventList to ""
            set startDate to current date
            set endDate to startDate + (\(days) * days)
            set calEvents to calendar events of default calendar whose start time >= startDate and start time <= endDate
            repeat with evt in calEvents
                set evtId to id of evt as string
                set evtSubject to subject of evt
                set evtStart to start time of evt as string
                set evtEnd to end time of evt as string
                set evtLocation to ""
                try
                    set evtLocation to location of evt
                end try
                set evtAllDay to is all day event of evt as string
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
        var filterClause = ""
        if let priority = priority {
            let outlookPriority: String
            switch priority.lowercased() {
            case "high": outlookPriority = "priority is high priority"
            case "low": outlookPriority = "priority is low priority"
            default: outlookPriority = "priority is normal priority"
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
                    set tDue to due date of t as string
                end try
                set tPriority to priority of t as string
                set tComplete to completed of t as string
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
