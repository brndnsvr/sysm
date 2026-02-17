import XCTest
@testable import SysmCore

final class ServiceContainerTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        ServiceContainer.shared.reset()
    }

    // MARK: - Factory Injection

    func testCustomFactoryReturnsInjectedService() {
        let container = ServiceContainer.shared

        // Use a mock notes factory
        var factoryCalled = false
        container.notesFactory = {
            factoryCalled = true
            return NotesService()
        }
        container.clearCache()

        _ = container.notes()
        XCTAssertTrue(factoryCalled)
    }

    // MARK: - Caching

    func testServiceIsCached() {
        let container = ServiceContainer.shared
        var callCount = 0
        container.notesFactory = {
            callCount += 1
            return NotesService()
        }
        container.clearCache()

        _ = container.notes()
        _ = container.notes()
        XCTAssertEqual(callCount, 1, "Factory should only be called once due to caching")
    }

    // MARK: - reset()

    func testResetRestoresDefaults() {
        let container = ServiceContainer.shared
        var customCalled = false
        container.notesFactory = {
            customCalled = true
            return NotesService()
        }
        container.clearCache()
        _ = container.notes()
        XCTAssertTrue(customCalled)

        container.reset()
        customCalled = false
        _ = container.notes()
        // After reset, the default factory is used, not our custom one
        XCTAssertFalse(customCalled)
    }

    // MARK: - clearCache()

    func testClearCacheKeepsFactories() {
        let container = ServiceContainer.shared
        var callCount = 0
        container.notesFactory = {
            callCount += 1
            return NotesService()
        }
        container.clearCache()

        _ = container.notes()
        XCTAssertEqual(callCount, 1)

        container.clearCache()
        _ = container.notes()
        XCTAssertEqual(callCount, 2, "After clearCache, factory should be called again")
    }

    func testClearCacheThenNewFactory() {
        let container = ServiceContainer.shared
        var firstCalled = false
        var secondCalled = false

        container.notesFactory = {
            firstCalled = true
            return NotesService()
        }
        container.clearCache()
        _ = container.notes()
        XCTAssertTrue(firstCalled)

        container.notesFactory = {
            secondCalled = true
            return NotesService()
        }
        container.clearCache()
        _ = container.notes()
        XCTAssertTrue(secondCalled)
    }

    // MARK: - Thread Safety

    func testConcurrentAccessDoesNotCrash() {
        let container = ServiceContainer.shared
        container.reset()

        let expectation = expectation(description: "concurrent access")
        expectation.expectedFulfillmentCount = 100

        for _ in 0..<100 {
            DispatchQueue.global().async {
                _ = container.notes()
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10.0)
    }

    // MARK: - Multiple Service Types

    func testDifferentServicesAreSeparatelyCached() {
        let container = ServiceContainer.shared
        var notesCount = 0
        var mailCount = 0

        container.notesFactory = {
            notesCount += 1
            return NotesService()
        }
        container.mailFactory = {
            mailCount += 1
            return MailService()
        }
        container.clearCache()

        _ = container.notes()
        _ = container.mail()
        _ = container.notes()
        _ = container.mail()

        XCTAssertEqual(notesCount, 1)
        XCTAssertEqual(mailCount, 1)
    }

    // MARK: - Accessor Coverage

    func testVariousAccessors() {
        let container = ServiceContainer.shared
        // Just verify these don't crash
        _ = container.music()
        _ = container.safari()
        _ = container.workflow()
        _ = container.scriptRunner()
        _ = container.appleScriptRunner()
        _ = container.dateParser()
        _ = container.system()
    }
}
