import ArgumentParser
import Foundation
import SysmCore

struct RemindersSearch: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search reminders with filters"
    )

    @Argument(help: "Search query (searches title, notes, and URL)")
    var query: String

    @Option(name: .shortAndLong, help: "Filter by list name")
    var list: String?

    @Flag(name: .long, help: "Include completed reminders")
    var all = false

    @Option(name: .long, help: "Filter by priority: high, medium, low, none")
    var priority: ReminderPriority?

    @Flag(name: .long, help: "Show only overdue reminders")
    var overdue = false

    @Flag(name: .long, help: "Show only reminders with alarms")
    var hasAlarms = false

    @Flag(name: .long, help: "Show only recurring reminders")
    var recurring = false

    @Option(name: .long, help: "Filter by tag (hashtag format, e.g., work)")
    var tag: String?

    @Option(name: .long, help: "Filter by native Reminders tag")
    var nativeTag: String?

    @Flag(name: .long, help: "Show additional details")
    var details = false

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.reminders()

        // Get all reminders
        var reminders = try await service.getReminders(listName: list, includeCompleted: all)

        // Apply search query
        let queryLower = query.lowercased()
        if !queryLower.isEmpty {
            reminders = reminders.filter { reminder in
                reminder.title.lowercased().contains(queryLower) ||
                (reminder.notes?.lowercased().contains(queryLower) ?? false) ||
                (reminder.url?.lowercased().contains(queryLower) ?? false)
            }
        }

        // Apply filters
        if let priorityFilter = priority {
            reminders = reminders.filter { $0.priorityLevel == priorityFilter }
        }

        if overdue {
            let now = Date()
            reminders = reminders.filter { reminder in
                guard let dueDate = reminder.dueDate else { return false }
                return !reminder.isCompleted && dueDate < now
            }
        }

        if hasAlarms {
            reminders = reminders.filter { $0.hasAlarms }
        }

        if recurring {
            reminders = reminders.filter { $0.hasRecurrence }
        }

        if let tagFilter = tag {
            reminders = reminders.filter { $0.hasTag(tagFilter) }
        }

        if let nativeTagFilter = nativeTag {
            let nativeTagService = Services.nativeTag()
            reminders = reminders.filter { reminder in
                let tags = (try? nativeTagService.getTagsForReminder(eventKitId: reminder.id)) ?? []
                return tags.contains(where: { $0.lowercased() == nativeTagFilter.lowercased() })
            }
        }

        // Output results
        if json {
            struct SearchResult: Codable {
                struct Filters: Codable {
                    let list: String?
                    let priority: String?
                    let includeCompleted: Bool
                    let overdue: Bool
                    let hasAlarms: Bool
                    let recurring: Bool
                    let tag: String?
                    let nativeTag: String?
                }
                let query: String
                let filters: Filters
                let count: Int
                let results: [Reminder]
            }
            let result = SearchResult(
                query: query,
                filters: SearchResult.Filters(
                    list: list,
                    priority: priority?.description,
                    includeCompleted: all,
                    overdue: overdue,
                    hasAlarms: hasAlarms,
                    recurring: recurring,
                    tag: tag,
                    nativeTag: nativeTag
                ),
                count: reminders.count,
                results: reminders
            )
            try OutputFormatter.printJSON(result)
        } else {
            if reminders.isEmpty {
                print("No reminders found matching '\(query)'")
            } else {
                print("Found \(reminders.count) reminder\(reminders.count == 1 ? "" : "s") matching '\(query)':")
                for reminder in reminders {
                    print("  \(reminder.formatted(includeList: list == nil, showDetails: details))")
                }
            }
        }
    }
}
