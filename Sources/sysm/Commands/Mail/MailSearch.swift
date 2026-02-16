import ArgumentParser
import Foundation
import SysmCore

struct MailSearch: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search messages by subject, sender, body, or date"
    )

    @Argument(help: "Search query (subject/sender)")
    var query: String?

    @Option(name: .long, help: "Search in message body")
    var body: String?

    @Option(name: .long, help: "Messages after date (YYYY-MM-DD)")
    var after: String?

    @Option(name: .long, help: "Messages before date (YYYY-MM-DD)")
    var before: String?

    @Option(name: .long, help: "Filter by account name")
    var account: String?

    @Option(name: .long, help: "Maximum results (default: 30)")
    var limit: Int = 30

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func validate() throws {
        if query == nil && body == nil && after == nil && before == nil {
            throw ValidationError("At least one search criteria required (query, --body, --after, or --before)")
        }
        if limit <= 0 {
            throw ValidationError("--limit must be a positive integer")
        }
        if let after = after, let before = before {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"
            if let afterDate = fmt.date(from: after),
               let beforeDate = fmt.date(from: before),
               afterDate > beforeDate {
                throw ValidationError("--after date must be before --before date")
            }
        }
    }

    func run() throws {
        let service = Services.mail()

        // Parse dates
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var afterDate: Date?
        if let after = after {
            guard let date = dateFormatter.date(from: after) else {
                fputs("Invalid date format for --after. Use YYYY-MM-DD\n", stderr)
                throw ExitCode.failure
            }
            afterDate = date
        }

        var beforeDate: Date?
        if let before = before {
            guard let date = dateFormatter.date(from: before) else {
                fputs("Invalid date format for --before. Use YYYY-MM-DD\n", stderr)
                throw ExitCode.failure
            }
            // Set to end of day
            beforeDate = Calendar.current.date(byAdding: .day, value: 1, to: date)
        }

        let messages = try service.searchMessages(
            accountName: account,
            query: query,
            bodyQuery: body,
            afterDate: afterDate,
            beforeDate: beforeDate,
            limit: limit
        )

        if json {
            try OutputFormatter.printJSON(messages)
        } else {
            // Build search description
            var searchDesc: [String] = []
            if let query = query { searchDesc.append("'\(query)'") }
            if let body = body { searchDesc.append("body:'\(body)'") }
            if let after = after { searchDesc.append("after:\(after)") }
            if let before = before { searchDesc.append("before:\(before)") }
            let searchText = searchDesc.joined(separator: " ")

            if messages.isEmpty {
                print("No messages found for \(searchText)")
            } else {
                print("Search Results for \(searchText) (\(messages.count)):")
                for msg in messages {
                    let readStatus = msg.isRead ? " " : "*"
                    print("\n  \(readStatus)[\(msg.id)] \(msg.subject)")
                    print("   From: \(msg.from)")
                    print("   Date: \(msg.dateReceived)")
                }
            }
        }
    }
}
