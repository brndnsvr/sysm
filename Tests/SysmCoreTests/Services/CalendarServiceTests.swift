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
}
