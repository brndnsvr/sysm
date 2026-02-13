import XCTest
@testable import SysmCore

/// Tests for CacheService with TTL, expiration, and invalidation.
final class CacheServiceTests: XCTestCase {
    var cacheService: CacheService!
    var tempCachePath: URL!

    override func setUp() async throws {
        try await super.setUp()

        // Create temporary cache file for testing
        tempCachePath = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_cache_\(UUID().uuidString).json")

        cacheService = CacheService()
        // Reset to empty state for test isolation
        try cacheService.saveCache(SysmCache())
    }

    override func tearDown() async throws {
        // Clean up temp cache file
        if let tempCachePath = tempCachePath,
           FileManager.default.fileExists(atPath: tempCachePath.path) {
            try? FileManager.default.removeItem(at: tempCachePath)
        }

        cacheService = nil
        tempCachePath = nil

        try await super.tearDown()
    }

    // MARK: - Basic Cache Operations

    func testSetAndGet() throws {
        let testValue = ["key1": "value1", "key2": "value2"]

        try cacheService.set("test:dict", value: testValue, ttl: 60)

        let retrieved: [String: String]? = try cacheService.get("test:dict", as: [String: String].self)

        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?["key1"], "value1")
        XCTAssertEqual(retrieved?["key2"], "value2")
    }

    func testGetNonExistentKey() throws {
        let retrieved: String? = try cacheService.get("nonexistent", as: String.self)
        XCTAssertNil(retrieved)
    }

    func testSetWithZeroTTL() throws {
        let testValue = "persistent value"

        try cacheService.set("test:persistent", value: testValue, ttl: 0)

        let retrieved: String? = try cacheService.get("test:persistent", as: String.self)

        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved, testValue)
    }

    // MARK: - TTL and Expiration

    func testExpirationAfterTTL() throws {
        let testValue = "expires soon"

        // Set with 1 second TTL
        try cacheService.set("test:expires", value: testValue, ttl: 1)

        // Should be available immediately
        var retrieved: String? = try cacheService.get("test:expires", as: String.self)
        XCTAssertNotNil(retrieved)

        // Wait for expiration
        Thread.sleep(forTimeInterval: 1.5)

        // Should be nil after expiration
        retrieved = try cacheService.get("test:expires", as: String.self)
        XCTAssertNil(retrieved)
    }

    func testMultipleEntriesWithDifferentTTL() throws {
        try cacheService.set("test:short", value: "short-lived", ttl: 1)
        try cacheService.set("test:long", value: "long-lived", ttl: 10)

        // Both should be available immediately
        XCTAssertNotNil(try cacheService.get("test:short", as: String.self))
        XCTAssertNotNil(try cacheService.get("test:long", as: String.self))

        // Wait for short TTL to expire
        Thread.sleep(forTimeInterval: 1.5)

        // Short should be expired, long should still be available
        XCTAssertNil(try cacheService.get("test:short", as: String.self))
        XCTAssertNotNil(try cacheService.get("test:long", as: String.self))
    }

    // MARK: - Invalidation

    func testInvalidateSingleKey() throws {
        try cacheService.set("test:remove", value: "will be removed", ttl: 60)

        // Verify it exists
        XCTAssertNotNil(try cacheService.get("test:remove", as: String.self))

        // Invalidate
        try cacheService.invalidate("test:remove")

        // Should be nil after invalidation
        XCTAssertNil(try cacheService.get("test:remove", as: String.self))
    }

    func testInvalidatePrefix() throws {
        try cacheService.set("calendar:today", value: ["event1"], ttl: 60)
        try cacheService.set("calendar:week", value: ["event2"], ttl: 60)
        try cacheService.set("contacts:search", value: ["contact1"], ttl: 60)

        // Verify all exist
        XCTAssertNotNil(try cacheService.get("calendar:today", as: [String].self))
        XCTAssertNotNil(try cacheService.get("calendar:week", as: [String].self))
        XCTAssertNotNil(try cacheService.get("contacts:search", as: [String].self))

        // Invalidate all calendar entries
        try cacheService.invalidatePrefix("calendar:")

        // Calendar entries should be nil, contacts should remain
        XCTAssertNil(try cacheService.get("calendar:today", as: [String].self))
        XCTAssertNil(try cacheService.get("calendar:week", as: [String].self))
        XCTAssertNotNil(try cacheService.get("contacts:search", as: [String].self))
    }

    func testClearCache() throws {
        try cacheService.set("test:1", value: "value1", ttl: 60)
        try cacheService.set("test:2", value: "value2", ttl: 60)

        // Track a reminder (should not be cleared)
        try cacheService.trackReminder(name: "Test Reminder", project: "Test")

        // Clear all cache entries
        try cacheService.clearCache()

        // Cache entries should be nil
        XCTAssertNil(try cacheService.get("test:1", as: String.self))
        XCTAssertNil(try cacheService.get("test:2", as: String.self))

        // Reminder tracking should still exist
        let reminders = cacheService.getSeenReminders()
        XCTAssertFalse(reminders.isEmpty)
    }

    // MARK: - Cleanup

    func testCleanupExpiredEntries() throws {
        try cacheService.set("test:expires1", value: "will expire", ttl: 1)
        try cacheService.set("test:expires2", value: "will expire too", ttl: 1)
        try cacheService.set("test:persistent", value: "stays forever", ttl: 0)

        // Wait for expiration
        Thread.sleep(forTimeInterval: 1.5)

        // Manually trigger cleanup
        try cacheService.cleanupExpired()

        // Expired entries should be gone
        XCTAssertNil(try cacheService.get("test:expires1", as: String.self))
        XCTAssertNil(try cacheService.get("test:expires2", as: String.self))

        // Persistent entry should remain
        XCTAssertNotNil(try cacheService.get("test:persistent", as: String.self))
    }

    // MARK: - Complex Types

    func testCachingComplexTypes() throws {
        struct TestModel: Codable, Equatable {
            let id: String
            let name: String
            let tags: [String]
        }

        let model = TestModel(id: "123", name: "Test", tags: ["a", "b", "c"])

        try cacheService.set("test:model", value: model, ttl: 60)

        let retrieved: TestModel? = try cacheService.get("test:model", as: TestModel.self)

        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved, model)
    }

    func testCachingArrays() throws {
        let events = ["Event 1", "Event 2", "Event 3"]

        try cacheService.set("calendar:list", value: events, ttl: 30)

        let retrieved: [String]? = try cacheService.get("calendar:list", as: [String].self)

        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.count, 3)
        XCTAssertEqual(retrieved?[0], "Event 1")
    }

    // MARK: - Reminder Tracking (Existing Functionality)

    func testReminderTracking() throws {
        try cacheService.trackReminder(name: "Test Task", project: "Work")

        let reminders = cacheService.getSeenReminders()

        XCTAssertFalse(reminders.isEmpty)

        let tracked = cacheService.getTrackedReminders()
        XCTAssertEqual(tracked.count, 1)
        XCTAssertEqual(tracked[0].reminder.originalName, "Test Task")
    }

    func testReminderCompletion() throws {
        try cacheService.trackReminder(name: "Complete Me", project: "Test")

        let completed = try cacheService.completeTracked(name: "Complete Me")
        XCTAssertTrue(completed)

        let reminders = cacheService.getSeenReminders()
        let key = TrackedReminder.makeKey("Complete Me")
        XCTAssertEqual(reminders[key]?.status, "done")
    }

    func testReminderUntrack() throws {
        try cacheService.trackReminder(name: "Remove Me", project: "Test")

        let removed = try cacheService.untrackReminder(name: "Remove Me")
        XCTAssertTrue(removed)

        let reminders = cacheService.getSeenReminders()
        let key = TrackedReminder.makeKey("Remove Me")
        XCTAssertNil(reminders[key])
    }
}
