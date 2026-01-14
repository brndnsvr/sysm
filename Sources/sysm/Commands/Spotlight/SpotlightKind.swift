import ArgumentParser
import Foundation

struct SpotlightKind: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "kind",
        abstract: "Search files by type (pdf, image, video, audio, document, folder, application)"
    )

    @Argument(help: "File type to search for (pdf, image, video, audio, document, folder, application, archive, presentation, spreadsheet)")
    var kind: String

    @Option(name: .shortAndLong, help: "Limit search to directory")
    var scope: String?

    @Option(name: .shortAndLong, help: "Limit number of results")
    var limit: Int?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = SpotlightService()
        let expandedScope = scope.map { NSString(string: $0).expandingTildeInPath }
        let results = try service.searchByKind(kind: kind, scope: expandedScope, limit: limit)

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(results)
            print(String(data: data, encoding: .utf8)!)
        } else {
            if results.isEmpty {
                print("No files of type '\(kind)' found")
            } else {
                print("Files of type '\(kind)' (\(results.count)):\n")
                for result in results {
                    print("  \(result.formatted())\n")
                }
            }
        }
    }
}
