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
        let service = SpotlightService()
        let expandedScope = scope.map { NSString(string: $0).expandingTildeInPath }
        let results = try service.search(query: query, scope: expandedScope, limit: limit)

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(results)
            print(String(data: data, encoding: .utf8)!)
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
