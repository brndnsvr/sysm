import EventKit
import XCTest
@testable import SysmCore

final class ReminderServiceTests: XCTestCase {

    private let parser = DateParser()

    private func components(_ input: String) throws -> DateComponents {
        try ReminderService.dateComponents(for: input, parser: parser)
    }

    // MARK: - dateComponents(for:parser:)

    func testDateOnlyInputIsAllDay() throws {
        // Components without an hour and minute make EventKit treat the reminder as all-day.
        for input in ["2026-01-15", "tomorrow", "friday", "today"] {
            let result = try components(input)
            XCTAssertNotNil(result.day, input)
            XCTAssertNil(result.hour, input)
            XCTAssertNil(result.minute, input)
        }
    }

    func testInputWithATimeKeepsIt() throws {
        let result = try components("2026-01-15 14:30")

        XCTAssertEqual(result.year, 2026)
        XCTAssertEqual(result.month, 1)
        XCTAssertEqual(result.day, 15)
        XCTAssertEqual(result.hour, 14)
        XCTAssertEqual(result.minute, 30)
    }

    func testRelativeDayWithATimeKeepsIt() throws {
        let result = try components("tomorrow 9am")

        XCTAssertEqual(result.hour, 9)
        XCTAssertEqual(result.minute, 0)
    }

    func testUnparseableInputThrows() {
        XCTAssertThrowsError(try components("someday")) { error in
            guard let reminderError = error as? ReminderError,
                  case .invalidDateFormat(let input) = reminderError else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(input, "someday")
        }
    }

    func testYearsOutsideTheSupportedRangeThrow() {
        XCTAssertThrowsError(try components("1999-12-31")) { error in
            guard let reminderError = error as? ReminderError,
                  case .invalidYear(let year) = reminderError else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(year, 1999)
        }
    }

    // MARK: - ambiguousReminder

    func testAmbiguousReminderErrorListsTheCandidates() {
        let error = ReminderError.ambiguousReminder("Pay rent", ["id-1  (Home)", "id-2  (Work)"])
        let message = error.errorDescription ?? ""

        XCTAssertTrue(message.contains("2 incomplete reminders are titled 'Pay rent'"), message)
        XCTAssertTrue(message.contains("id-1  (Home)") && message.contains("id-2  (Work)"), message)
        XCTAssertTrue(message.contains("--id"), message)
    }

    // MARK: - preferredReminderSource

    private struct Account {
        let title: String
        let type: EKSourceType
        let holdsLists: Bool
    }

    private func source(_ accounts: [Account], default defaultAccount: Account? = nil) -> Account? {
        ReminderService.preferredReminderSource(accounts, default: defaultAccount,
                                                holdsLists: \.holdsLists, title: \.title, type: \.type)
    }

    func testTheAccountHoldingListsBeatsAnEmptyNamesake() {
        // This Mac carries two CalDAV accounts titled iCloud: one holds the
        // calendars, the other the reminder lists. Saving a list to the first
        // fails with "That account does not support reminders".
        let calendars = Account(title: "iCloud", type: .calDAV, holdsLists: false)
        let lists = Account(title: "iCloud", type: .calDAV, holdsLists: true)

        XCTAssertEqual(source([calendars, lists])?.holdsLists, true)
    }

    func testTheStoresOwnDefaultWins() {
        let exchange = Account(title: "Exchange", type: .exchange, holdsLists: true)
        let icloud = Account(title: "iCloud", type: .calDAV, holdsLists: true)

        XCTAssertEqual(source([icloud, exchange], default: exchange)?.title, "Exchange")
    }

    func testWithNoListsAnywhereItFallsBackToICloudThenCalDAVThenLocal() {
        let local = Account(title: "On My Mac", type: .local, holdsLists: false)
        let exchange = Account(title: "Exchange", type: .exchange, holdsLists: false)
        let icloud = Account(title: "iCloud", type: .calDAV, holdsLists: false)
        let fastmail = Account(title: "Fastmail", type: .calDAV, holdsLists: false)

        XCTAssertEqual(source([local, exchange, fastmail, icloud])?.title, "iCloud")
        XCTAssertEqual(source([local, exchange, fastmail])?.title, "Fastmail")
        XCTAssertEqual(source([local, exchange])?.title, "On My Mac")
    }

    func testNoAccountsGiveNil() {
        XCTAssertNil(source([]))
    }
}
