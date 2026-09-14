import EventKit
import XCTest
@testable import SysmCore

final class ICSRecurrenceTests: XCTestCase {

    private let allDay = ICSAllDayDates(timeZone: TimeZone(identifier: "UTC")!)

    private func rrule(_ rule: EKRecurrenceRule, isAllDay: Bool = false) -> String {
        ICSGenerator.rrule(for: rule, isAllDay: isAllDay, allDay: allDay)
    }

    func testWeeklyRuleWithDaysIntervalAndCount() {
        let rule = EKRecurrenceRule(
            recurrenceWith: .weekly, interval: 2,
            daysOfTheWeek: [EKRecurrenceDayOfWeek(.monday), EKRecurrenceDayOfWeek(.wednesday)],
            daysOfTheMonth: nil, monthsOfTheYear: nil, weeksOfTheYear: nil, daysOfTheYear: nil,
            setPositions: nil, end: EKRecurrenceEnd(occurrenceCount: 10)
        )

        // WKST matters for a weekly rule with an interval and BYDAY, so the
        // week start EventKit reports is written.
        let codes = ["SU", "MO", "TU", "WE", "TH", "FR", "SA"]
        let weekStart = (1...7).contains(rule.firstDayOfTheWeek) ? ";WKST=\(codes[rule.firstDayOfTheWeek - 1])" : ""
        XCTAssertEqual(rrule(rule), "FREQ=WEEKLY;INTERVAL=2;BYDAY=MO,WE\(weekStart);COUNT=10")
    }

    func testMonthlyRuleKeepsWeekNumbers() {
        // The last Friday of every month.
        let rule = EKRecurrenceRule(
            recurrenceWith: .monthly, interval: 1,
            daysOfTheWeek: [EKRecurrenceDayOfWeek(.friday, weekNumber: -1)],
            daysOfTheMonth: nil, monthsOfTheYear: nil, weeksOfTheYear: nil, daysOfTheYear: nil,
            setPositions: nil, end: nil
        )

        XCTAssertEqual(rrule(rule), "FREQ=MONTHLY;BYDAY=-1FR")
    }

    func testUntilMatchesTheEventsDateForm() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let end = calendar.date(from: DateComponents(year: 2027, month: 12, day: 31, hour: 23, minute: 59, second: 59))!
        let rule = EKRecurrenceRule(recurrenceWith: .yearly, interval: 1, end: EKRecurrenceEnd(end: end))

        XCTAssertEqual(rrule(rule), "FREQ=YEARLY;UNTIL=20271231T235959Z")
        XCTAssertEqual(rrule(rule, isAllDay: true), "FREQ=YEARLY;UNTIL=20271231")
    }

    func testRepeatingEventIsExportedWithItsRule() {
        let event = EKEvent(eventStore: EKEventStore())
        event.title = "Standup"
        event.startDate = Date(timeIntervalSince1970: 1_768_467_600)
        event.endDate = event.startDate.addingTimeInterval(900)
        event.addRecurrenceRule(EKRecurrenceRule(recurrenceWith: .daily, interval: 1, end: nil))

        let ics = ICSGenerator.generate(events: [event], calendarName: "Work", timeZone: TimeZone(identifier: "UTC")!)

        XCTAssertTrue(ics.contains("\r\nRRULE:FREQ=DAILY\r\n"), ics)
        XCTAssertFalse(ics.contains("RECURRENCE-ID"), ics)
    }
}
