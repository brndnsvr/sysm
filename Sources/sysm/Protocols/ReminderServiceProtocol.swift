import Foundation

/// Protocol for reminder service operations
protocol ReminderServiceProtocol: Sendable {
    func requestAccess() async throws -> Bool
    func listNames() async throws -> [String]
    func getReminders(listName: String?, includeCompleted: Bool) async throws -> [Reminder]
    func getTodayReminders() async throws -> [Reminder]
    func addReminder(title: String, listName: String, dueDate: String?) async throws -> Reminder
    func completeReminder(name: String) async throws -> Bool
    func validateReminders() async throws -> [Reminder]
}

extension ReminderServiceProtocol {
    func getReminders(listName: String? = nil, includeCompleted: Bool = false) async throws -> [Reminder] {
        try await getReminders(listName: listName, includeCompleted: includeCompleted)
    }
}
