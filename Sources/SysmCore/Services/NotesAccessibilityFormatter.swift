import ApplicationServices
import AppKit
import Foundation

protocol NotesStructuredFormatting: Sendable {
    func preflight() throws
    func apply(
        document: NotesMarkdownDocument,
        toNote id: String,
        expectedFolder: String?
    ) throws
}

enum NotesStructuredFormattingError: LocalizedError, Equatable {
    case accessibilityPermissionRequired
    case notesUnavailable
    case targetMismatch(expected: String, actual: String)
    case editorNotFound
    case ambiguousEditor
    case focusLost
    case textSelectionFailed
    case formatCommandUnavailable(String)
    case formatCommandFailed(String)
    case readBackFailed(String)
    case verificationFailed(String)
    case appleScriptFailed(String)

    var errorDescription: String? {
        switch self {
        case .accessibilityPermissionRequired:
            return "Accessibility permission is required in System Settings > Privacy & Security > Accessibility"
        case .notesUnavailable:
            return "Notes.app is not available"
        case .targetMismatch(let expected, let actual):
            return "Notes target changed (expected \(expected), found \(actual.isEmpty ? "none" : actual))"
        case .editorNotFound:
            return "Could not find the Notes editor containing the newly created content"
        case .ambiguousEditor:
            return "More than one Notes editor matched the newly created content"
        case .focusLost:
            return "Notes lost keyboard focus before formatting completed"
        case .textSelectionFailed:
            return "Could not select the expected text in the target note"
        case .formatCommandUnavailable(let command):
            return "Notes format command '\(command)' is unavailable for the current account or keyboard layout"
        case .formatCommandFailed(let command):
            return "Notes format command '\(command)' failed"
        case .readBackFailed(let reason):
            return "Could not read the formatted note back: \(reason)"
        case .verificationFailed(let reason):
            return "Formatted note verification failed: \(reason)"
        case .appleScriptFailed(let reason):
            return "AppleScript failed while targeting the note: \(reason)"
        }
    }
}

/// Applies Notes-native paragraph and checklist styles to an exactly targeted note.
///
/// Notes' scripting dictionary exposes HTML body content but no checklist state. This formatter
/// uses the supported `show` command to isolate the note, verifies its ID through `selection`, and
/// invokes Notes' own format menu items through Accessibility. Every UI action rechecks target,
/// focus, and selected text range before it is performed.
struct NotesAccessibilityFormatter: NotesStructuredFormatting {
    private static let notesBundleIdentifier = "com.apple.Notes"
    private static let fieldDelimiter = "\u{001E}"
    private static let waitIterations = 100
    private static let waitInterval: TimeInterval = 0.05

    private var appleScript: any AppleScriptRunnerProtocol { Services.appleScriptRunner() }

    func preflight() throws {
        guard AXIsProcessTrusted() else {
            throw NotesStructuredFormattingError.accessibilityPermissionRequired
        }
        guard NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.notesBundleIdentifier) != nil else {
            throw NotesStructuredFormattingError.notesUnavailable
        }
    }

    func apply(
        document: NotesMarkdownDocument,
        toNote id: String,
        expectedFolder: String?
    ) throws {
        let previousApplication = NSWorkspace.shared.frontmostApplication
        defer {
            if previousApplication?.bundleIdentifier != Self.notesBundleIdentifier {
                _ = previousApplication?.activate(options: [.activateAllWindows])
            }
        }

        try showAndSelectNote(id: id)
        let runningApplication = try waitForNotesToBecomeFrontmost()
        let applicationElement = AXUIElementCreateApplication(runningApplication.processIdentifier)
        let accessibilityUI = NotesAccessibilityUI(application: applicationElement) {
            try verifySelectedNote(id: id)
        }
        try accessibilityUI.apply(document: document)
        try verifyReadBack(document: document, noteId: id, expectedFolder: expectedFolder)
    }

    private func showAndSelectNote(id: String) throws {
        let escapedId = appleScript.escape(id)
        let script = """
        tell application "Notes"
            set matchingNotes to every note whose id is "\(escapedId)"
            if (count of matchingNotes) is not 1 then error "Expected exactly one note with the created ID"
            set targetNote to item 1 of matchingNotes
            set selection to {targetNote}
            show targetNote separately true
            activate
            return id of targetNote
        end tell
        """
        let actualId = try runAppleScript(script, identifier: "notes-structured-show")
        guard actualId == id else {
            throw NotesStructuredFormattingError.targetMismatch(expected: id, actual: actualId)
        }
    }

    private func waitForNotesToBecomeFrontmost() throws -> NSRunningApplication {
        for _ in 0..<Self.waitIterations {
            if let application = NSRunningApplication
                .runningApplications(withBundleIdentifier: Self.notesBundleIdentifier)
                .first,
                NSWorkspace.shared.frontmostApplication?.processIdentifier == application.processIdentifier {
                return application
            }
            Thread.sleep(forTimeInterval: Self.waitInterval)
        }
        throw NotesStructuredFormattingError.focusLost
    }

    private func verifySelectedNote(id: String) throws {
        let script = """
        tell application "Notes"
            set selectedNotes to selection
            if (count of selectedNotes) is not 1 then return ""
            return id of item 1 of selectedNotes
        end tell
        """
        let selectedId = try runAppleScript(script, identifier: "notes-structured-target")
        guard selectedId == id else {
            throw NotesStructuredFormattingError.targetMismatch(expected: id, actual: selectedId)
        }
    }

    private func verifyReadBack(
        document: NotesMarkdownDocument,
        noteId: String,
        expectedFolder: String?
    ) throws {
        let escapedId = appleScript.escape(noteId)
        let script = """
        tell application "Notes"
            set matchingNotes to every note whose id is "\(escapedId)"
            if (count of matchingNotes) is not 1 then error "Expected exactly one note with the created ID"
            set n to item 1 of matchingNotes
            set fieldDelimiter to character id 30
            set output to (id of n) & fieldDelimiter & (plaintext of n)
            set output to output & fieldDelimiter & (body of n)
            return output
        end tell
        """
        let result = try runAppleScript(script, identifier: "notes-structured-verify")
        let fields = result.components(separatedBy: Self.fieldDelimiter)
        guard fields.count >= 3 else {
            throw NotesStructuredFormattingError.readBackFailed("unexpected Notes response")
        }
        guard fields[0] == noteId else {
            throw NotesStructuredFormattingError.targetMismatch(expected: noteId, actual: fields[0])
        }
        if let expectedFolder {
            try verifyFolder(expectedFolder, containsNote: noteId)
        }

        let body = fields.dropFirst(2).joined(separator: Self.fieldDelimiter)
        try NotesReadBackValidator().validate(document: document, plaintext: fields[1], body: body)
    }

    private func verifyFolder(_ folder: String, containsNote noteId: String) throws {
        let escapedFolder = appleScript.escape(folder)
        let escapedId = appleScript.escape(noteId)
        let script = """
        tell application "Notes"
            set targetFolder to folder "\(escapedFolder)"
            if (id of every note of targetFolder) contains "\(escapedId)" then return name of targetFolder
            return ""
        end tell
        """
        let actualFolder = try runAppleScript(script, identifier: "notes-structured-folder")
        guard actualFolder == folder else {
            throw NotesStructuredFormattingError.verificationFailed(
                "expected folder '\(folder)', but the created note was not found there"
            )
        }
    }

    private func runAppleScript(_ script: String, identifier: String) throws -> String {
        do {
            return try appleScript.run(script, identifier: identifier)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } catch AppleScriptError.executionFailed(let message) {
            throw NotesStructuredFormattingError.appleScriptFailed(message)
        }
    }
}
