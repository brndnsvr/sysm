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

    // MARK: - Focus database

    func testModeNamesComeFromModeConfigurations() throws {
        // Shaped like ~/Library/DoNotDisturb/DB/ModeConfigurations.json on macOS 27.
        let json = """
        {"header": {}, "data": [{"modeConfigurations": {
            "com.apple.sleep.sleep-mode": {"mode": {"name": "Sleep", "modeIdentifier": "com.apple.sleep.sleep-mode"}},
            "com.apple.donotdisturb.mode.driving": {"mode": {"name": "Driving", "modeIdentifier": "com.apple.donotdisturb.mode.driving"}},
            "com.apple.focus.reduce-interruptions": {"mode": {"name": "Reduce Interruptions", "modeIdentifier": "com.apple.focus.reduce-interruptions"}}
        }}]}
        """
        let names = try FocusService.modeNamesByIdentifier(fromModeConfigurations: Data(json.utf8))

        XCTAssertEqual(names.count, 3)
        XCTAssertEqual(names["com.apple.sleep.sleep-mode"], "Sleep")
        XCTAssertEqual(names["com.apple.donotdisturb.mode.driving"], "Driving")
        XCTAssertEqual(names["com.apple.focus.reduce-interruptions"], "Reduce Interruptions")
    }

    func testModeConfigurationsWithoutDataAreAnError() {
        XCTAssertThrowsError(try FocusService.modeNamesByIdentifier(fromModeConfigurations: Data(#"{"header": {}}"#.utf8)))
    }

    func testActiveFocusComesFromAssertionRecords() {
        let active = """
        {"data": [{"storeAssertionRecords": [{"assertionDetails": {"assertionDetailsModeIdentifier": "com.apple.focus.work"}}]}]}
        """
        XCTAssertEqual(FocusService.activeFocusIdentifier(fromAssertions: Data(active.utf8)), "com.apple.focus.work")

        // With no focus on, the file holds only invalidation records.
        let idle = #"{"data": [{"storeInvalidationRecords": [], "storeInvalidationRequestRecords": []}]}"#
        XCTAssertNil(FocusService.activeFocusIdentifier(fromAssertions: Data(idle.utf8)))
    }

    // MARK: - Do Not Disturb

    func testEnableDNDRunsTheShortcutOnly() throws {
        try service.enableDND()

        XCTAssertEqual(mock.executedScripts.count, 1)
        XCTAssertTrue(mock.executedScripts[0].script.contains(#"run shortcut "Turn On Do Not Disturb""#))
    }

    func testMissingDNDShortcutFailsWithoutGUIScripting() {
        mock.errorToThrow = AppleScriptError.executionFailed("shortcut not found")

        XCTAssertThrowsError(try service.disableDND()) { error in
            guard case FocusError.toggleFailed(let message) = error else {
                return XCTFail("expected toggleFailed, got \(error)")
            }
            XCTAssertTrue(message.contains("Turn Off Do Not Disturb"), message)
        }
        // The removed fallback scripted Control Center through System Events.
        XCTAssertFalse(mock.executedScripts.contains { $0.script.contains("System Events") })
    }
}
