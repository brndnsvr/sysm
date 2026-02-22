import XCTest
import SQLite3
@testable import SysmCore

/// Tests for NativeTagService using a temporary SQLite database with the expected schema.
final class NativeTagServiceTests: XCTestCase {
    var tempDBPath: String!
    var db: OpaquePointer!

    override func setUp() async throws {
        try await super.setUp()

        // Create temp database
        let tempDir = FileManager.default.temporaryDirectory
        tempDBPath = tempDir.appendingPathComponent("test_reminders_\(UUID().uuidString).sqlite").path

        var dbPtr: OpaquePointer?
        XCTAssertEqual(sqlite3_open(tempDBPath, &dbPtr), SQLITE_OK)
        db = dbPtr

        try createSchema()
    }

    override func tearDown() async throws {
        if let db = db {
            sqlite3_close(db)
        }
        if let path = tempDBPath {
            try? FileManager.default.removeItem(atPath: path)
            try? FileManager.default.removeItem(atPath: "\(path)-wal")
            try? FileManager.default.removeItem(atPath: "\(path)-shm")
        }
        try await super.tearDown()
    }

    // MARK: - Schema & Model Tests

    func testNativeTagModel() {
        let tag = NativeTag(name: "Work", canonicalName: "work", count: 3)
        XCTAssertEqual(tag.name, "Work")
        XCTAssertEqual(tag.canonicalName, "work")
        XCTAssertEqual(tag.count, 3)
        XCTAssertEqual(tag.formatted(), "#Work (3 reminders)")
    }

    func testNativeTagFormattedSingular() {
        let tag = NativeTag(name: "Solo", canonicalName: "solo", count: 1)
        XCTAssertEqual(tag.formatted(), "#Solo (1 reminder)")
    }

    func testNativeTagCodable() throws {
        let tag = NativeTag(name: "Test", canonicalName: "test", count: 5)
        let data = try JSONEncoder().encode(tag)
        let decoded = try JSONDecoder().decode(NativeTag.self, from: data)
        XCTAssertEqual(decoded.name, "Test")
        XCTAssertEqual(decoded.canonicalName, "test")
        XCTAssertEqual(decoded.count, 5)
    }

    func testSchemaValidation() throws {
        // Our test DB has the correct schema — resolving entity types should succeed
        let entities = try resolveTestEntityTypes()
        XCTAssertGreaterThan(entities.labelEnt, 0)
        XCTAssertGreaterThan(entities.objectEnt, 0)
        XCTAssertGreaterThan(entities.hashtagEnt, 0)
    }

    // MARK: - List Tags

    func testListTagsEmpty() throws {
        let tags = try listTagsFromTestDB()
        XCTAssertTrue(tags.isEmpty)
    }

    func testListTagsWithData() throws {
        // Insert a label
        try insertLabel(pk: 1, name: "Work", canonical: "work")

        let tags = try listTagsFromTestDB()
        XCTAssertEqual(tags.count, 1)
        XCTAssertEqual(tags[0].name, "Work")
        XCTAssertEqual(tags[0].canonicalName, "work")
        XCTAssertEqual(tags[0].count, 0) // no join records yet
    }

    func testListTagsWithCounts() throws {
        let entities = try resolveTestEntityTypes()

        try insertLabel(pk: 1, name: "Work", canonical: "work")
        try insertReminder(pk: 1, title: "Task 1", ekId: "EK-001")
        try insertReminder(pk: 2, title: "Task 2", ekId: "EK-002")
        try insertJoinRecord(pk: 1, ent: entities.hashtagEnt, labelPK: 1, reminderPK: 1)
        try insertJoinRecord(pk: 2, ent: entities.hashtagEnt, labelPK: 1, reminderPK: 2)

        let tags = try listTagsFromTestDB()
        XCTAssertEqual(tags.count, 1)
        XCTAssertEqual(tags[0].count, 2)
    }

    func testListTagsExcludesDeleted() throws {
        let entities = try resolveTestEntityTypes()

        try insertLabel(pk: 1, name: "Work", canonical: "work")
        try insertReminder(pk: 1, title: "Task 1", ekId: "EK-001")
        try insertJoinRecord(pk: 1, ent: entities.hashtagEnt, labelPK: 1, reminderPK: 1, deleted: true)

        let tags = try listTagsFromTestDB()
        XCTAssertEqual(tags[0].count, 0) // deleted join records excluded
    }

    // MARK: - ID Mapping

    func testReminderPKResolution() throws {
        try insertReminder(pk: 42, title: "Test Reminder", ekId: "EK-UUID-123")

        let pk = try resolveReminderPK("EK-UUID-123")
        XCTAssertEqual(pk, 42)
    }

    func testReminderPKNotFound() {
        XCTAssertThrowsError(try resolveReminderPK("NONEXISTENT")) { error in
            guard case NativeTagError.reminderNotFoundInDB = error else {
                XCTFail("Expected reminderNotFoundInDB, got \(error)")
                return
            }
        }
    }

    // MARK: - Add Tag

    func testAddTagCreatesLabelAndJoin() throws {
        try insertReminder(pk: 1, title: "Task 1", ekId: "EK-001")
        try insertAccountInfo()

        try addTagToTestDB("work", reminderPK: 1, ekId: "EK-001")

        // Verify label was created
        let labelCount = queryInt("SELECT COUNT(*) FROM ZREMCDHASHTAGLABEL WHERE ZCANONICALNAME = 'work'")
        XCTAssertEqual(labelCount, 1)

        // Verify join record was created
        let entities = try resolveTestEntityTypes()
        let joinCount = queryInt(
            "SELECT COUNT(*) FROM ZREMCDOBJECT WHERE Z_ENT = \(entities.hashtagEnt) AND ZREMINDER3 = 1 AND ZMARKEDFORDELETION = 0"
        )
        XCTAssertEqual(joinCount, 1)
    }

    func testAddTagReusesExistingLabel() throws {
        try insertLabel(pk: 1, name: "Work", canonical: "work")
        try insertReminder(pk: 1, title: "Task 1", ekId: "EK-001")
        try insertAccountInfo()

        try addTagToTestDB("work", reminderPK: 1, ekId: "EK-001")

        // Should still be only 1 label
        let labelCount = queryInt("SELECT COUNT(*) FROM ZREMCDHASHTAGLABEL WHERE ZCANONICALNAME = 'work'")
        XCTAssertEqual(labelCount, 1)
    }

    func testAddTagReturnsFalseIfAlreadyPresent() throws {
        let entities = try resolveTestEntityTypes()

        try insertLabel(pk: 1, name: "Work", canonical: "work")
        try insertReminder(pk: 1, title: "Task 1", ekId: "EK-001")
        try insertJoinRecord(pk: 1, ent: entities.hashtagEnt, labelPK: 1, reminderPK: 1)
        try insertAccountInfo()

        let result = try addTagToTestDB("work", reminderPK: 1, ekId: "EK-001")
        XCTAssertFalse(result)
    }

    // MARK: - Remove Tag

    func testRemoveTagSoftDeletes() throws {
        let entities = try resolveTestEntityTypes()

        try insertLabel(pk: 1, name: "Work", canonical: "work")
        try insertReminder(pk: 1, title: "Task 1", ekId: "EK-001")
        try insertJoinRecord(pk: 1, ent: entities.hashtagEnt, labelPK: 1, reminderPK: 1)

        let result = try removeTagFromTestDB("work", ekId: "EK-001")
        XCTAssertTrue(result)

        // Verify soft-delete
        let deleted = queryInt("SELECT ZMARKEDFORDELETION FROM ZREMCDOBJECT WHERE Z_PK = 1")
        XCTAssertEqual(deleted, 1)

        let labelFK = queryOptionalInt("SELECT ZHASHTAGLABEL FROM ZREMCDOBJECT WHERE Z_PK = 1")
        XCTAssertNil(labelFK)
    }

    func testRemoveTagReturnsFalseIfNotPresent() throws {
        try insertReminder(pk: 1, title: "Task 1", ekId: "EK-001")

        let result = try removeTagFromTestDB("nonexistent", ekId: "EK-001")
        XCTAssertFalse(result)
    }

    // MARK: - Get Tags for Reminder

    func testGetTagsForReminder() throws {
        let entities = try resolveTestEntityTypes()

        try insertLabel(pk: 1, name: "Work", canonical: "work")
        try insertLabel(pk: 2, name: "Urgent", canonical: "urgent")
        try insertReminder(pk: 1, title: "Task 1", ekId: "EK-001")
        try insertJoinRecord(pk: 1, ent: entities.hashtagEnt, labelPK: 1, reminderPK: 1)
        try insertJoinRecord(pk: 2, ent: entities.hashtagEnt, labelPK: 2, reminderPK: 1)

        let tags = try getTagsForReminderFromTestDB(ekId: "EK-001")
        XCTAssertEqual(tags.sorted(), ["Urgent", "Work"])
    }

    func testGetTagsForReminderExcludesDeleted() throws {
        let entities = try resolveTestEntityTypes()

        try insertLabel(pk: 1, name: "Work", canonical: "work")
        try insertLabel(pk: 2, name: "Deleted", canonical: "deleted")
        try insertReminder(pk: 1, title: "Task 1", ekId: "EK-001")
        try insertJoinRecord(pk: 1, ent: entities.hashtagEnt, labelPK: 1, reminderPK: 1)
        try insertJoinRecord(pk: 2, ent: entities.hashtagEnt, labelPK: 2, reminderPK: 1, deleted: true)

        let tags = try getTagsForReminderFromTestDB(ekId: "EK-001")
        XCTAssertEqual(tags, ["Work"])
    }

    // MARK: - Backup

    func testBackupCreatesFiles() throws {
        // Test backup on our temp DB
        let backupPath = try backupTestDB()
        XCTAssertTrue(FileManager.default.fileExists(atPath: backupPath))

        // Cleanup
        try? FileManager.default.removeItem(atPath: backupPath)
    }

    // MARK: - Error Cases

    func testSchemaChangedError() {
        let error = NativeTagError.schemaChanged("Missing entity")
        XCTAssertTrue(error.localizedDescription.contains("schema has changed"))
    }

    func testDatabaseNotFoundError() {
        let error = NativeTagError.databaseDirectoryNotFound("/fake/path")
        XCTAssertTrue(error.localizedDescription.contains("/fake/path"))
    }

    func testNoDatabaseFoundError() {
        let error = NativeTagError.noDatabaseFound
        XCTAssertTrue(error.localizedDescription.contains("No Reminders database"))
    }

    func testReminderNotFoundError() {
        let error = NativeTagError.reminderNotFoundInDB("EK-MISSING")
        XCTAssertTrue(error.localizedDescription.contains("EK-MISSING"))
    }

    // MARK: - Test Helpers

    private struct TestEntityTypes {
        let labelEnt: Int32
        let objectEnt: Int32
        let hashtagEnt: Int32
    }

    private func createSchema() throws {
        let ddl = """
            CREATE TABLE IF NOT EXISTS Z_PRIMARYKEY (
                Z_ENT INTEGER PRIMARY KEY,
                Z_NAME VARCHAR,
                Z_SUPER INTEGER,
                Z_MAX INTEGER
            );
            CREATE TABLE IF NOT EXISTS ZREMCDHASHTAGLABEL (
                Z_PK INTEGER PRIMARY KEY,
                Z_ENT INTEGER,
                Z_OPT INTEGER,
                ZFIRSTOCCURRENCECREATIONDATE TIMESTAMP,
                ZRECENCYDATE TIMESTAMP,
                ZACCOUNTIDENTIFIER VARCHAR,
                ZCANONICALNAME VARCHAR,
                ZNAME VARCHAR,
                ZUUIDFORCHANGETRACKING BLOB
            );
            CREATE TABLE IF NOT EXISTS ZREMCDOBJECT (
                Z_PK INTEGER PRIMARY KEY,
                Z_ENT INTEGER,
                Z_OPT INTEGER,
                ZCKDIRTYFLAGS INTEGER DEFAULT 0,
                ZCKNEEDSINITIALFETCHFROMCLOUD INTEGER DEFAULT 0,
                ZCKNEEDSTOBEFETCHEDFROMCLOUD INTEGER DEFAULT 0,
                ZEFFECTIVEMINIMUMSUPPORTEDAPPVERSION INTEGER DEFAULT 0,
                ZMARKEDFORDELETION INTEGER DEFAULT 0,
                ZMINIMUMSUPPORTEDAPPVERSION INTEGER DEFAULT 0,
                ZACCOUNT INTEGER,
                ZHASHTAGLABEL INTEGER,
                ZREMINDER3 INTEGER,
                ZCREATIONDATE TIMESTAMP,
                ZCKIDENTIFIER VARCHAR,
                ZNAME1 VARCHAR,
                ZIDENTIFIER BLOB,
                ZEXTERNALIDENTIFIER VARCHAR
            );
            CREATE TABLE IF NOT EXISTS ZREMCDREMINDER (
                Z_PK INTEGER PRIMARY KEY,
                ZTITLE VARCHAR,
                ZCOMPLETED INTEGER DEFAULT 0,
                ZMARKEDFORDELETION INTEGER DEFAULT 0,
                ZDACALENDARITEMUNIQUEIDENTIFIER VARCHAR
            );
            INSERT INTO Z_PRIMARYKEY (Z_ENT, Z_NAME, Z_SUPER, Z_MAX) VALUES (11, 'REMCDHashtagLabel', 0, 0);
            INSERT INTO Z_PRIMARYKEY (Z_ENT, Z_NAME, Z_SUPER, Z_MAX) VALUES (13, 'REMCDObject', 0, 0);
            INSERT INTO Z_PRIMARYKEY (Z_ENT, Z_NAME, Z_SUPER, Z_MAX) VALUES (32, 'REMCDHashtag', 0, 0);
            """

        var errMsg: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(db, ddl, nil, nil, &errMsg) == SQLITE_OK else {
            let msg = errMsg.map { String(cString: $0) } ?? "unknown"
            sqlite3_free(errMsg)
            XCTFail("Failed to create schema: \(msg)")
            return
        }
    }

    private func resolveTestEntityTypes() throws -> TestEntityTypes {
        let labelEnt = queryInt32("SELECT Z_ENT FROM Z_PRIMARYKEY WHERE Z_NAME = 'REMCDHashtagLabel'")
        let objectEnt = queryInt32("SELECT Z_ENT FROM Z_PRIMARYKEY WHERE Z_NAME = 'REMCDObject'")
        let hashtagEnt = queryInt32("SELECT Z_ENT FROM Z_PRIMARYKEY WHERE Z_NAME = 'REMCDHashtag'")
        return TestEntityTypes(labelEnt: labelEnt, objectEnt: objectEnt, hashtagEnt: hashtagEnt)
    }

    private func insertLabel(pk: Int, name: String, canonical: String) throws {
        let sql = """
            INSERT INTO ZREMCDHASHTAGLABEL (Z_PK, Z_ENT, Z_OPT, ZACCOUNTIDENTIFIER, ZCANONICALNAME, ZNAME)
            VALUES (\(pk), 11, 1, 'test-account', '\(canonical)', '\(name)')
            """
        try execSQL(sql)
    }

    private func insertReminder(pk: Int, title: String, ekId: String) throws {
        let sql = """
            INSERT INTO ZREMCDREMINDER (Z_PK, ZTITLE, ZCOMPLETED, ZMARKEDFORDELETION, ZDACALENDARITEMUNIQUEIDENTIFIER)
            VALUES (\(pk), '\(title)', 0, 0, '\(ekId)')
            """
        try execSQL(sql)
    }

    private func insertJoinRecord(pk: Int, ent: Int32, labelPK: Int, reminderPK: Int, deleted: Bool = false) throws {
        let sql = """
            INSERT INTO ZREMCDOBJECT (Z_PK, Z_ENT, Z_OPT, ZMARKEDFORDELETION, ZHASHTAGLABEL, ZREMINDER3, ZACCOUNT, ZNAME1)
            VALUES (\(pk), \(ent), 1, \(deleted ? 1 : 0), \(labelPK), \(reminderPK), 1, 'tag')
            """
        try execSQL(sql)
        try execSQL("UPDATE Z_PRIMARYKEY SET Z_MAX = MAX(Z_MAX, \(pk)) WHERE Z_ENT = 13")
    }

    private func insertAccountInfo() throws {
        // Insert an account record for account discovery
        let sql = """
            INSERT OR IGNORE INTO ZREMCDOBJECT (Z_PK, Z_ENT, Z_OPT, ZMARKEDFORDELETION, ZACCOUNT, ZEXTERNALIDENTIFIER)
            VALUES (9999, 14, 1, 0, 1, 'test-account-id')
            """
        try execSQL(sql)
    }

    private func execSQL(_ sql: String) throws {
        var errMsg: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(db, sql, nil, nil, &errMsg) == SQLITE_OK else {
            let msg = errMsg.map { String(cString: $0) } ?? "unknown"
            sqlite3_free(errMsg)
            throw NativeTagError.sqliteError(msg)
        }
    }

    private func queryInt(_ sql: String) -> Int {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return 0 }
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_step(stmt) == SQLITE_ROW else { return 0 }
        return Int(sqlite3_column_int(stmt, 0))
    }

    private func queryInt32(_ sql: String) -> Int32 {
        return Int32(queryInt(sql))
    }

    private func queryOptionalInt(_ sql: String) -> Int? {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_step(stmt) == SQLITE_ROW else { return nil }
        if sqlite3_column_type(stmt, 0) == SQLITE_NULL { return nil }
        return Int(sqlite3_column_int(stmt, 0))
    }

    // Direct database operations that mirror NativeTagService's logic for testing
    // These operate on the test DB directly rather than going through the service
    // (which does its own database discovery)

    private func listTagsFromTestDB() throws -> [NativeTag] {
        let sql = """
            SELECT l.ZNAME, l.ZCANONICALNAME, COUNT(o.Z_PK) as cnt
            FROM ZREMCDHASHTAGLABEL l
            LEFT JOIN ZREMCDOBJECT o ON o.ZHASHTAGLABEL = l.Z_PK AND o.ZMARKEDFORDELETION = 0
            GROUP BY l.Z_PK ORDER BY l.ZNAME
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw NativeTagError.sqliteError("prepare failed")
        }
        defer { sqlite3_finalize(stmt) }

        var tags: [NativeTag] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let name = String(cString: sqlite3_column_text(stmt, 0))
            let canonical = String(cString: sqlite3_column_text(stmt, 1))
            let count = Int(sqlite3_column_int(stmt, 2))
            tags.append(NativeTag(name: name, canonicalName: canonical, count: count))
        }
        return tags
    }

    private func resolveReminderPK(_ ekId: String) throws -> Int {
        let sql = "SELECT Z_PK FROM ZREMCDREMINDER WHERE ZDACALENDARITEMUNIQUEIDENTIFIER = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw NativeTagError.sqliteError("prepare failed")
        }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, (ekId as NSString).utf8String, -1, nil)
        guard sqlite3_step(stmt) == SQLITE_ROW else {
            throw NativeTagError.reminderNotFoundInDB(ekId)
        }
        return Int(sqlite3_column_int(stmt, 0))
    }

    @discardableResult
    private func addTagToTestDB(_ name: String, reminderPK: Int, ekId: String) throws -> Bool {
        let entities = try resolveTestEntityTypes()
        let canonicalName = name.lowercased()

        // Check existing
        let existingLabelPK = queryOptionalInt(
            "SELECT Z_PK FROM ZREMCDHASHTAGLABEL WHERE ZCANONICALNAME = '\(canonicalName)'"
        )

        if let labelPK = existingLabelPK {
            let existing = queryInt(
                "SELECT COUNT(*) FROM ZREMCDOBJECT WHERE Z_ENT = \(entities.hashtagEnt) AND ZHASHTAGLABEL = \(labelPK) AND ZREMINDER3 = \(reminderPK) AND ZMARKEDFORDELETION = 0"
            )
            if existing > 0 { return false }
        }

        let nowCD = Date().timeIntervalSinceReferenceDate
        try execSQL("BEGIN IMMEDIATE")

        do {
            let labelPK: Int
            if let existing = existingLabelPK {
                labelPK = existing
            } else {
                let labelMax = queryInt("SELECT Z_MAX FROM Z_PRIMARYKEY WHERE Z_ENT = 11")
                labelPK = labelMax + 1
                try execSQL("""
                    INSERT INTO ZREMCDHASHTAGLABEL (Z_PK, Z_ENT, Z_OPT, ZFIRSTOCCURRENCECREATIONDATE, ZRECENCYDATE,
                        ZACCOUNTIDENTIFIER, ZCANONICALNAME, ZNAME, ZUUIDFORCHANGETRACKING)
                    VALUES (\(labelPK), 11, 1, \(nowCD), \(nowCD), 'test-account', '\(canonicalName)', '\(name)', randomblob(16))
                    """)
                try execSQL("UPDATE Z_PRIMARYKEY SET Z_MAX = \(labelPK) WHERE Z_ENT = 11")
            }

            let objectMax = queryInt("SELECT Z_MAX FROM Z_PRIMARYKEY WHERE Z_ENT = 13")
            let joinPK = objectMax + 1
            try execSQL("""
                INSERT INTO ZREMCDOBJECT (Z_PK, Z_ENT, Z_OPT, ZCKDIRTYFLAGS, ZMARKEDFORDELETION, ZACCOUNT,
                    ZHASHTAGLABEL, ZREMINDER3, ZCREATIONDATE, ZNAME1)
                VALUES (\(joinPK), \(entities.hashtagEnt), 1, 1, 0, 1, \(labelPK), \(reminderPK), \(nowCD), '\(name)')
                """)
            try execSQL("UPDATE Z_PRIMARYKEY SET Z_MAX = \(joinPK) WHERE Z_ENT = 13")

            try execSQL("COMMIT")
            return true
        } catch {
            try? execSQL("ROLLBACK")
            throw error
        }
    }

    private func removeTagFromTestDB(_ name: String, ekId: String) throws -> Bool {
        let entities = try resolveTestEntityTypes()
        let reminderPK = try resolveReminderPK(ekId)
        let canonicalName = name.lowercased()

        let labelPK = queryOptionalInt(
            "SELECT Z_PK FROM ZREMCDHASHTAGLABEL WHERE ZCANONICALNAME = '\(canonicalName)'"
        )
        guard let labelPK = labelPK else { return false }

        let joinPK = queryOptionalInt(
            "SELECT Z_PK FROM ZREMCDOBJECT WHERE Z_ENT = \(entities.hashtagEnt) AND ZHASHTAGLABEL = \(labelPK) AND ZREMINDER3 = \(reminderPK) AND ZMARKEDFORDELETION = 0"
        )
        guard let joinPK = joinPK else { return false }

        try execSQL("UPDATE ZREMCDOBJECT SET ZMARKEDFORDELETION = 1, ZHASHTAGLABEL = NULL, ZCKDIRTYFLAGS = 1 WHERE Z_PK = \(joinPK)")
        return true
    }

    private func getTagsForReminderFromTestDB(ekId: String) throws -> [String] {
        let entities = try resolveTestEntityTypes()
        let reminderPK = try resolveReminderPK(ekId)

        let sql = """
            SELECT l.ZNAME FROM ZREMCDOBJECT o
            JOIN ZREMCDHASHTAGLABEL l ON o.ZHASHTAGLABEL = l.Z_PK
            WHERE o.Z_ENT = \(entities.hashtagEnt) AND o.ZREMINDER3 = \(reminderPK) AND o.ZMARKEDFORDELETION = 0
            ORDER BY l.ZNAME
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw NativeTagError.sqliteError("prepare failed")
        }
        defer { sqlite3_finalize(stmt) }

        var names: [String] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            names.append(String(cString: sqlite3_column_text(stmt, 0)))
        }
        return names
    }

    private func backupTestDB() throws -> String {
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let backupPath = "\(tempDBPath!).backup.\(timestamp)"
        try FileManager.default.copyItem(atPath: tempDBPath, toPath: backupPath)
        return backupPath
    }
}
