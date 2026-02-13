//
//  TestFixtures.swift
//  sysm
//

import Foundation
@testable import SysmCore

/// Provides sample test data for all sysm models.
///
/// These fixtures can be used in tests to avoid repetitive object creation
/// and ensure consistency across tests.
public enum TestFixtures {

    // MARK: - Calendar Fixtures

    // Note: CalendarEvent requires EventKit EKEvent - use real events in integration tests
    // For unit tests, mock the service protocol methods instead

    // Note: Calendar, Reminder, Contact, Photo models require EventKit/Contacts/Photos frameworks
    // Use real framework objects in integration tests
    // For unit tests, mock the service protocol methods instead

    // MARK: - Date Fixtures

    /// Returns a date for "today at 2pm"
    public static var todayAt2PM: Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 14
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components)!
    }

    /// Returns a date for "tomorrow at 9am"
    public static var tomorrowAt9AM: Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1
        components.hour = 9
        components.minute = 0
        components.second = 0
        return Calendar.current.date(from: components)!
    }

    /// Returns a date for "next Monday at 10am"
    public static var nextMondayAt10AM: Date {
        let calendar = Calendar.current
        let today = Date()
        var components = DateComponents()
        components.weekday = 2 // Monday
        components.hour = 10
        components.minute = 0

        if let nextMonday = calendar.nextDate(
            after: today,
            matching: components,
            matchingPolicy: .nextTime
        ) {
            return nextMonday
        }

        // Fallback
        return today.addingTimeInterval(86400 * 7)
    }

    // MARK: - String Fixtures

    /// Sample ICS content for import testing
    public static var sampleICSContent: String {
        """
        BEGIN:VCALENDAR
        VERSION:2.0
        PRODID:-//sysm//EN
        BEGIN:VEVENT
        UID:test-event-ics@example.com
        DTSTAMP:20240101T120000Z
        DTSTART:20240115T140000Z
        DTEND:20240115T150000Z
        SUMMARY:Test Event
        DESCRIPTION:This is a test event from ICS
        LOCATION:Test Location
        END:VEVENT
        END:VCALENDAR
        """
    }

    /// Sample AppleScript output for mail list
    public static var sampleMailListOutput: String {
        """
        test-mail-1|||Project Update|||alice@example.com|||bob@example.com|||2024-01-15 14:30:00|||false|||false|||Inbox|||true|||report.pdf
        test-mail-2|||Weekly Report|||bob@example.com|||team@example.com|||2024-01-14 09:00:00|||true|||false|||Inbox|||false|||
        """
    }

    /// Sample AppleScript output for notes list
    public static var sampleNotesListOutput: String {
        """
        test-note-1|||Meeting Notes|||Work|||2024-01-15 10:00:00
        test-note-2|||Ideas|||Personal|||2024-01-10 15:30:00
        """
    }
}
