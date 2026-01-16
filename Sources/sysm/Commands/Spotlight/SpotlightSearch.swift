import ArgumentParser
import Foundation

struct SpotlightSearch: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search files by content or name"
    )

    @Argument(help: "Search query")
    var query: String

    @Option(name: .shortAndLong, help: "Limit search to directory")
    var scope: String?

    @Option(name: .shortAndLong, help: "Limit number of results")
    var limit: Int?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.spotlight()
        let expandedScope = scope.map { NSString(string: $0).expandingTildeInPath }
        let results = try service.search(query: query, scope: expandedScope, limit: limit)

        if json {
            try OutputFormatter.printJSON(results)
        } else {
            if results.isEmpty {
                print("No results for '\(query)'")
            } else {
                print("Search results for '\(query)' (\(results.count)):\n")
                for result in results {
                    print("  \(result.formatted())\n")
                }
            }
        }
    }
}
