import XCTest
@testable import SysmCore

final class CalendarServiceTests: XCTestCase {

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
