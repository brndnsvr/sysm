//
//  NotesServiceTests.swift
//  sysm
//

import XCTest
@testable import SysmCore

final class NotesServiceTests: XCTestCase {
    var mockRunner: MockAppleScriptRunner!
    var service: NotesService!

    override func setUp() {
        super.setUp()
        mockRunner = MockAppleScriptRunner()
        service = NotesService(scriptRunner: mockRunner)
    }

    override func tearDown() {
        mockRunner = nil
        service = nil
        super.tearDown()
    }

    // MARK: - Folder Tests

    func testListFolders() throws {
        mockRunner.mockResponses["notes-folders"] = "Work|||Personal|||Archive"

        let folders = try service.listFolders()

        XCTAssertEqual(folders.count, 3)
        XCTAssertEqual(folders[0], "Work")
        XCTAssertEqual(folders[1], "Personal")
        XCTAssertEqual(folders[2], "Archive")
    }

    func testListFoldersEmpty() throws {
        mockRunner.mockResponses["notes-folders"] = ""

        let folders = try service.listFolders()

        XCTAssertEqual(folders.count, 0)
    }

    // MARK: - List Notes Tests

    func testListNotes() throws {
        let mockOutput = """
        note-1|||Meeting Notes|||Work|||2024-01-15 10:00:00
        note-2|||Ideas|||Personal|||2024-01-14 15:30:00
        """
        mockRunner.mockResponses["notes-list"] = mockOutput

        let notes = try service.listNotes(folder: nil)

        XCTAssertEqual(notes.count, 2)
        XCTAssertEqual(notes[0].name, "Meeting Notes")
        XCTAssertEqual(notes[0].folder, "Work")
        XCTAssertEqual(notes[0].id, "note-1")

        XCTAssertEqual(notes[1].name, "Ideas")
        XCTAssertEqual(notes[1].folder, "Personal")
    }

    func testListNotesWithFolder() throws {
        mockRunner.mockResponses["notes-list"] = "note-1|||Note|||Work|||2024-01-15 10:00:00"

        _ = try service.listNotes(folder: "Work")

        XCTAssertTrue(mockRunner.lastScript!.contains("Work"))
    }

    // MARK: - Get Note Tests

    func testGetNoteById() throws {
        let mockOutput = "note-1|||Meeting Notes|||Work|||Meeting content here|||2024-01-15 10:00:00|||2024-01-15 12:00:00"
        mockRunner.mockResponses["notes-get"] = mockOutput

        let note = try service.getNote(id: "note-1")

        XCTAssertNotNil(note)
        XCTAssertEqual(note?.id, "note-1")
        XCTAssertEqual(note?.name, "Meeting Notes")
        XCTAssertEqual(note?.folder, "Work")
        XCTAssertEqual(note?.body, "Meeting content here")
    }

    func testGetNoteNotFound() throws {
        mockRunner.mockResponses["notes-get"] = ""

        let note = try service.getNote(id: "nonexistent")

        XCTAssertNil(note)
    }

    // MARK: - Create Note Tests

    func testCreateNote() throws {
        mockRunner.mockResponses["notes-create"] = "new-note-id"

        let noteId = try service.createNote(
            name: "New Note",
            body: "Note content",
            folder: "Work"
        )

        XCTAssertEqual(noteId, "new-note-id")

        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("New Note"))
        XCTAssertTrue(script.contains("Note content"))
        XCTAssertTrue(script.contains("Work"))
    }

    func testCreateNoteDefaultFolder() throws {
        mockRunner.mockResponses["notes-create"] = "new-note-id"

        _ = try service.createNote(name: "New Note", body: "Content", folder: nil)

        // Should not specify folder in script
        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("New Note"))
    }

    // MARK: - Update Note Tests

    func testUpdateNoteTitle() throws {
        mockRunner.mockResponses["notes-update"] = "success"

        XCTAssertNoThrow(
            try service.updateNote(id: "note-1", name: "Updated Title", body: nil)
        )

        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("note-1"))
        XCTAssertTrue(script.contains("Updated Title"))
    }

    func testUpdateNoteBody() throws {
        mockRunner.mockResponses["notes-update"] = "success"

        XCTAssertNoThrow(
            try service.updateNote(id: "note-1", name: nil, body: "Updated content")
        )

        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("note-1"))
        XCTAssertTrue(script.contains("Updated content"))
    }

    // MARK: - Delete Tests

    func testDeleteNote() throws {
        mockRunner.mockResponses["notes-delete"] = "success"

        XCTAssertNoThrow(try service.deleteNote(id: "note-1"))

        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("note-1"))
        XCTAssertTrue(script.contains("delete"))
    }

    func testDeleteFolder() throws {
        mockRunner.mockResponses["notes-delete-folder"] = "success"

        XCTAssertNoThrow(try service.deleteFolder(name: "Old Folder"))

        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("Old Folder"))
    }

    // MARK: - Search Tests

    func testSearchNotes() throws {
        let mockOutput = """
        note-1|||Found Note|||Work|||Content with search term|||2024-01-15 10:00:00|||2024-01-15 10:00:00
        """
        mockRunner.mockResponses["notes-search"] = mockOutput

        let notes = try service.searchNotes(query: "search term", searchBody: true, folder: nil)

        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes[0].name, "Found Note")

        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("search term"))
    }

    // MARK: - Advanced Operations Tests

    func testMoveNote() throws {
        mockRunner.mockResponses["notes-move"] = "success"

        XCTAssertNoThrow(try service.moveNote(id: "note-1", toFolder: "Archive"))

        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("note-1"))
        XCTAssertTrue(script.contains("Archive"))
    }

    func testAppendToNote() throws {
        mockRunner.mockResponses["notes-append"] = "success"

        XCTAssertNoThrow(try service.appendToNote(id: "note-1", content: "Additional content"))

        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("note-1"))
        XCTAssertTrue(script.contains("Additional content"))
    }

    func testDuplicateNote() throws {
        mockRunner.mockResponses["notes-duplicate"] = "new-note-id"

        let newId = try service.duplicateNote(id: "note-1", newName: "Copy of Note")

        XCTAssertEqual(newId, "new-note-id")

        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("note-1"))
        XCTAssertTrue(script.contains("Copy of Note"))
    }

    // MARK: - Count Tests

    func testCountNotes() throws {
        mockRunner.mockResponses["notes-count"] = "42"

        let count = try service.countNotes(folder: nil)

        XCTAssertEqual(count, 42)
    }

    // MARK: - Error Tests

    func testFolderNotFoundError() {
        mockRunner.mockResponses["notes-list"] = ""
        mockRunner.mockErrors["notes-list"] = NotesError.folderNotFound("Nonexistent")

        XCTAssertThrowsError(try service.listNotes(folder: "Nonexistent")) { error in
            XCTAssertTrue(error is NotesError)
        }
    }

    // MARK: - Escaping Tests

    func testInputEscaping() throws {
        mockRunner.mockResponses["notes-create"] = "new-id"

        _ = try service.createNote(
            name: "Note's \"Title\"",
            body: "Body with 'quotes'",
            folder: nil
        )

        // Verify escaping was applied
        let script = mockRunner.lastScript!
        XCTAssertTrue(script.contains("\\"))
    }
}
