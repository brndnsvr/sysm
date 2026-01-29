import Foundation

public struct NotesService: NotesServiceProtocol {

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
        let folderFilter = folder.map { "folder \"\(AppleScriptRunner.escape($0))\"" } ?? "default folder"

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
                set n to note id "\(AppleScriptRunner.escape(id))"
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
        let escapedFolder = AppleScriptRunner.escape(folder)

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
        let folderFilter = folder.map { "folder \"\(AppleScriptRunner.escape($0))\"" } ?? "default folder"

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
        let escapedName = AppleScriptRunner.escape(name)
        let escapedBody = AppleScriptRunner.escape(body)
        let folderRef = folder.map { "folder \"\(AppleScriptRunner.escape($0))\"" } ?? "default folder"

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
        let escapedId = AppleScriptRunner.escape(id)

        var updates: [String] = []
        if let name = name {
            updates.append("set name of n to \"\(AppleScriptRunner.escape(name))\"")
        }
        if let body = body {
            updates.append("set body of n to \"\(AppleScriptRunner.escape(body))\"")
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
        let escapedId = AppleScriptRunner.escape(id)

        let script = """
        tell application "Notes"
            delete note id "\(escapedId)"
        end tell
        """

        _ = try runAppleScript(script)
    }

    public func createFolder(name: String) throws {
        let escapedName = AppleScriptRunner.escape(name)

        let script = """
        tell application "Notes"
            make new folder with properties {name:"\(escapedName)"}
        end tell
        """

        _ = try runAppleScript(script)
    }

    public func deleteFolder(name: String) throws {
        let escapedName = AppleScriptRunner.escape(name)

        let script = """
        tell application "Notes"
            delete folder "\(escapedName)"
        end tell
        """

        _ = try runAppleScript(script)
    }

    private func runAppleScript(_ script: String) throws -> String {
        do {
            return try AppleScriptRunner.run(script, identifier: "notes")
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
}
