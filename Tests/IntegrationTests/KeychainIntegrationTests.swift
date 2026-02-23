import XCTest

final class KeychainIntegrationTests: IntegrationTestCase {

    private var testServiceName: String!
    private let testAccount = "integration-test-account"
    private let testValue = "integration-test-value-42"

    override func setUp() {
        super.setUp()
        testServiceName = "sysm-integration-test-\(UUID().uuidString)"
    }

    override func tearDown() {
        // Clean up any test keychain items
        try? runCommand(["keychain", "delete", testServiceName, testAccount])
        super.tearDown()
    }

    // MARK: - Help

    func testKeychainHelp() throws {
        let output = try runCommand(["keychain", "--help"])

        XCTAssertTrue(output.contains("set"))
        XCTAssertTrue(output.contains("get"))
        XCTAssertTrue(output.contains("delete"))
        XCTAssertTrue(output.contains("list"))
        XCTAssertTrue(output.contains("search"))
    }

    // MARK: - Set and Get

    func testKeychainSetAndGet() throws {
        // Set a test value
        _ = try runCommand([
            "keychain", "set",
            testServiceName, testAccount,
            "--value", testValue,
        ])

        // Get it back
        let output = try runCommand(["keychain", "get", testServiceName, testAccount])
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(trimmed, testValue, "Retrieved value should match what was set")
    }

    // MARK: - List

    func testKeychainList() throws {
        // Set a test value
        _ = try runCommand([
            "keychain", "set",
            testServiceName, testAccount,
            "--value", testValue,
        ])

        // List with service filter
        let output = try runCommand(["keychain", "list", "--service", testServiceName, "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data)

        XCTAssertTrue(output.contains(testServiceName), "List should include the test service")
    }

    // MARK: - Search

    func testKeychainSearch() throws {
        // Set a test value
        _ = try runCommand([
            "keychain", "set",
            testServiceName, testAccount,
            "--value", testValue,
        ])

        // Search for it
        let output = try runCommand(["keychain", "search", testServiceName, "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data)

        XCTAssertTrue(output.contains(testServiceName), "Search should find the test item")
    }

    // MARK: - Delete

    func testKeychainDelete() throws {
        // Set a test value
        _ = try runCommand([
            "keychain", "set",
            testServiceName, testAccount,
            "--value", testValue,
        ])

        // Delete it
        _ = try runCommand(["keychain", "delete", testServiceName, testAccount])

        // Verify get fails
        try runCommandExpectingFailure(["keychain", "get", testServiceName, testAccount])
    }

    // MARK: - Error Handling

    func testKeychainGetNonexistent() throws {
        try runCommandExpectingFailure([
            "keychain", "get",
            "sysm-nonexistent-\(UUID().uuidString)",
            "nonexistent-account",
        ])
    }
}
