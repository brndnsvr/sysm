import ArgumentParser
import Foundation
import SysmCore

struct OutlookSearch: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search Outlook messages"
    )

    @Argument(help: "Search query")
    var query: String

    @Option(name: .long, help: "Maximum results (default: 20)")
    var limit: Int = 20

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.outlook()
        let messages = try service.searchMessages(query: query, limit: limit)

        if json {
            try OutputFormatter.printJSON(messages)
        } else {
            OutlookFormatting.printMessages(messages, header: "Search: \(query)", emptyMessage: "No messages found")
        }
    }
}
