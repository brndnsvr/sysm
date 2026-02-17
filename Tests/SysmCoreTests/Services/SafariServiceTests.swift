import XCTest
@testable import SysmCore

final class SafariServiceTests: XCTestCase {
    var mock: MockAppleScriptRunner!
    var service: SafariService!

    override func setUp() {
        super.setUp()
        mock = MockAppleScriptRunner()
        ServiceContainer.shared.appleScriptRunnerFactory = { [mock] in mock! }
        ServiceContainer.shared.clearCache()
        service = SafariService()
    }

    override func tearDown() {
        super.tearDown()
        ServiceContainer.shared.reset()
    }

    // MARK: - getOpenTabs()

    func testGetOpenTabsParsesOutput() throws {
        mock.defaultResponse = "1|||1|||https://example.com|||Example###1|||2|||https://google.com|||Google###"
        let tabs = try service.getOpenTabs()
        XCTAssertEqual(tabs.count, 2)
        XCTAssertEqual(tabs[0].windowIndex, 1)
        XCTAssertEqual(tabs[0].tabIndex, 1)
        XCTAssertEqual(tabs[0].url, "https://example.com")
        XCTAssertEqual(tabs[0].title, "Example")
        XCTAssertEqual(tabs[1].url, "https://google.com")
    }

    func testGetOpenTabsEmpty() throws {
        mock.defaultResponse = ""
        let tabs = try service.getOpenTabs()
        XCTAssertTrue(tabs.isEmpty)
    }

    func testGetOpenTabsMalformedSkipped() throws {
        mock.defaultResponse = "1|||1|||https://example.com|||Example###bad###"
        let tabs = try service.getOpenTabs()
        XCTAssertEqual(tabs.count, 1)
    }

    func testGetOpenTabsMultipleWindows() throws {
        mock.defaultResponse = "1|||1|||https://a.com|||A###2|||1|||https://b.com|||B###"
        let tabs = try service.getOpenTabs()
        XCTAssertEqual(tabs.count, 2)
        XCTAssertEqual(tabs[0].windowIndex, 1)
        XCTAssertEqual(tabs[1].windowIndex, 2)
    }

    // MARK: - Error mapping

    func testAppleScriptErrorMapping() {
        mock.errorToThrow = AppleScriptError.executionFailed("Safari error")
        XCTAssertThrowsError(try service.getOpenTabs()) { error in
            guard case SafariError.appleScriptError = error else {
                XCTFail("Expected SafariError.appleScriptError, got \(error)")
                return
            }
        }
    }

    // MARK: - SafariError descriptions

    func testSafariErrorDescriptions() {
        XCTAssertNotNil(SafariError.bookmarksNotFound.errorDescription)
        XCTAssertNotNil(SafariError.invalidPlist.errorDescription)
        XCTAssertNotNil(SafariError.appleScriptError("test").errorDescription)
        XCTAssertNotNil(SafariError.safariNotRunning.errorDescription)
    }

    // MARK: - Model Codable round-trips

    func testSafariTabCodable() throws {
        let tab = SafariTab(windowIndex: 1, tabIndex: 2, url: "https://test.com", title: "Test")
        let data = try JSONEncoder().encode(tab)
        let decoded = try JSONDecoder().decode(SafariTab.self, from: data)
        XCTAssertEqual(decoded.windowIndex, 1)
        XCTAssertEqual(decoded.url, "https://test.com")
    }

    func testBookmarkCodable() throws {
        let bookmark = Bookmark(title: "Test", url: "https://test.com", folder: "Favorites")
        let data = try JSONEncoder().encode(bookmark)
        let decoded = try JSONDecoder().decode(Bookmark.self, from: data)
        XCTAssertEqual(decoded.title, "Test")
    }
}
