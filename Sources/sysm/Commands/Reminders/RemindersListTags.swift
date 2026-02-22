import ArgumentParser
import Foundation
import SysmCore

struct RemindersListTags: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list-tags",
        abstract: "List all unique tags across all reminders"
    )

    @Option(name: .shortAndLong, help: "Filter by list name")
    var list: String?

    @Flag(name: .long, help: "Include completed reminders")
    var all = false

    @Flag(name: .long, help: "List native Reminders tags (visible in Reminders.app)")
    var native = false

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        if native {
            try runNative()
        } else {
            try await runHashtag()
        }
    }

    private func runNative() throws {
        let nativeTagService = Services.nativeTag()
        let tags = try nativeTagService.listTags()

        if json {
            try OutputFormatter.printJSON(tags)
        } else {
            if tags.isEmpty {
                print("No native tags found")
            } else {
                print("Native tags (\(tags.count) unique):")
                for tag in tags {
                    print("  \(tag.formatted())")
                }
            }
        }
    }

    private func runHashtag() async throws {
        let service = Services.reminders()

        do {
            let reminders = try await service.getReminders(listName: list, includeCompleted: all)

            var tagCounts: [String: Int] = [:]
            for reminder in reminders {
                for tag in reminder.tags {
                    tagCounts[tag, default: 0] += 1
                }
            }

            let sortedTags = tagCounts.sorted { $0.value > $1.value }

            if json {
                struct TagCount: Codable {
                    let tag: String
                    let count: Int
                }
                let result = sortedTags.map { tag, count in
                    TagCount(tag: tag, count: count)
                }
                try OutputFormatter.printJSON(result)
            } else {
                if sortedTags.isEmpty {
                    print("No tags found")
                } else {
                    print("Tags (\(sortedTags.count) unique):")
                    for (tag, count) in sortedTags {
                        print("  #\(tag) (\(count) reminder\(count == 1 ? "" : "s"))")
                    }
                }
            }
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }
}
