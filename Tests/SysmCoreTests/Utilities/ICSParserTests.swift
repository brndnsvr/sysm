import XCTest
@testable import SysmCore

final class ICSParserTests: XCTestCase {

    // MARK: - Basic Parsing

    func testParseSimpleEvent() throws {
        let ics = """
        BEGIN:VCALENDAR
        BEGIN:VEVENT
        SUMMARY:Team Meeting
        DTSTART:20260215T140000Z
        DTEND:20260215T150000Z
        END:VEVENT
        END:VCALENDAR
        """
        let parser = ICSParser(content: ics)
        let events = try parser.parse()

        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].title, "Team Meeting")
        XCTAssertFalse(events[0].isAllDay)
    }

    func testParseMultipleEvents() throws {
        let ics = """
        BEGIN:VCALENDAR
        BEGIN:VEVENT
        SUMMARY:Event One
        DTSTART:20260215T100000Z
        DTEND:20260215T110000Z
        END:VEVENT
        BEGIN:VEVENT
        SUMMARY:Event Two
        DTSTART:20260216T090000Z
        DTEND:20260216T100000Z
        END:VEVENT
        END:VCALENDAR
        """
        let parser = ICSParser(content: ics)
        let events = try parser.parse()

        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events[0].title, "Event One")
        XCTAssertEqual(events[1].title, "Event Two")
    }

    func testParseAllDayEvent() throws {
        let ics = """
        BEGIN:VCALENDAR
        BEGIN:VEVENT
        SUMMARY:Holiday
        DTSTART;VALUE=DATE:20260101
        DTEND;VALUE=DATE:20260102
        END:VEVENT
        END:VCALENDAR
        """
        let parser = ICSParser(content: ics)
        let events = try parser.parse()

        XCTAssertEqual(events.count, 1)
        XCTAssertTrue(events[0].isAllDay)
        XCTAssertEqual(events[0].title, "Holiday")
    }

    func testParseEventWithLocationAndDescription() throws {
        let ics = """
        BEGIN:VCALENDAR
        BEGIN:VEVENT
        SUMMARY:Lunch
        DTSTART:20260215T120000Z
        DTEND:20260215T130000Z
        LOCATION:Conference Room A
        DESCRIPTION:Weekly team lunch
        END:VEVENT
        END:VCALENDAR
        """
        let parser = ICSParser(content: ics)
        let events = try parser.parse()

        XCTAssertEqual(events[0].location, "Conference Room A")
        XCTAssertEqual(events[0].notes, "Weekly team lunch")
    }

    func testParseEmptyCalendar() throws {
        let ics = """
        BEGIN:VCALENDAR
        VERSION:2.0
        END:VCALENDAR
        """
        let parser = ICSParser(content: ics)
        let events = try parser.parse()

        XCTAssertTrue(events.isEmpty)
    }

    func testParseMissingSummarySkipsEvent() throws {
        let ics = """
        BEGIN:VCALENDAR
        BEGIN:VEVENT
        DTSTART:20260215T140000Z
        DTEND:20260215T150000Z
        END:VEVENT
        END:VCALENDAR
        """
        let parser = ICSParser(content: ics)
        let events = try parser.parse()

        XCTAssertTrue(events.isEmpty)
    }

    // MARK: - ICS Escaping (T-018 regression tests)

    func testUnescapeNewline() throws {
        let ics = """
        BEGIN:VCALENDAR
        BEGIN:VEVENT
        SUMMARY:Test
        DTSTART:20260215T140000Z
        DTEND:20260215T150000Z
        DESCRIPTION:Line one\\nLine two
        END:VEVENT
        END:VCALENDAR
        """
        let parser = ICSParser(content: ics)
        let events = try parser.parse()

        XCTAssertEqual(events[0].notes, "Line one\nLine two")
    }

    func testUnescapeCommaAndSemicolon() throws {
        let ics = """
        BEGIN:VCALENDAR
        BEGIN:VEVENT
        SUMMARY:Test
        DTSTART:20260215T140000Z
        DTEND:20260215T150000Z
        LOCATION:Room A\\, Building 1\\; Floor 2
        END:VEVENT
        END:VCALENDAR
        """
        let parser = ICSParser(content: ics)
        let events = try parser.parse()

        XCTAssertEqual(events[0].location, "Room A, Building 1; Floor 2")
    }

    func testUnescapeLiteralBackslash() throws {
        let ics = """
        BEGIN:VCALENDAR
        BEGIN:VEVENT
        SUMMARY:Test
        DTSTART:20260215T140000Z
        DTEND:20260215T150000Z
        DESCRIPTION:Path is C:\\\\Users\\\\test
        END:VEVENT
        END:VCALENDAR
        """
        let parser = ICSParser(content: ics)
        let events = try parser.parse()

        XCTAssertEqual(events[0].notes, "Path is C:\\Users\\test")
    }

    func testUnescapeBackslashFollowedByN() throws {
        // \\n in ICS should become literal \n (backslash + n), NOT a newline
        let ics = """
        BEGIN:VCALENDAR
        BEGIN:VEVENT
        SUMMARY:Test
        DTSTART:20260215T140000Z
        DTEND:20260215T150000Z
        DESCRIPTION:Literal \\\\n should stay
        END:VEVENT
        END:VCALENDAR
        """
        let parser = ICSParser(content: ics)
        let events = try parser.parse()

        XCTAssertEqual(events[0].notes, "Literal \\n should stay")
    }

    func testUnescapeUppercaseN() throws {
        // RFC 5545 allows both \n and \N for newline
        let ics = """
        BEGIN:VCALENDAR
        BEGIN:VEVENT
        SUMMARY:Test
        DTSTART:20260215T140000Z
        DTEND:20260215T150000Z
        DESCRIPTION:Line one\\NLine two
        END:VEVENT
        END:VCALENDAR
        """
        let parser = ICSParser(content: ics)
        let events = try parser.parse()

        XCTAssertEqual(events[0].notes, "Line one\nLine two")
    }

    // MARK: - Line Folding (RFC 5545)

    func testLineFoldingWithSpace() throws {
        // Long lines are folded with CRLF + space
        let ics = "BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\nSUMMARY:A very long ev\r\n ent title here\r\nDTSTART:20260215T140000Z\r\nDTEND:20260215T150000Z\r\nEND:VEVENT\r\nEND:VCALENDAR"
        let parser = ICSParser(content: ics)
        let events = try parser.parse()

        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].title, "A very long event title here")
    }

    func testLineFoldingWithTab() throws {
        let ics = "BEGIN:VCALENDAR\nBEGIN:VEVENT\nSUMMARY:Folded\n\twith tab\nDTSTART:20260215T140000Z\nDTEND:20260215T150000Z\nEND:VEVENT\nEND:VCALENDAR"
        let parser = ICSParser(content: ics)
        let events = try parser.parse()

        XCTAssertEqual(events[0].title, "Foldedwith tab")
    }

    func testLineFoldingLF() throws {
        // Also handle LF-only folding (common in practice)
        let ics = "BEGIN:VCALENDAR\nBEGIN:VEVENT\nSUMMARY:Long\n  title\nDTSTART:20260215T140000Z\nDTEND:20260215T150000Z\nEND:VEVENT\nEND:VCALENDAR"
        let parser = ICSParser(content: ics)
        let events = try parser.parse()

        XCTAssertEqual(events[0].title, "Long title")
    }
}
