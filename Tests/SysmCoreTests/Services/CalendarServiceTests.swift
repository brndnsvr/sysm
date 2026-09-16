import EventKit
import XCTest
@testable import SysmCore

final class CalendarServiceTests: XCTestCase {

    private struct Occurrence: Equatable {
        let start: Date
        let end: Date
    }

    private let now = Date(timeIntervalSinceReferenceDate: 800_000_000)

    private func occurrence(startingIn hours: Double, lasting duration: Double = 1) -> Occurrence {
        let start = now.addingTimeInterval(hours * 3600)
        return Occurrence(start: start, end: start.addingTimeInterval(duration * 3600))
    }

    private func preferred(_ occurrences: [Occurrence]) -> Occurrence? {
        CalendarService.preferredOccurrence(of: occurrences, now: now, start: \.start, end: \.end)
    }

    // MARK: - preferredOccurrence

    func testPicksTheNextOccurrenceWhateverTheInputOrder() {
        let past = occurrence(startingIn: -48)
        let next = occurrence(startingIn: 20)
        let later = occurrence(startingIn: 44)

        XCTAssertEqual(preferred([later, past, next]), next)
        XCTAssertEqual(preferred([next, later, past]), next)
    }

    func testAnOccurrenceInProgressCountsAsNext() {
        let current = occurrence(startingIn: -0.5)

        XCTAssertEqual(preferred([occurrence(startingIn: 24), current]), current)
    }

    func testFallsBackToTheLatestPastOccurrence() {
        let older = occurrence(startingIn: -72)
        let newer = occurrence(startingIn: -24)

        XCTAssertEqual(preferred([newer, older]), newer)
    }

    func testNoOccurrencesGiveNil() {
        XCTAssertNil(preferred([]))
    }

    // MARK: - validationWindows

    private func year(_ date: Date) -> Int {
        CalendarService.gregorian.component(.year, from: date)
    }

    func testValidationWindowsStayUnderEventKitsFourYearLimit() {
        for window in CalendarService.validationWindows() {
            let years = CalendarService.gregorian.dateComponents([.year], from: window.start, to: window.end).year!
            XCTAssertLessThanOrEqual(years, 3, "\(window)")
        }
    }

    func testValidationWindowsCoverOnlyOutOfRangeYears() {
        let windows = CalendarService.validationWindows()
        let valid = CalendarService.validYearRange

        XCTAssertEqual(year(windows.first!.start), 1)
        XCTAssertEqual(year(windows.last!.end), valid.upperBound + 101)
        for window in windows {
            XCTAssertFalse(valid.contains(year(window.start)), "\(window)")
            XCTAssertFalse(valid.contains(year(window.end.addingTimeInterval(-1))), "\(window)")
        }
    }

    func testValidationWindowsLeaveNoGapBesideTheValidSpan() {
        let windows = CalendarService.validationWindows()
        let gaps = zip(windows, windows.dropFirst()).filter { $0.end != $1.start }

        XCTAssertEqual(gaps.count, 1)
        XCTAssertEqual(gaps.first.map { year($0.0.end) }, CalendarService.validYearRange.lowerBound)
        XCTAssertEqual(gaps.first.map { year($0.1.start) }, CalendarService.validYearRange.upperBound + 1)
    }

    // MARK: - ICS import duplicates

    func testImportRecognizesAnEventAlreadyInTheCalendar() {
        let start = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let event = ICSEventData(title: "Standup", startDate: start, endDate: start.addingTimeInterval(900),
                                 isAllDay: false, location: nil, notes: nil, uid: "abc", organizer: nil, attendees: [])

        XCTAssertTrue(CalendarService.matchesExisting(event, [(title: "Standup", start: start, end: start.addingTimeInterval(900))]))
        XCTAssertFalse(CalendarService.matchesExisting(event, [(title: "Standup", start: start, end: start.addingTimeInterval(1800))]))
        XCTAssertFalse(CalendarService.matchesExisting(event, [(title: "Retro", start: start, end: start.addingTimeInterval(900))]))
    }

    // MARK: - validate

    private func midYear(_ year: Int) -> Date {
        CalendarService.gregorian.date(from: DateComponents(year: year, month: 6, day: 15))!
    }

    private func series(from year: Int, rule: EKRecurrenceRule?) -> EKEvent {
        let event = EKEvent(eventStore: EKEventStore())
        event.startDate = midYear(year)
        event.endDate = event.startDate.addingTimeInterval(3600)
        if let rule { event.addRecurrenceRule(rule) }
        return event
    }

    func testADateInsideTheRangeIsValid() {
        XCTAssertFalse(CalendarService.isOutsideValidRange(start: midYear(2026), end: midYear(2026)))
    }

    func testALoneDateOutsideTheRangeIsInvalid() {
        XCTAssertTrue(CalendarService.isOutsideValidRange(start: midYear(1604), end: midYear(1604)))
        XCTAssertTrue(CalendarService.isOutsideValidRange(start: midYear(2150), end: midYear(2150)))
    }

    func testASeriesBegunBeforeTheRangeThatStillRunsIsValid() {
        XCTAssertFalse(CalendarService.isOutsideValidRange(start: midYear(1979), end: nil))
        XCTAssertFalse(CalendarService.isOutsideValidRange(start: midYear(1604), end: midYear(2026)))
    }

    func testASeriesThatRanOutBeforeTheRangeIsInvalid() {
        XCTAssertTrue(CalendarService.isOutsideValidRange(start: midYear(1979), end: midYear(1984)))
    }

    func testAContactBirthdayIsNotReported() {
        // Google and Exchange deliver contact birthdays into ordinary
        // calendars as endless yearly series begun at the year of birth, or at
        // 1604 when no year was recorded.
        let birthday = series(from: 1979, rule: EKRecurrenceRule(recurrenceWith: .yearly, interval: 1, end: nil))
        let noYearRecorded = series(from: 1604, rule: EKRecurrenceRule(recurrenceWith: .yearly, interval: 1, end: nil))

        XCTAssertNil(CalendarService.seriesEnd(of: birthday))
        XCTAssertFalse(CalendarService.isOutsideValidRange(birthday))
        XCTAssertFalse(CalendarService.isOutsideValidRange(noYearRecorded))
    }

    func testACountLimitedSeriesEndsWhereItRunsOut() {
        let event = series(from: 1979, rule: EKRecurrenceRule(recurrenceWith: .yearly, interval: 1,
                                                              end: EKRecurrenceEnd(occurrenceCount: 5)))
        let endYear = CalendarService.seriesEnd(of: event).map { CalendarService.gregorian.component(.year, from: $0) }

        XCTAssertEqual(endYear, 1983)
        XCTAssertTrue(CalendarService.isOutsideValidRange(event))
    }

    func testAnEventWithNoRuleEndsWhereItStarts() {
        let event = series(from: 1604, rule: nil)

        XCTAssertEqual(CalendarService.seriesEnd(of: event), event.startDate)
        XCTAssertTrue(CalendarService.isOutsideValidRange(event))
    }
}
