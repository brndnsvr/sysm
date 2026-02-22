import Foundation
import SQLite3

/// Reads and writes native Reminders tags via the Core Data SQLite database.
///
/// This service directly accesses the Reminders database at
/// `~/Library/Group Containers/group.com.apple.reminders/Container_v1/Stores/`.
/// Tags created this way appear as native tag pills in Reminders.app, work with
/// smart lists, and show up in autocomplete.
///
/// ## Important
///
/// Reminders.app caches Core Data in memory. Changes made while the app is running
/// may be overwritten or not visible until the app is restarted.
public struct NativeTagService: NativeTagServiceProtocol {
    /// Resolved entity type numbers from Z_PRIMARYKEY (never hardcoded).
    private struct EntityTypes {
        let hashtagLabel: Int32  // REMCDHashtagLabel
        let object: Int32        // REMCDObject
        let hashtag: Int32       // REMCDHashtag
    }

    public init() {}

    // MARK: - Public API

    public func listTags() throws -> [NativeTag] {
        let dbPath = try findDatabase()
        let db = try openDatabase(dbPath)
        defer { sqlite3_close(db) }

        let sql = """
            SELECT l.ZNAME, l.ZCANONICALNAME,
                   COUNT(o.Z_PK) as cnt
            FROM ZREMCDHASHTAGLABEL l
            LEFT JOIN ZREMCDOBJECT o ON o.ZHASHTAGLABEL = l.Z_PK
              AND o.ZMARKEDFORDELETION = 0
            GROUP BY l.Z_PK
            ORDER BY l.ZNAME
            """

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            let msg = String(cString: sqlite3_errmsg(db))
            throw NativeTagError.sqliteError("Failed to prepare list query: \(msg)")
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

    public func getTagsForReminder(eventKitId: String) throws -> [String] {
        let dbPath = try findDatabase()
        let db = try openDatabase(dbPath)
        defer { sqlite3_close(db) }

        let entities = try resolveEntityTypes(db)
        let reminderPK = try resolveReminderPK(db, eventKitId: eventKitId)

        let sql = """
            SELECT l.ZNAME
            FROM ZREMCDOBJECT o
            JOIN ZREMCDHASHTAGLABEL l ON o.ZHASHTAGLABEL = l.Z_PK
            WHERE o.Z_ENT = ? AND o.ZREMINDER3 = ? AND o.ZMARKEDFORDELETION = 0
            ORDER BY l.ZNAME
            """

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            let msg = String(cString: sqlite3_errmsg(db))
            throw NativeTagError.sqliteError("Failed to prepare tags query: \(msg)")
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_int(stmt, 1, entities.hashtag)
        sqlite3_bind_int(stmt, 2, Int32(reminderPK))

        var names: [String] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            names.append(String(cString: sqlite3_column_text(stmt, 0)))
        }
        return names
    }

    public func addTag(_ name: String, toReminder eventKitId: String) throws -> Bool {
        let dbPath = try findDatabase()
        let db = try openDatabase(dbPath)
        defer { sqlite3_close(db) }

        let entities = try resolveEntityTypes(db)
        let reminderPK = try resolveReminderPK(db, eventKitId: eventKitId)
        let canonicalName = name.lowercased()

        // Check if already tagged
        let existingLabelPK = try findLabelPK(db, canonicalName: canonicalName)
        if let labelPK = existingLabelPK {
            if try joinRecordExists(db, entities: entities, labelPK: labelPK, reminderPK: reminderPK) {
                return false // Already tagged
            }
        }

        // Discover account info
        let (accountIdentifier, accountFK) = try discoverAccount(db, entities: entities)

        // Core Data timestamp: seconds since 2001-01-01
        let nowCD = Date().timeIntervalSinceReferenceDate

        try exec(db, "BEGIN IMMEDIATE")
        do {
            // Step 1: Create or reuse label
            let labelPK: Int
            if let existing = existingLabelPK {
                labelPK = existing
                // Update recency date
                try execBind(db, "UPDATE ZREMCDHASHTAGLABEL SET ZRECENCYDATE = ? WHERE Z_PK = ?") { stmt in
                    sqlite3_bind_double(stmt, 1, nowCD)
                    sqlite3_bind_int(stmt, 2, Int32(labelPK))
                }
            } else {
                let labelMax = try getZMax(db, ent: entities.hashtagLabel)
                labelPK = labelMax + 1

                let insertLabel = """
                    INSERT INTO ZREMCDHASHTAGLABEL (
                        Z_PK, Z_ENT, Z_OPT,
                        ZFIRSTOCCURRENCECREATIONDATE, ZRECENCYDATE,
                        ZACCOUNTIDENTIFIER, ZCANONICALNAME, ZNAME,
                        ZUUIDFORCHANGETRACKING
                    ) VALUES (?, ?, 1, ?, ?, ?, ?, ?, randomblob(16))
                    """
                try execBind(db, insertLabel) { stmt in
                    sqlite3_bind_int(stmt, 1, Int32(labelPK))
                    sqlite3_bind_int(stmt, 2, entities.hashtagLabel)
                    sqlite3_bind_double(stmt, 3, nowCD)
                    sqlite3_bind_double(stmt, 4, nowCD)
                    sqlite3_bind_text(stmt, 5, (accountIdentifier as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(stmt, 6, (canonicalName as NSString).utf8String, -1, nil)
                    sqlite3_bind_text(stmt, 7, (name as NSString).utf8String, -1, nil)
                }

                try updateZMax(db, ent: entities.hashtagLabel, newMax: labelPK)
            }

            // Step 2: Create join record (REMCDHashtag)
            let objectMax = try getZMax(db, ent: entities.object)
            let joinPK = objectMax + 1
            let ckUUID = UUID().uuidString.uppercased()

            let insertJoin = """
                INSERT INTO ZREMCDOBJECT (
                    Z_PK, Z_ENT, Z_OPT,
                    ZCKDIRTYFLAGS,
                    ZCKNEEDSINITIALFETCHFROMCLOUD,
                    ZCKNEEDSTOBEFETCHEDFROMCLOUD,
                    ZEFFECTIVEMINIMUMSUPPORTEDAPPVERSION,
                    ZMARKEDFORDELETION,
                    ZMINIMUMSUPPORTEDAPPVERSION,
                    ZACCOUNT,
                    ZHASHTAGLABEL,
                    ZREMINDER3,
                    ZCREATIONDATE,
                    ZCKIDENTIFIER,
                    ZNAME1,
                    ZIDENTIFIER
                ) VALUES (?, ?, 1, 1, 0, 0, 0, 0, 0, ?, ?, ?, ?, ?, ?, randomblob(16))
                """
            try execBind(db, insertJoin) { stmt in
                sqlite3_bind_int(stmt, 1, Int32(joinPK))
                sqlite3_bind_int(stmt, 2, entities.hashtag)
                sqlite3_bind_int(stmt, 3, Int32(accountFK))
                sqlite3_bind_int(stmt, 4, Int32(labelPK))
                sqlite3_bind_int(stmt, 5, Int32(reminderPK))
                sqlite3_bind_double(stmt, 6, nowCD)
                sqlite3_bind_text(stmt, 7, (ckUUID as NSString).utf8String, -1, nil)
                sqlite3_bind_text(stmt, 8, (name as NSString).utf8String, -1, nil)
            }

            try updateZMax(db, ent: entities.object, newMax: joinPK)

            try exec(db, "COMMIT")
            return true
        } catch {
            try? exec(db, "ROLLBACK")
            throw error
        }
    }

    public func removeTag(_ name: String, fromReminder eventKitId: String) throws -> Bool {
        let dbPath = try findDatabase()
        let db = try openDatabase(dbPath)
        defer { sqlite3_close(db) }

        let entities = try resolveEntityTypes(db)
        let reminderPK = try resolveReminderPK(db, eventKitId: eventKitId)
        let canonicalName = name.lowercased()

        guard let labelPK = try findLabelPK(db, canonicalName: canonicalName) else {
            return false // Tag doesn't exist
        }

        // Find the join record
        let sql = """
            SELECT Z_PK FROM ZREMCDOBJECT
            WHERE Z_ENT = ? AND ZHASHTAGLABEL = ? AND ZREMINDER3 = ? AND ZMARKEDFORDELETION = 0
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            let msg = String(cString: sqlite3_errmsg(db))
            throw NativeTagError.sqliteError("Failed to find join record: \(msg)")
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_int(stmt, 1, entities.hashtag)
        sqlite3_bind_int(stmt, 2, Int32(labelPK))
        sqlite3_bind_int(stmt, 3, Int32(reminderPK))

        guard sqlite3_step(stmt) == SQLITE_ROW else {
            return false // Not tagged
        }
        let joinPK = sqlite3_column_int(stmt, 0)

        // Soft-delete matching Apple's convention
        let update = """
            UPDATE ZREMCDOBJECT
            SET ZMARKEDFORDELETION = 1, ZHASHTAGLABEL = NULL, ZCKDIRTYFLAGS = 1
            WHERE Z_PK = ?
            """
        try execBind(db, update) { stmt in
            sqlite3_bind_int(stmt, 1, joinPK)
        }

        return true
    }

    public func backupDatabase() throws -> String {
        let dbPath = try findDatabase()
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let backupPath = "\(dbPath).backup.\(timestamp)"

        let fm = FileManager.default
        do {
            try fm.copyItem(atPath: dbPath, toPath: backupPath)

            // Backup WAL and SHM if present
            let walPath = "\(dbPath)-wal"
            let shmPath = "\(dbPath)-shm"
            if fm.fileExists(atPath: walPath) {
                try fm.copyItem(atPath: walPath, toPath: "\(backupPath)-wal")
            }
            if fm.fileExists(atPath: shmPath) {
                try fm.copyItem(atPath: shmPath, toPath: "\(backupPath)-shm")
            }
        } catch {
            throw NativeTagError.backupFailed(error.localizedDescription)
        }

        return backupPath
    }

    // MARK: - Database Discovery

    internal func findDatabase() throws -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let baseDir = "\(home)/Library/Group Containers/group.com.apple.reminders/Container_v1/Stores"

        guard FileManager.default.fileExists(atPath: baseDir) else {
            throw NativeTagError.databaseDirectoryNotFound(baseDir)
        }

        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(atPath: baseDir) else {
            throw NativeTagError.databaseDirectoryNotFound(baseDir)
        }

        var bestPath: String?
        var maxCount = 0

        for file in contents {
            guard file.hasPrefix("Data-") && file.hasSuffix(".sqlite") else { continue }
            guard !file.contains("local") else { continue }

            let fullPath = "\(baseDir)/\(file)"
            if let db = try? openDatabase(fullPath) {
                defer { sqlite3_close(db) }
                let count = queryInt(db, "SELECT COUNT(*) FROM ZREMCDREMINDER WHERE ZMARKEDFORDELETION = 0")
                if count > maxCount {
                    maxCount = count
                    bestPath = fullPath
                }
            }
        }

        guard let path = bestPath else {
            throw NativeTagError.noDatabaseFound
        }

        return path
    }

    // MARK: - Database Helpers

    private func openDatabase(_ path: String) throws -> OpaquePointer {
        var db: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(path, &db, flags, nil) == SQLITE_OK else {
            let msg = db.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown error"
            if let db = db { sqlite3_close(db) }
            throw NativeTagError.databaseOpenFailed(path, msg)
        }

        // Set busy timeout for concurrent access
        sqlite3_busy_timeout(db, 5000)

        return db!
    }

    private func resolveEntityTypes(_ db: OpaquePointer) throws -> EntityTypes {
        let labelEnt = queryInt32(db, "SELECT Z_ENT FROM Z_PRIMARYKEY WHERE Z_NAME = 'REMCDHashtagLabel'")
        let objectEnt = queryInt32(db, "SELECT Z_ENT FROM Z_PRIMARYKEY WHERE Z_NAME = 'REMCDObject'")
        let hashtagEnt = queryInt32(db, "SELECT Z_ENT FROM Z_PRIMARYKEY WHERE Z_NAME = 'REMCDHashtag'")

        guard labelEnt > 0 && objectEnt > 0 && hashtagEnt > 0 else {
            throw NativeTagError.schemaChanged("Required entity types not found in Z_PRIMARYKEY")
        }

        return EntityTypes(hashtagLabel: labelEnt, object: objectEnt, hashtag: hashtagEnt)
    }

    private func resolveReminderPK(_ db: OpaquePointer, eventKitId: String) throws -> Int {
        let sql = "SELECT Z_PK FROM ZREMCDREMINDER WHERE ZDACALENDARITEMUNIQUEIDENTIFIER = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            let msg = String(cString: sqlite3_errmsg(db))
            throw NativeTagError.sqliteError("Failed to resolve reminder: \(msg)")
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, (eventKitId as NSString).utf8String, -1, nil)

        guard sqlite3_step(stmt) == SQLITE_ROW else {
            throw NativeTagError.reminderNotFoundInDB(eventKitId)
        }

        return Int(sqlite3_column_int(stmt, 0))
    }

    private func findLabelPK(_ db: OpaquePointer, canonicalName: String) throws -> Int? {
        let sql = "SELECT Z_PK FROM ZREMCDHASHTAGLABEL WHERE ZCANONICALNAME = ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            let msg = String(cString: sqlite3_errmsg(db))
            throw NativeTagError.sqliteError("Failed to find label: \(msg)")
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, (canonicalName as NSString).utf8String, -1, nil)

        guard sqlite3_step(stmt) == SQLITE_ROW else {
            return nil
        }
        return Int(sqlite3_column_int(stmt, 0))
    }

    private func joinRecordExists(_ db: OpaquePointer, entities: EntityTypes, labelPK: Int, reminderPK: Int) throws -> Bool {
        let sql = """
            SELECT Z_PK FROM ZREMCDOBJECT
            WHERE Z_ENT = ? AND ZHASHTAGLABEL = ? AND ZREMINDER3 = ? AND ZMARKEDFORDELETION = 0
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            let msg = String(cString: sqlite3_errmsg(db))
            throw NativeTagError.sqliteError("Failed to check join record: \(msg)")
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_int(stmt, 1, entities.hashtag)
        sqlite3_bind_int(stmt, 2, Int32(labelPK))
        sqlite3_bind_int(stmt, 3, Int32(reminderPK))

        return sqlite3_step(stmt) == SQLITE_ROW
    }

    private func discoverAccount(_ db: OpaquePointer, entities: EntityTypes) throws -> (identifier: String, fk: Int) {
        // Try to get from existing label
        var stmt: OpaquePointer?
        let labelSQL = "SELECT ZACCOUNTIDENTIFIER FROM ZREMCDHASHTAGLABEL WHERE ZACCOUNTIDENTIFIER IS NOT NULL LIMIT 1"
        var accountIdentifier: String?

        if sqlite3_prepare_v2(db, labelSQL, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                accountIdentifier = String(cString: sqlite3_column_text(stmt, 0))
            }
            sqlite3_finalize(stmt)
        }

        // Get account FK from existing join records
        let fkSQL = "SELECT ZACCOUNT FROM ZREMCDOBJECT WHERE Z_ENT = ? AND ZMARKEDFORDELETION = 0 AND ZACCOUNT IS NOT NULL LIMIT 1"
        var accountFK = 1
        stmt = nil
        if sqlite3_prepare_v2(db, fkSQL, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, entities.hashtag)
            if sqlite3_step(stmt) == SQLITE_ROW {
                accountFK = Int(sqlite3_column_int(stmt, 0))
            }
            sqlite3_finalize(stmt)
        }

        // Fallback: try account table (Z_ENT=14 is typically REMCDAccount)
        if accountIdentifier == nil {
            let accountSQL = "SELECT ZEXTERNALIDENTIFIER FROM ZREMCDOBJECT WHERE Z_ENT = 14 LIMIT 1"
            stmt = nil
            if sqlite3_prepare_v2(db, accountSQL, -1, &stmt, nil) == SQLITE_OK {
                if sqlite3_step(stmt) == SQLITE_ROW {
                    accountIdentifier = String(cString: sqlite3_column_text(stmt, 0))
                }
                sqlite3_finalize(stmt)
            }
        }

        guard let identifier = accountIdentifier else {
            throw NativeTagError.accountNotFound
        }

        return (identifier, accountFK)
    }

    private func getZMax(_ db: OpaquePointer, ent: Int32) throws -> Int {
        return queryInt(db, "SELECT Z_MAX FROM Z_PRIMARYKEY WHERE Z_ENT = \(ent)")
    }

    private func updateZMax(_ db: OpaquePointer, ent: Int32, newMax: Int) throws {
        try exec(db, "UPDATE Z_PRIMARYKEY SET Z_MAX = \(newMax) WHERE Z_ENT = \(ent)")
    }

    // MARK: - Low-level SQLite

    private func exec(_ db: OpaquePointer, _ sql: String) throws {
        var errMsg: UnsafeMutablePointer<CChar>?
        guard sqlite3_exec(db, sql, nil, nil, &errMsg) == SQLITE_OK else {
            let msg = errMsg.map { String(cString: $0) } ?? "unknown error"
            sqlite3_free(errMsg)
            throw NativeTagError.sqliteError(msg)
        }
    }

    private func execBind(_ db: OpaquePointer, _ sql: String, bind: (OpaquePointer) -> Void) throws {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            let msg = String(cString: sqlite3_errmsg(db))
            throw NativeTagError.sqliteError("Failed to prepare: \(msg)")
        }
        defer { sqlite3_finalize(stmt) }

        bind(stmt!)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            let msg = String(cString: sqlite3_errmsg(db))
            throw NativeTagError.sqliteError("Failed to execute: \(msg)")
        }
    }

    private func queryInt(_ db: OpaquePointer, _ sql: String) -> Int {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return 0 }
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_step(stmt) == SQLITE_ROW else { return 0 }
        return Int(sqlite3_column_int(stmt, 0))
    }

    private func queryInt32(_ db: OpaquePointer, _ sql: String) -> Int32 {
        return Int32(queryInt(db, sql))
    }
}

// MARK: - Errors

public enum NativeTagError: LocalizedError {
    case databaseDirectoryNotFound(String)
    case noDatabaseFound
    case databaseOpenFailed(String, String)
    case schemaChanged(String)
    case reminderNotFoundInDB(String)
    case accountNotFound
    case sqliteError(String)
    case backupFailed(String)

    public var errorDescription: String? {
        switch self {
        case .databaseDirectoryNotFound(let path):
            return "Reminders database directory not found: \(path)"
        case .noDatabaseFound:
            return "No Reminders database found with active reminders"
        case .databaseOpenFailed(let path, let reason):
            return "Failed to open database at \(path): \(reason)"
        case .schemaChanged(let detail):
            return "Reminders database schema has changed: \(detail)"
        case .reminderNotFoundInDB(let id):
            return "Reminder not found in database: \(id)"
        case .accountNotFound:
            return "Cannot determine iCloud account identifier"
        case .sqliteError(let msg):
            return "SQLite error: \(msg)"
        case .backupFailed(let reason):
            return "Database backup failed: \(reason)"
        }
    }
}
