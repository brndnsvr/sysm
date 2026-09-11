import XCTest
@testable import SysmCore

final class FocusServiceTests: XCTestCase {
    var mock: MockAppleScriptRunner!
    var service: FocusService!

    override func setUp() {
        super.setUp()
        mock = MockAppleScriptRunner()
        ServiceContainer.shared.appleScriptRunnerFactory = { [mock] in mock! }
        ServiceContainer.shared.clearCache()
        service = FocusService()
    }

    override func tearDown() {
        super.tearDown()
        ServiceContainer.shared.reset()
    }

    // MARK: - activateFocus(_:)

    func testActivateFocusPassesPlainNameThrough() throws {
        try service.activateFocus("Work")

        let script = try XCTUnwrap(mock.executedScripts.first?.script)
        XCTAssertTrue(script.contains(#"run shortcut "Turn On Work""#))
    }

    func testActivateFocusEscapesConcatenationPayload() throws {
        let payload = #"" & (do shell script "touch /tmp/pwned") & ""#

        try service.activateFocus(payload)

        let script = try XCTUnwrap(mock.executedScripts.first?.script)
        XCTAssertTrue(
            script.contains(#"run shortcut "Turn On \" & (do shell script \"touch /tmp/pwned\") & \"""#),
            "mode name must stay inside one string literal"
        )
        XCTAssertFalse(script.contains(#"run shortcut "Turn On " & (do shell script"#))
    }

    func testActivateFocusFallbackShortcutIsAlsoEscaped() {
        mock.errorToThrow = AppleScriptError.executionFailed("shortcut not found")

        XCTAssertThrowsError(try service.activateFocus(#"Work" & "x"#)) { error in
            guard case FocusError.toggleFailed = error else {
                return XCTFail("expected toggleFailed, got \(error)")
            }
        }

        XCTAssertEqual(mock.executedScripts.count, 2)
        XCTAssertTrue(mock.executedScripts[1].script.contains(#"run shortcut "Enable Work\" & \"x""#))
    }
}
