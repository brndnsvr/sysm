import XCTest
@testable import SysmCore

final class RecurrenceRuleTests: XCTestCase {

    // MARK: - description

    func testDescriptionDaily() {
        let rule = RecurrenceRule(frequency: .daily)
        XCTAssertEqual(rule.description, "Every day")
    }

    func testDescriptionWeekly() {
        let rule = RecurrenceRule(frequency: .weekly)
        XCTAssertEqual(rule.description, "Every week")
    }

    func testDescriptionMonthlyWithInterval() {
        let rule = RecurrenceRule(frequency: .monthly, interval: 3)
        XCTAssertEqual(rule.description, "Every 3 months")
    }

    func testDescriptionYearly() {
        let rule = RecurrenceRule(frequency: .yearly)
        XCTAssertEqual(rule.description, "Every year")
    }

    func testDescriptionWithDaysOfWeek() {
        // Day 2 = Monday, Day 4 = Wednesday (EKWeekday uses 1=Sunday)
        let rule = RecurrenceRule(frequency: .weekly, daysOfWeek: [2, 4])
        let desc = rule.description
        XCTAssertTrue(desc.contains("on"))
        XCTAssertTrue(desc.contains("Monday"))
        XCTAssertTrue(desc.contains("Wednesday"))
    }

    func testDescriptionWithEndDate() {
        let endDate = Date(timeIntervalSince1970: 1735689600) // Jan 1, 2025
        let rule = RecurrenceRule(frequency: .daily, endDate: endDate)
        let desc = rule.description
        XCTAssertTrue(desc.contains("until"))
    }

    func testDescriptionWithOccurrenceCount() {
        let rule = RecurrenceRule(frequency: .weekly, occurrenceCount: 10)
        XCTAssertTrue(rule.description.contains("10 times"))
    }

    func testDescriptionDailyWithInterval() {
        let rule = RecurrenceRule(frequency: .daily, interval: 2)
        XCTAssertEqual(rule.description, "Every 2 days")
    }

    func testDescriptionWeeklyWithInterval() {
        let rule = RecurrenceRule(frequency: .weekly, interval: 2)
        XCTAssertEqual(rule.description, "Every 2 weeks")
    }

    // MARK: - ordinalSuffix (tested via description with daysOfTheMonth)

    func testOrdinalSuffixes() {
        let rule1 = RecurrenceRule(frequency: .monthly, daysOfTheMonth: [1])
        XCTAssertTrue(rule1.description.contains("1st"))

        let rule2 = RecurrenceRule(frequency: .monthly, daysOfTheMonth: [2])
        XCTAssertTrue(rule2.description.contains("2nd"))

        let rule3 = RecurrenceRule(frequency: .monthly, daysOfTheMonth: [3])
        XCTAssertTrue(rule3.description.contains("3rd"))

        let rule4 = RecurrenceRule(frequency: .monthly, daysOfTheMonth: [4])
        XCTAssertTrue(rule4.description.contains("4th"))

        let rule11 = RecurrenceRule(frequency: .monthly, daysOfTheMonth: [11])
        XCTAssertTrue(rule11.description.contains("11th"))

        let rule12 = RecurrenceRule(frequency: .monthly, daysOfTheMonth: [12])
        XCTAssertTrue(rule12.description.contains("12th"))

        let rule13 = RecurrenceRule(frequency: .monthly, daysOfTheMonth: [13])
        XCTAssertTrue(rule13.description.contains("13th"))

        let rule21 = RecurrenceRule(frequency: .monthly, daysOfTheMonth: [21])
        XCTAssertTrue(rule21.description.contains("21st"))
    }

    // MARK: - RecurrenceFrequency Codable

    func testRecurrenceFrequencyCodableRoundTrip() throws {
        for freq in RecurrenceFrequency.allCases {
            let data = try JSONEncoder().encode(freq)
            let decoded = try JSONDecoder().decode(RecurrenceFrequency.self, from: data)
            XCTAssertEqual(freq, decoded)
        }
    }

    // MARK: - RecurrenceRule Codable

    func testRecurrenceRuleCodableRoundTrip() throws {
        let original = RecurrenceRule(
            frequency: .weekly,
            interval: 2,
            daysOfWeek: [2, 4, 6],
            occurrenceCount: 52
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(RecurrenceRule.self, from: data)
        XCTAssertEqual(decoded.frequency, .weekly)
        XCTAssertEqual(decoded.interval, 2)
        XCTAssertEqual(decoded.daysOfWeek, [2, 4, 6])
        XCTAssertEqual(decoded.occurrenceCount, 52)
    }

    // MARK: - Description with months and setPositions

    func testDescriptionWithMonths() {
        let rule = RecurrenceRule(frequency: .yearly, monthsOfTheYear: [1, 6])
        let desc = rule.description
        XCTAssertTrue(desc.contains("in"))
        XCTAssertTrue(desc.contains("January"))
        XCTAssertTrue(desc.contains("June"))
    }

    func testDescriptionWithSetPositions() {
        let rule = RecurrenceRule(frequency: .monthly, daysOfWeek: [2], setPositions: [1, -1])
        let desc = rule.description
        XCTAssertTrue(desc.contains("first"))
        XCTAssertTrue(desc.contains("last"))
    }
}
