import XCTest
@testable import SysmCore

final class MarkdownExporterTests: XCTestCase {

    var exporter: MarkdownExporter!
    var tempDir: URL!

    override func setUp() {
        super.setUp()
        exporter = MarkdownExporter()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MarkdownExporterTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let tempDir = tempDir {
            try? FileManager.default.removeItem(at: tempDir)
        }
        exporter = nil
        tempDir = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    func createTestNote(
        id: String = "test-id",
        name: String = "Test Note",
        folder: String = "Test Folder",
        body: String = "Test content"
    ) -> Note {
        return Note(
            id: id,
            name: name,
            folder: folder,
            body: body,
            creationDate: Date(),
            modificationDate: Date()
        )
    }

    // MARK: - loadImportedIds Tests

    func testLoadImportedIds_NoFile() {
        let ids = exporter.loadImportedIds(outputDir: tempDir)
        XCTAssertTrue(ids.isEmpty)
    }

    func testLoadImportedIds_ValidFile() throws {
        let testIds = ["id1", "id2", "id3"]
        let data = try JSONEncoder().encode(testIds)
        let trackingFile = tempDir.appendingPathComponent(".imported_notes.json")
        try data.write(to: trackingFile)

        let ids = exporter.loadImportedIds(outputDir: tempDir)
        XCTAssertEqual(ids.count, 3)
        XCTAssertTrue(ids.contains("id1"))
        XCTAssertTrue(ids.contains("id2"))
        XCTAssertTrue(ids.contains("id3"))
    }

    func testLoadImportedIds_InvalidFile() throws {
        let trackingFile = tempDir.appendingPathComponent(".imported_notes.json")
        try "invalid json".write(to: trackingFile, atomically: true, encoding: .utf8)

        let ids = exporter.loadImportedIds(outputDir: tempDir)
        XCTAssertTrue(ids.isEmpty)
    }

    // MARK: - saveImportedIds Tests

    func testSaveImportedIds() throws {
        let testIds: Set<String> = ["id1", "id2", "id3"]
        try exporter.saveImportedIds(testIds, outputDir: tempDir)

        let trackingFile = tempDir.appendingPathComponent(".imported_notes.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: trackingFile.path))

        let data = try Data(contentsOf: trackingFile)
        let loadedIds = try JSONDecoder().decode([String].self, from: data)
        XCTAssertEqual(Set(loadedIds), testIds)
    }

    // MARK: - exportNote Tests

    func testExportNote_Success() throws {
        let note = createTestNote(name: "Test Note", body: "Test content")
        let outputURL = try exporter.exportNote(note, outputDir: tempDir, dryRun: false)

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        XCTAssertEqual(outputURL.lastPathComponent, "Test Note.md")

        let content = try String(contentsOf: outputURL, encoding: .utf8)
        XCTAssertTrue(content.contains("source: apple-notes"))
        XCTAssertTrue(content.contains("folder: Test Folder"))
        XCTAssertTrue(content.contains("Test content"))
    }

    func testExportNote_DryRun() throws {
        let note = createTestNote(name: "Dry Run Note")
        let outputURL = try exporter.exportNote(note, outputDir: tempDir, dryRun: true)

        XCTAssertFalse(FileManager.default.fileExists(atPath: outputURL.path))
        XCTAssertEqual(outputURL.lastPathComponent, "Dry Run Note.md")
    }

    func testExportNote_SanitizesFilename() throws {
        let note = createTestNote(name: "Test/Note:With\\Special")
        let outputURL = try exporter.exportNote(note, outputDir: tempDir, dryRun: false)

        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        XCTAssertEqual(outputURL.lastPathComponent, "Test-Note-With-Special.md")
    }

    func testExportNote_CreatesDirectory() throws {
        let newDir = tempDir.appendingPathComponent("newsubdir")
        let note = createTestNote()

        XCTAssertFalse(FileManager.default.fileExists(atPath: newDir.path))

        let outputURL = try exporter.exportNote(note, outputDir: newDir, dryRun: false)

        XCTAssertTrue(FileManager.default.fileExists(atPath: newDir.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
    }

    // MARK: - exportNotes Tests

    func testExportNotes_Success() throws {
        let notes = [
            createTestNote(id: "1", name: "Note 1"),
            createTestNote(id: "2", name: "Note 2"),
            createTestNote(id: "3", name: "Note 3")
        ]

        let results = try exporter.exportNotes(notes, outputDir: tempDir, dryRun: false)

        XCTAssertEqual(results.count, 3)
        for (note, path) in results {
            XCTAssertTrue(FileManager.default.fileExists(atPath: path.path))
            XCTAssertTrue(path.lastPathComponent.contains(note.name))
        }
    }

    func testExportNotes_SkipsImported() throws {
        // Pre-save one note as imported
        try exporter.saveImportedIds(["2"], outputDir: tempDir)

        let notes = [
            createTestNote(id: "1", name: "Note 1"),
            createTestNote(id: "2", name: "Note 2"),
            createTestNote(id: "3", name: "Note 3")
        ]

        let results = try exporter.exportNotes(notes, outputDir: tempDir, dryRun: false)

        XCTAssertEqual(results.count, 2)
        XCTAssertFalse(results.contains(where: { $0.note.id == "2" }))
    }

    func testExportNotes_DryRun() throws {
        let notes = [
            createTestNote(id: "1", name: "Note 1"),
            createTestNote(id: "2", name: "Note 2")
        ]

        let results = try exporter.exportNotes(notes, outputDir: tempDir, dryRun: true)

        XCTAssertEqual(results.count, 2)
        for (_, path) in results {
            XCTAssertFalse(FileManager.default.fileExists(atPath: path.path))
        }

        // Tracking file should not exist in dry run
        let trackingFile = tempDir.appendingPathComponent(".imported_notes.json")
        XCTAssertFalse(FileManager.default.fileExists(atPath: trackingFile.path))
    }

    func testExportNotes_DeferTracking() throws {
        let notes = [
            createTestNote(id: "1", name: "Note 1"),
            createTestNote(id: "2", name: "Note 2")
        ]

        let results = try exporter.exportNotes(notes, outputDir: tempDir, dryRun: false, deferTracking: true)

        XCTAssertEqual(results.count, 2)

        // Files should exist
        for (_, path) in results {
            XCTAssertTrue(FileManager.default.fileExists(atPath: path.path))
        }

        // But tracking file should not be updated
        let ids = exporter.loadImportedIds(outputDir: tempDir)
        XCTAssertTrue(ids.isEmpty)
    }

    func testExportNotes_UpdatesTracking() throws {
        let notes = [
            createTestNote(id: "1", name: "Note 1"),
            createTestNote(id: "2", name: "Note 2")
        ]

        _ = try exporter.exportNotes(notes, outputDir: tempDir, dryRun: false, deferTracking: false)

        let ids = exporter.loadImportedIds(outputDir: tempDir)
        XCTAssertEqual(ids.count, 2)
        XCTAssertTrue(ids.contains("1"))
        XCTAssertTrue(ids.contains("2"))
    }

    // MARK: - markAsImported Tests

    func testMarkAsImported_NewIds() throws {
        try exporter.markAsImported(["1", "2", "3"], outputDir: tempDir)

        let ids = exporter.loadImportedIds(outputDir: tempDir)
        XCTAssertEqual(ids.count, 3)
        XCTAssertTrue(ids.contains("1"))
        XCTAssertTrue(ids.contains("2"))
        XCTAssertTrue(ids.contains("3"))
    }

    func testMarkAsImported_AppendsToExisting() throws {
        try exporter.saveImportedIds(["1", "2"], outputDir: tempDir)
        try exporter.markAsImported(["3", "4"], outputDir: tempDir)

        let ids = exporter.loadImportedIds(outputDir: tempDir)
        XCTAssertEqual(ids.count, 4)
        XCTAssertTrue(ids.contains("1"))
        XCTAssertTrue(ids.contains("2"))
        XCTAssertTrue(ids.contains("3"))
        XCTAssertTrue(ids.contains("4"))
    }

    func testMarkAsImported_EmptyArray() throws {
        try exporter.markAsImported([], outputDir: tempDir)

        let trackingFile = tempDir.appendingPathComponent(".imported_notes.json")
        XCTAssertFalse(FileManager.default.fileExists(atPath: trackingFile.path))
    }

    // MARK: - checkForNew Tests

    func testCheckForNew_AllNew() {
        let notes = [
            createTestNote(id: "1", name: "Note 1"),
            createTestNote(id: "2", name: "Note 2"),
            createTestNote(id: "3", name: "Note 3")
        ]

        let newNotes = exporter.checkForNew(notes, outputDir: tempDir)
        XCTAssertEqual(newNotes.count, 3)
    }

    func testCheckForNew_SomeImported() throws {
        try exporter.saveImportedIds(["2"], outputDir: tempDir)

        let notes = [
            createTestNote(id: "1", name: "Note 1"),
            createTestNote(id: "2", name: "Note 2"),
            createTestNote(id: "3", name: "Note 3")
        ]

        let newNotes = exporter.checkForNew(notes, outputDir: tempDir)
        XCTAssertEqual(newNotes.count, 2)
        XCTAssertFalse(newNotes.contains(where: { $0.id == "2" }))
    }

    func testCheckForNew_AllImported() throws {
        try exporter.saveImportedIds(["1", "2", "3"], outputDir: tempDir)

        let notes = [
            createTestNote(id: "1", name: "Note 1"),
            createTestNote(id: "2", name: "Note 2"),
            createTestNote(id: "3", name: "Note 3")
        ]

        let newNotes = exporter.checkForNew(notes, outputDir: tempDir)
        XCTAssertTrue(newNotes.isEmpty)
    }
}
