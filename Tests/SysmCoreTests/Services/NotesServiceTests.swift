import XCTest
@testable import SysmCore

final class NotesServiceTests: XCTestCase {
    var mock: MockAppleScriptRunner!
    var service: NotesService!

    override func setUp() {
        super.setUp()
        mock = MockAppleScriptRunner()
        ServiceContainer.shared.appleScriptRunnerFactory = { [mock] in mock! }
        ServiceContainer.shared.clearCache()
        service = NotesService()
    }

    override func tearDown() {
        super.tearDown()
        ServiceContainer.shared.reset()
    }

    // MARK: - listFolders()

    func testListFoldersParsesOutput() throws {
        mock.defaultResponse = "Notes|||Work|||Personal"
        let folders = try service.listFolders()
        XCTAssertEqual(folders, ["Notes", "Work", "Personal"])
    }

    func testListFoldersEmpty() throws {
        mock.defaultResponse = ""
        let folders = try service.listFolders()
        XCTAssertTrue(folders.isEmpty)
    }

    // MARK: - listNotes()

    func testListNotesParsesOutput() throws {
        mock.defaultResponse = "Meeting Notes|||Work|||note-id-1###Ideas|||Personal|||note-id-2"
        let notes = try service.listNotes()
        XCTAssertEqual(notes.count, 2)
        XCTAssertEqual(notes[0].name, "Meeting Notes")
        XCTAssertEqual(notes[0].folder, "Work")
        XCTAssertEqual(notes[0].id, "note-id-1")
        XCTAssertEqual(notes[1].name, "Ideas")
    }

    func testListNotesEmpty() throws {
        mock.defaultResponse = ""
        let notes = try service.listNotes()
        XCTAssertTrue(notes.isEmpty)
    }

    // MARK: - getNote()

    func testGetNoteParsesResponse() throws {
        mock.defaultResponse = "Test Note|||FIELD|||Work|||FIELD|||<p>Hello World</p>|||FIELD|||Monday, January 15, 2024 at 10:00:00 AM|||FIELD|||Monday, January 15, 2024 at 11:00:00 AM"
        let note = try service.getNote(id: "note-123")
        XCTAssertNotNil(note)
        XCTAssertEqual(note?.name, "Test Note")
        XCTAssertEqual(note?.folder, "Work")
        XCTAssertTrue(note?.body.contains("Hello World") ?? false)
    }

    func testGetNoteEmpty() throws {
        mock.defaultResponse = ""
        let note = try service.getNote(id: "missing")
        XCTAssertNil(note)
    }

    // MARK: - countNotes()

    func testCountNotes() throws {
        mock.defaultResponse = "5"
        let count = try service.countNotes()
        XCTAssertEqual(count, 5)
    }

    func testCountNotesInvalidResponse() throws {
        mock.defaultResponse = "not-a-number"
        let count = try service.countNotes()
        XCTAssertEqual(count, 0)
    }

    // MARK: - searchNotes()

    func testSearchNotesReturnsMatching() throws {
        mock.defaultResponse = "note-1|||FIELD|||Found Note|||FIELD|||Work|||FIELD|||<p>Content</p>|||FIELD|||Monday, January 15, 2024 at 10:00:00 AM|||FIELD|||Monday, January 15, 2024 at 11:00:00 AM"
        let results = try service.searchNotes(query: "Found", searchBody: false)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "Found Note")
    }

    func testSearchNotesEmpty() throws {
        mock.defaultResponse = ""
        let results = try service.searchNotes(query: "nothing", searchBody: true)
        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - createStructuredNote()

    func testCreateStructuredNotePreflightsCreatesAndFormatsExactId() throws {
        let formatter = MockNotesStructuredFormatter()
        service = NotesService(structuredFormatter: formatter)
        mock.defaultResponse = "note-structured-1"
        mock.responses["count of matchingFolders"] = "1"

        let noteId = try service.createStructuredNote(
            name: "Supplies",
            markdown: "# Supplies\n\n- [ ] Pencils\n- [x] Paper",
            folder: "Kids Stuff"
        )

        XCTAssertEqual(noteId, "note-structured-1")
        XCTAssertTrue(formatter.didPreflight)
        XCTAssertEqual(formatter.appliedNoteId, "note-structured-1")
        XCTAssertEqual(formatter.appliedFolder, "Kids Stuff")
        XCTAssertEqual(
            formatter.appliedDocument?.blocks,
            [
                .title("Supplies"),
                .checklistItem(text: "Pencils", isChecked: false),
                .checklistItem(text: "Paper", isChecked: true),
            ]
        )

        let script = try XCTUnwrap(mock.executedScripts.first { $0.script.contains("make new note") }?.script)
        XCTAssertTrue(script.contains("folder \"Kids Stuff\""))
        XCTAssertTrue(script.contains("<div>Supplies</div>"))
        XCTAssertTrue(script.contains("<div>Pencils</div>"))
        XCTAssertFalse(script.contains("- [ ]"))
    }

    func testCreateStructuredNotePreflightFailureDoesNotCreateNote() {
        let formatter = MockNotesStructuredFormatter()
        formatter.preflightError = NotesStructuredFormattingError.accessibilityPermissionRequired
        service = NotesService(structuredFormatter: formatter)

        XCTAssertThrowsError(
            try service.createStructuredNote(name: "Supplies", markdown: "- [ ] Pencils", folder: nil)
        ) { error in
            guard case NotesError.structuredFormattingUnavailable = error else {
                XCTFail("Expected structuredFormattingUnavailable, got \(error)")
                return
            }
        }
        XCTAssertTrue(mock.executedScripts.isEmpty)
    }

    func testCreateStructuredNoteReportsPartialNoteIdWhenFormattingFails() {
        let formatter = MockNotesStructuredFormatter()
        formatter.applyError = NotesStructuredFormattingError.editorNotFound
        service = NotesService(structuredFormatter: formatter)
        mock.defaultResponse = "note-partial-1"

        XCTAssertThrowsError(
            try service.createStructuredNote(name: "Supplies", markdown: "- [ ] Pencils", folder: nil)
        ) { error in
            guard case NotesError.structuredFormattingFailed(let noteId, let reason) = error else {
                XCTFail("Expected structuredFormattingFailed, got \(error)")
                return
            }
            XCTAssertEqual(noteId, "note-partial-1")
            XCTAssertTrue(reason.contains("newly created content"))
        }
    }

    func testCreateStructuredNoteRejectsAmbiguousFolderBeforeCreation() {
        let formatter = MockNotesStructuredFormatter()
        service = NotesService(structuredFormatter: formatter)
        mock.responses["count of matchingFolders"] = "2"

        XCTAssertThrowsError(
            try service.createStructuredNote(name: "Supplies", markdown: "- [ ] Pencils", folder: "Notes")
        ) { error in
            guard case NotesError.ambiguousFolder(let folder, let count) = error else {
                XCTFail("Expected ambiguousFolder, got \(error)")
                return
            }
            XCTAssertEqual(folder, "Notes")
            XCTAssertEqual(count, 2)
        }
        XCTAssertFalse(mock.executedScripts.contains { $0.script.contains("make new note") })
        XCTAssertNil(formatter.appliedNoteId)
    }

    // MARK: - Error mapping

    func testCommandsWithoutAFolderUseTheDefaultAccountsFolder() throws {
        mock.defaultResponse = ""
        _ = try service.listNotes()
        _ = try service.countNotes()
        _ = try service.createNote(name: "Note", body: "Body")
        _ = try service.searchNotes(query: "q", searchBody: false)

        // Notes rejects a bare "default folder" on a Mac holding more than one
        // account, which broke every command run without --folder.
        for script in mock.executedScripts.map(\.script) {
            XCTAssertEqual(script.components(separatedBy: "default folder").count,
                           script.components(separatedBy: NotesService.defaultFolder).count, script)
        }
    }

    func testAppleScriptErrorMapping() {
        mock.errorToThrow = AppleScriptError.executionFailed("test error")
        XCTAssertThrowsError(try service.listFolders()) { error in
            guard case NotesError.appleScriptError = error else {
                XCTFail("Expected NotesError.appleScriptError, got \(error)")
                return
            }
        }
    }

    // MARK: - moveNote error paths

    func testMoveNoteFolderNotFound() {
        mock.responses["count of matchingFolders"] = "0"
        XCTAssertThrowsError(try service.moveNote(id: "note-1", toFolder: "Missing")) { error in
            guard case NotesError.folderNotFound = error else {
                XCTFail("Expected folderNotFound, got \(error)")
                return
            }
        }
        XCTAssertFalse(mock.executedScripts.contains { $0.script.contains("move n to") })
    }

    func testMoveNoteNoteNotFound() {
        mock.responses["count of matchingFolders"] = "1"
        mock.defaultResponse = "error:Can't get note"
        XCTAssertThrowsError(try service.moveNote(id: "bad-id", toFolder: "Work")) { error in
            guard case NotesError.noteNotFound = error else {
                XCTFail("Expected noteNotFound, got \(error)")
                return
            }
        }
    }

    // MARK: - Folder names shared across accounts

    func testMoveNoteRejectsAmbiguousFolder() {
        mock.responses["count of matchingFolders"] = "2"
        XCTAssertThrowsError(try service.moveNote(id: "note-1", toFolder: "Notes")) { error in
            guard case NotesError.ambiguousFolder(let folder, let count) = error else {
                XCTFail("Expected ambiguousFolder, got \(error)")
                return
            }
            XCTAssertEqual(folder, "Notes")
            XCTAssertEqual(count, 2)
        }
        XCTAssertFalse(mock.executedScripts.contains { $0.script.contains("move n to") })
    }

    func testDeleteFolderRejectsAmbiguousName() {
        // Notes would delete whichever "Notes" folder it found first, with its notes.
        mock.responses["count of matchingFolders"] = "2"
        XCTAssertThrowsError(try service.deleteFolder(name: "Notes")) { error in
            guard case NotesError.ambiguousFolder = error else {
                XCTFail("Expected ambiguousFolder, got \(error)")
                return
            }
        }
        XCTAssertFalse(mock.executedScripts.contains { $0.script.contains("delete folder") })
    }
}

private final class MockNotesStructuredFormatter: NotesStructuredFormatting, @unchecked Sendable {
    var preflightError: Error?
    var applyError: Error?
    var didPreflight = false
    var appliedDocument: NotesMarkdownDocument?
    var appliedNoteId: String?
    var appliedFolder: String?

    func preflight() throws {
        didPreflight = true
        if let preflightError { throw preflightError }
    }

    func apply(
        document: NotesMarkdownDocument,
        toNote id: String,
        expectedFolder: String?
    ) throws {
        appliedDocument = document
        appliedNoteId = id
        appliedFolder = expectedFolder
        if let applyError { throw applyError }
    }
}
