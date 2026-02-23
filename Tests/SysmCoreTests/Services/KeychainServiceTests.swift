import XCTest

@testable import SysmCore

final class KeychainServiceTests: XCTestCase {
    private var service: KeychainService!
    private var testService: String!

    override func setUp() {
        super.setUp()
        service = KeychainService()
        testService = "com.brndnsvr.sysm.test.\(UUID().uuidString)"
    }

    override func tearDown() {
        // Clean up any test keychain items
        if let testService = testService {
            let accounts = ["testuser", "testuser1", "testuser2", "another-account", "searchme"]
            for account in accounts {
                try? service.delete(service: testService, account: account)
            }
        }
        super.tearDown()
    }

    // MARK: - Set and Get

    func testSetAndGetRoundTrip() throws {
        try service.set(service: testService, account: "testuser", value: "s3cret", label: "Test Label")

        let detail = try service.get(service: testService, account: "testuser")
        XCTAssertEqual(detail.value, "s3cret")
        XCTAssertEqual(detail.item.service, testService)
        XCTAssertEqual(detail.item.account, "testuser")
        XCTAssertEqual(detail.item.itemClass, "genericPassword")
    }

    func testSetOverwritesExistingValue() throws {
        try service.set(service: testService, account: "testuser", value: "first", label: nil)
        try service.set(service: testService, account: "testuser", value: "second", label: nil)

        let detail = try service.get(service: testService, account: "testuser")
        XCTAssertEqual(detail.value, "second")
    }

    // MARK: - Delete

    func testDeleteExistingItem() throws {
        try service.set(service: testService, account: "testuser", value: "todelete", label: nil)
        try service.delete(service: testService, account: "testuser")

        XCTAssertThrowsError(
            try service.get(service: testService, account: "testuser")
        ) { error in
            guard case KeychainError.itemNotFound = error else {
                XCTFail("Expected itemNotFound, got \(error)")
                return
            }
        }
    }

    func testDeleteNonexistentThrowsItemNotFound() throws {
        XCTAssertThrowsError(
            try service.delete(service: testService, account: "nonexistent")
        ) { error in
            guard case KeychainError.itemNotFound = error else {
                XCTFail("Expected itemNotFound, got \(error)")
                return
            }
        }
    }

    // MARK: - List

    func testListWithFilter() throws {
        try service.set(service: testService, account: "testuser1", value: "val1", label: nil)
        try service.set(service: testService, account: "testuser2", value: "val2", label: nil)

        let items = try service.list(service: testService)
        XCTAssertEqual(items.count, 2)

        let accounts = Set(items.map { $0.account })
        XCTAssertTrue(accounts.contains("testuser1"))
        XCTAssertTrue(accounts.contains("testuser2"))
    }

    func testListWithNoMatchReturnsEmpty() throws {
        let items = try service.list(service: "com.brndnsvr.sysm.nonexistent.\(UUID().uuidString)")
        XCTAssertTrue(items.isEmpty)
    }

    // MARK: - Search

    func testSearchByPartialMatch() throws {
        try service.set(service: testService, account: "searchme", value: "findthis", label: nil)

        let items = try service.search(query: "searchme")
        XCTAssertFalse(items.isEmpty)
        XCTAssertTrue(items.contains { $0.account == "searchme" && $0.service == testService })
    }

    func testSearchByServiceName() throws {
        try service.set(service: testService, account: "another-account", value: "val", label: nil)

        // Search using part of the unique test service name
        let items = try service.search(query: testService)
        XCTAssertFalse(items.isEmpty)
        XCTAssertTrue(items.contains { $0.service == testService })
    }

    // MARK: - Get Nonexistent

    func testGetNonexistentThrowsItemNotFound() throws {
        XCTAssertThrowsError(
            try service.get(service: testService, account: "doesnotexist")
        ) { error in
            guard case KeychainError.itemNotFound = error else {
                XCTFail("Expected itemNotFound, got \(error)")
                return
            }
        }
    }

    // MARK: - Error Descriptions

    func testErrorDescriptions() {
        let errors: [(KeychainError, String)] = [
            (.itemNotFound, "Keychain item not found"),
            (.duplicateItem, "Keychain item already exists"),
            (.accessDenied, "Access to keychain denied"),
            (.operationFailed(-25300), "Keychain operation failed (OSStatus -25300)"),
        ]

        for (error, expected) in errors {
            XCTAssertEqual(error.errorDescription, expected)
        }
    }
}
