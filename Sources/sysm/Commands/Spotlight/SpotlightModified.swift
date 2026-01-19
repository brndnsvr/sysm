import ArgumentParser
import Foundation
import SysmCore

struct SpotlightModified: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "modified",
        abstract: "Find files modified in the last N days"
    )

    @Argument(help: "Number of days to look back")
    var days: Int

    @Option(name: .shortAndLong, help: "Limit search to directory")
    var scope: String?

    @Option(name: .shortAndLong, help: "Limit number of results")
    var limit: Int?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.spotlight()
        let expandedScope = scope.map { NSString(string: $0).expandingTildeInPath }
        let results = try service.searchModified(days: days, scope: expandedScope, limit: limit)

        if json {
            try OutputFormatter.printJSON(results)
        } else {
            if results.isEmpty {
                print("No files modified in the last \(days) day(s)")
            } else {
                print("Files modified in last \(days) day(s) (\(results.count)):\n")
                for result in results {
                    print("  \(result.formatted())\n")
                }
            }
        }
    }
}
