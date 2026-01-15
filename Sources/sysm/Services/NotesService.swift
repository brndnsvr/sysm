import Foundation

struct NotesService {

    func listFolders() throws -> [String] {
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

    func listNotes(folder: String? = nil) throws -> [(name: String, folder: String, id: String)] {
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

    func getNote(id: String) throws -> Note? {
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

    func getNotes(from folder: String) throws -> [Note] {
        let notesList = try listNotes(folder: folder)
        var notes: [Note] = []

        for noteInfo in notesList {
            if let note = try getNote(id: noteInfo.id) {
                notes.append(note)
            }
        }

        return notes
    }

    func countNotes(folder: String? = nil) throws -> Int {
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

    private func runAppleScript(_ script: String) throws -> String {
        // Write script to temp file to avoid escaping issues
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("sysm-notes-\(UUID().uuidString).scpt")
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
            throw NotesError.appleScriptError(errorMessage)
        }

        return String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
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

enum NotesError: LocalizedError {
    case appleScriptError(String)
    case folderNotFound(String)
    case noteNotFound(String)
    case exportFailed(String)

    var errorDescription: String? {
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
