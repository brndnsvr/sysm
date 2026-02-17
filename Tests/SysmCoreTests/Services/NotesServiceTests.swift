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

    // MARK: - Error mapping

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
        mock.defaultResponse = "error:Can't get folder"
        XCTAssertThrowsError(try service.moveNote(id: "note-1", toFolder: "Missing")) { error in
            guard case NotesError.folderNotFound = error else {
                XCTFail("Expected folderNotFound, got \(error)")
                return
            }
        }
    }

    func testMoveNoteNoteNotFound() {
        mock.defaultResponse = "error:Can't get note"
        XCTAssertThrowsError(try service.moveNote(id: "bad-id", toFolder: "Work")) { error in
            guard case NotesError.noteNotFound = error else {
                XCTFail("Expected noteNotFound, got \(error)")
                return
            }
        }
    }
}
