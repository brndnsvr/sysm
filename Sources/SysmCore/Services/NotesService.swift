import Foundation

public struct NotesService: NotesServiceProtocol {

    private var appleScript: any AppleScriptRunnerProtocol { Services.appleScriptRunner() }

    public init() {}

    public func listFolders() throws -> [String] {
        let script = """
        tell application "Notes"
            set AppleScript's text item delimiters to "|||"
            set folderNames to name of every folder
            set output to folderNames as text
            set AppleScript's text item delimiters to ""
            return output
        end tell
        """

        let result = try runAppleScript(script)
        if result.isEmpty { return [] }
        return result.components(separatedBy: "|||")
    }

    public func listNotes(folder: String? = nil) throws -> [(name: String, folder: String, id: String)] {
        let folderFilter = folder.map { "folder \"\(appleScript.escape($0))\"" } ?? "default folder"

        let script = """
        tell application "Notes"
            set AppleScript's text item delimiters to "|||"
            try
                set targetFolder to \(folderFilter)
                set noteNames to name of every note of targetFolder
                set noteIds to id of every note of targetFolder
                set folderName to name of targetFolder

                set output to ""
                repeat with i from 1 to count of noteNames
                    if i > 1 then set output to output & "###"
                    set output to output & (item i of noteNames) & "|||" & folderName & "|||" & (item i of noteIds)
                end repeat
                set AppleScript's text item delimiters to ""
                return output
            on error
                return ""
            end try
        end tell
        """

        let result = try runAppleScript(script)
        if result.isEmpty { return [] }

        return result.components(separatedBy: "###").compactMap { item in
            let parts = item.components(separatedBy: "|||")
            guard parts.count >= 3 else { return nil }
            return (name: parts[0], folder: parts[1], id: parts[2])
        }
    }

    public func getNote(id: String) throws -> Note? {
        let script = """
        tell application "Notes"
            try
                set n to note id "\(appleScript.escape(id))"
                set noteData to ""
                set noteData to noteData & (name of n) & "|||FIELD|||"
                set noteData to noteData & (name of container of n) & "|||FIELD|||"
                set noteData to noteData & (body of n) & "|||FIELD|||"
                set noteData to noteData & ((creation date of n) as string) & "|||FIELD|||"
                set noteData to noteData & ((modification date of n) as string)
                return noteData
            on error
                return ""
            end try
        end tell
        """

        let result = try runAppleScript(script)
        if result.isEmpty { return nil }

        let parts = result.components(separatedBy: "|||FIELD|||")
        guard parts.count >= 5 else { return nil }

        return Note(
            id: id,
            name: parts[0],
            folder: parts[1],
            body: parts[2],
            creationDate: parseAppleScriptDate(parts[3]),
            modificationDate: parseAppleScriptDate(parts[4])
        )
    }

    public func getNotes(from folder: String) throws -> [Note] {
        let escapedFolder = appleScript.escape(folder)

        // Batch fetch all notes in a single AppleScript call
        // Note: We use the passed-in folder name directly instead of querying
        // (name of container of n) because that property doesn't resolve correctly
        // inside the loop in some AppleScript contexts.
        let script = """
        tell application "Notes"
            try
                set targetFolder to folder "\(escapedFolder)"
                set folderName to name of targetFolder
                set output to ""
                repeat with n in notes of targetFolder
                    if output is not "" then set output to output & "###NOTE###"
                    set noteData to ""
                    set noteData to noteData & (id of n) & "|||FIELD|||"
                    set noteData to noteData & (name of n) & "|||FIELD|||"
                    set noteData to noteData & folderName & "|||FIELD|||"
                    set noteData to noteData & (body of n) & "|||FIELD|||"
                    set noteData to noteData & ((creation date of n) as string) & "|||FIELD|||"
                    set noteData to noteData & ((modification date of n) as string)
                    set output to output & noteData
                end repeat
                return output
            on error
                return ""
            end try
        end tell
        """

        let result = try runAppleScript(script)
        if result.isEmpty { return [] }

        return result.components(separatedBy: "###NOTE###").compactMap { noteData in
            let parts = noteData.components(separatedBy: "|||FIELD|||")
            guard parts.count >= 6 else { return nil }
            return Note(
                id: parts[0],
                name: parts[1],
                folder: parts[2],
                body: parts[3],
                creationDate: parseAppleScriptDate(parts[4]),
                modificationDate: parseAppleScriptDate(parts[5])
            )
        }
    }

    public func countNotes(folder: String? = nil) throws -> Int {
        let folderFilter = folder.map { "folder \"\(appleScript.escape($0))\"" } ?? "default folder"

        let script = """
        tell application "Notes"
            try
                return count of notes of \(folderFilter)
            on error
                return 0
            end try
        end tell
        """

        let result = try runAppleScript(script)
        return Int(result.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    public func createNote(name: String, body: String, folder: String? = nil) throws -> String {
        let escapedName = appleScript.escape(name)
        let escapedBody = appleScript.escape(body)
        let folderRef = folder.map { "folder \"\(appleScript.escape($0))\"" } ?? "default folder"

        let script = """
        tell application "Notes"
            set targetFolder to \(folderRef)
            set newNote to make new note at targetFolder with properties {name:"\(escapedName)", body:"\(escapedBody)"}
            return id of newNote
        end tell
        """

        return try runAppleScript(script).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func updateNote(id: String, name: String?, body: String?) throws {
        let escapedId = appleScript.escape(id)

        var updates: [String] = []
        if let name = name {
            updates.append("set name of n to \"\(appleScript.escape(name))\"")
        }
        if let body = body {
            updates.append("set body of n to \"\(appleScript.escape(body))\"")
        }

        guard !updates.isEmpty else { return }

        let script = """
        tell application "Notes"
            set n to note id "\(escapedId)"
            \(updates.joined(separator: "\n            "))
        end tell
        """

        _ = try runAppleScript(script)
    }

    public func deleteNote(id: String) throws {
        let escapedId = appleScript.escape(id)

        let script = """
        tell application "Notes"
            delete note id "\(escapedId)"
        end tell
        """

        _ = try runAppleScript(script)
    }

    public func createFolder(name: String) throws {
        let escapedName = appleScript.escape(name)

        let script = """
        tell application "Notes"
            make new folder with properties {name:"\(escapedName)"}
        end tell
        """

        _ = try runAppleScript(script)
    }

    public func deleteFolder(name: String) throws {
        let escapedName = appleScript.escape(name)

        let script = """
        tell application "Notes"
            delete folder "\(escapedName)"
        end tell
        """

        _ = try runAppleScript(script)
    }

    // MARK: - Advanced Operations

    public func searchNotes(query: String, searchBody: Bool, folder: String? = nil) throws -> [Note] {
        let escapedQuery = appleScript.escape(query)
        let folderFilter = folder.map { "folder \"\(appleScript.escape($0))\"" } ?? "default folder"

        let script = """
        tell application "Notes"
            try
                set targetFolder to \(folderFilter)
                set folderName to name of targetFolder
                set output to ""
                repeat with n in notes of targetFolder
                    set matches to false
                    set noteName to name of n

                    -- Search in title
                    if noteName contains "\(escapedQuery)" then
                        set matches to true
                    end if

                    -- Optionally search in body
                    \(searchBody ? """
                    if not matches then
                        set noteBody to body of n
                        if noteBody contains "\(escapedQuery)" then
                            set matches to true
                        end if
                    end if
                    """ : "")

                    if matches then
                        if output is not "" then set output to output & "###NOTE###"
                        set noteData to ""
                        set noteData to noteData & (id of n) & "|||FIELD|||"
                        set noteData to noteData & noteName & "|||FIELD|||"
                        set noteData to noteData & folderName & "|||FIELD|||"
                        set noteData to noteData & (body of n) & "|||FIELD|||"
                        set noteData to noteData & ((creation date of n) as string) & "|||FIELD|||"
                        set noteData to noteData & ((modification date of n) as string)
                        set output to output & noteData
                    end if
                end repeat
                return output
            on error
                return ""
            end try
        end tell
        """

        let result = try runAppleScript(script)
        if result.isEmpty { return [] }

        return result.components(separatedBy: "###NOTE###").compactMap { noteData in
            let parts = noteData.components(separatedBy: "|||FIELD|||")
            guard parts.count >= 6 else { return nil }
            return Note(
                id: parts[0],
                name: parts[1],
                folder: parts[2],
                body: parts[3],
                creationDate: parseAppleScriptDate(parts[4]),
                modificationDate: parseAppleScriptDate(parts[5])
            )
        }
    }

    public func moveNote(id: String, toFolder: String) throws {
        let escapedId = appleScript.escape(id)
        let escapedFolder = appleScript.escape(toFolder)

        let script = """
        tell application "Notes"
            try
                set n to note id "\(escapedId)"
                set targetFolder to folder "\(escapedFolder)"
                move n to targetFolder
                return "ok"
            on error errMsg
                return "error:" & errMsg
            end try
        end tell
        """

        let result = try runAppleScript(script)
        if result.hasPrefix("error:") {
            let errorMsg = String(result.dropFirst(6))
            if errorMsg.contains("folder") {
                throw NotesError.folderNotFound(toFolder)
            } else {
                throw NotesError.noteNotFound(id)
            }
        }
    }

    public func appendToNote(id: String, content: String) throws {
        let escapedId = appleScript.escape(id)
        let escapedContent = appleScript.escape(content)

        let script = """
        tell application "Notes"
            set n to note id "\(escapedId)"
            set currentBody to body of n
            set body of n to currentBody & "<br><br>\(escapedContent)"
        end tell
        """

        _ = try runAppleScript(script)
    }

    public func duplicateNote(id: String, newName: String? = nil) throws -> String {
        let escapedId = appleScript.escape(id)

        // If no new name provided, get the original and append " copy"
        let nameScript = newName.map { "\"\(appleScript.escape($0))\"" } ?? """
        (name of note id "\(escapedId)") & " copy"
        """

        let script = """
        tell application "Notes"
            set originalNote to note id "\(escapedId)"
            set noteFolder to container of originalNote
            set noteBody to body of originalNote
            set noteName to \(nameScript)
            set newNote to make new note at noteFolder with properties {name:noteName, body:noteBody}
            return id of newNote
        end tell
        """

        return try runAppleScript(script).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func runAppleScript(_ script: String) throws -> String {
        do {
            return try appleScript.run(script, identifier: "notes")
        } catch AppleScriptError.executionFailed(let message) {
            throw NotesError.appleScriptError(message)
        }
    }

    private func parseAppleScriptDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")

        // Try various AppleScript date formats
        let formats = [
            "EEEE, MMMM d, yyyy 'at' h:mm:ss a",
            "EEEE, MMMM d, yyyy 'at' h:mm a",
            "MMM d, yyyy, h:mm:ss a",
            "MMM d, yyyy, h:mm a",
            "yyyy-MM-dd HH:mm:ss",
        ]

        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return date
            }
        }

        return nil
    }
}

public enum NotesError: LocalizedError {
    case appleScriptError(String)
    case folderNotFound(String)
    case noteNotFound(String)
    case exportFailed(String)

    public var errorDescription: String? {
        switch self {
        case .appleScriptError(let message):
            return "AppleScript error: \(message)"
        case .folderNotFound(let name):
            return "Folder '\(name)' not found"
        case .noteNotFound(let name):
            return "Note '\(name)' not found"
        case .exportFailed(let reason):
            return "Export failed: \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .appleScriptError:
            return """
            AppleScript execution failed. Grant automation permission:
            1. Open System Settings
            2. Navigate to Privacy & Security > Automation
            3. Find Terminal and enable Notes
            4. Restart sysm
            """
        case .folderNotFound:
            return """
            Folder not found.

            Try:
            - List folders: sysm notes folders
            - Create folder: sysm notes create-folder "Folder Name"
            - Use default folder (omit --folder flag)
            """
        case .noteNotFound:
            return """
            Note not found.

            Try:
            - List notes: sysm notes list
            - Search notes: sysm notes search "title"
            - Check different folder: sysm notes list --folder "Other"
            """
        case .exportFailed(let reason):
            return "Export failed: \(reason). Check output directory and permissions."
        }
    }
}
