import XCTest

final class TccServicesIntegrationTests: IntegrationTestCase {

    // MARK: - Helpers

    /// Run a command or skip gracefully when TCC access is denied or the app is unavailable.
    private func runOrSkip(_ args: [String], timeout: TimeInterval = 60, reason: String) throws -> String {
        do {
            return try runCommand(args, timeout: timeout)
        } catch IntegrationTestError.commandFailed(_, _, let stderr) {
            if stderr.localizedCaseInsensitiveContains("access") ||
               stderr.localizedCaseInsensitiveContains("not granted") ||
               stderr.localizedCaseInsensitiveContains("permission") ||
               stderr.localizedCaseInsensitiveContains("not running") ||
               stderr.localizedCaseInsensitiveContains("not open") ||
               stderr.localizedCaseInsensitiveContains("denied") ||
               stderr.localizedCaseInsensitiveContains("authorization") ||
               stderr.localizedCaseInsensitiveContains("not available") {
                throw XCTSkip(reason)
            }
            throw IntegrationTestError.commandFailed(
                command: args.joined(separator: " "), exitCode: 1, stderr: stderr
            )
        } catch IntegrationTestError.timeout {
            throw XCTSkip("\(reason) (timed out)")
        }
    }

    // MARK: - Calendar

    func testCalendarCalendars() throws {
        let output = try runOrSkip(
            ["calendar", "calendars", "--json"],
            reason: "Calendar access not granted"
        )
        let data = try XCTUnwrap(output.data(using: .utf8))
        let arr = try JSONSerialization.jsonObject(with: data)

        XCTAssertTrue(arr is [Any], "Expected JSON array of calendars")
    }

    func testCalendarToday() throws {
        let output = try runOrSkip(
            ["calendar", "today", "--json"],
            reason: "Calendar access not granted"
        )
        let data = try XCTUnwrap(output.data(using: .utf8))
        let arr = try JSONSerialization.jsonObject(with: data)

        XCTAssertTrue(arr is [Any], "Expected JSON array of events")
    }

    func testCalendarSearch() throws {
        let output = try runOrSkip(
            ["calendar", "search", "meeting", "--json"],
            timeout: 60,
            reason: "Calendar access not granted"
        )
        let data = try XCTUnwrap(output.data(using: .utf8))
        let arr = try JSONSerialization.jsonObject(with: data)

        XCTAssertTrue(arr is [Any], "Expected JSON array of events")
    }

    // MARK: - Reminders

    func testRemindersLists() throws {
        let output = try runOrSkip(
            ["reminders", "lists", "--json"],
            reason: "Reminders access not granted"
        )
        let data = try XCTUnwrap(output.data(using: .utf8))
        let arr = try JSONSerialization.jsonObject(with: data)

        XCTAssertTrue(arr is [Any], "Expected JSON array of reminder lists")
    }

    func testRemindersList() throws {
        // List reminders from default list
        let output = try runOrSkip(
            ["reminders", "list", "--json"],
            timeout: 60,
            reason: "Reminders access not granted"
        )
        let data = try XCTUnwrap(output.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data)
    }

    func testRemindersToday() throws {
        let output = try runOrSkip(
            ["reminders", "today", "--json"],
            reason: "Reminders access not granted"
        )
        let data = try XCTUnwrap(output.data(using: .utf8))
        let arr = try JSONSerialization.jsonObject(with: data)

        XCTAssertTrue(arr is [Any], "Expected JSON array of reminders")
    }

    // MARK: - Contacts

    func testContactsSearch() throws {
        let output = try runOrSkip(
            ["contacts", "search", "test", "--json"],
            reason: "Contacts access not granted"
        )
        let data = try XCTUnwrap(output.data(using: .utf8))
        let arr = try JSONSerialization.jsonObject(with: data)

        XCTAssertTrue(arr is [Any], "Expected JSON array of contacts")
    }

    // MARK: - Photos

    func testPhotosAlbums() throws {
        let output = try runOrSkip(
            ["photos", "albums", "--json"],
            reason: "Photos access not granted"
        )
        let data = try XCTUnwrap(output.data(using: .utf8))
        let arr = try JSONSerialization.jsonObject(with: data)

        XCTAssertTrue(arr is [Any], "Expected JSON array of albums")
    }

    func testPhotosRecent() throws {
        let output = try runOrSkip(
            ["photos", "recent", "--json"],
            reason: "Photos access not granted"
        )
        let data = try XCTUnwrap(output.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data)
    }

    // MARK: - Mail

    func testMailUnread() throws {
        let output = try runOrSkip(
            ["mail", "unread", "--json"],
            reason: "Mail not running or access not granted"
        )
        let data = try XCTUnwrap(output.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data)
    }

    func testMailAccounts() throws {
        let output = try runOrSkip(
            ["mail", "accounts", "--json"],
            reason: "Mail not running or access not granted"
        )
        let data = try XCTUnwrap(output.data(using: .utf8))
        let arr = try JSONSerialization.jsonObject(with: data)

        XCTAssertTrue(arr is [Any], "Expected JSON array of mail accounts")
    }

    // MARK: - Notes

    func testNotesCheck() throws {
        let output = try runOrSkip(
            ["notes", "check", "--json"],
            reason: "Notes not running or access not granted"
        )
        let data = try XCTUnwrap(output.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data)
    }

    func testNotesList() throws {
        let output = try runOrSkip(
            ["notes", "list", "--json"],
            reason: "Notes not running or access not granted"
        )
        let data = try XCTUnwrap(output.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data)
    }

    func testNotesFolders() throws {
        let output = try runOrSkip(
            ["notes", "folders", "--json"],
            reason: "Notes not running or access not granted"
        )
        let data = try XCTUnwrap(output.data(using: .utf8))
        let arr = try JSONSerialization.jsonObject(with: data)

        XCTAssertTrue(arr is [Any], "Expected JSON array of folders")
    }

    // MARK: - Safari

    func testSafariTabs() throws {
        let output = try runOrSkip(
            ["safari", "tabs", "--json"],
            reason: "Safari not running or access not granted"
        )
        let data = try XCTUnwrap(output.data(using: .utf8))
        let arr = try JSONSerialization.jsonObject(with: data)

        XCTAssertTrue(arr is [Any], "Expected JSON array of tabs")
    }

    func testSafariBookmarks() throws {
        let output = try runOrSkip(
            ["safari", "bookmarks", "--json"],
            timeout: 60,
            reason: "Safari not running or access not granted"
        )
        let data = try XCTUnwrap(output.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data)
    }

    // MARK: - Messages

    func testMessagesRecent() throws {
        let output = try runOrSkip(
            ["messages", "recent", "--json"],
            reason: "Messages not running or access not granted"
        )
        let data = try XCTUnwrap(output.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data)
    }
}
