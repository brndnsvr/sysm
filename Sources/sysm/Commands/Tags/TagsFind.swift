import ArgumentParser
import Foundation

struct TagsFind: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "find",
        abstract: "Find files with a specific tag"
    )

    @Argument(help: "Tag name to search for")
    var tag: String

    @Option(name: .shortAndLong, help: "Limit search to directory")
    var scope: String?

    @Option(name: .shortAndLong, help: "Limit number of results")
    var limit: Int?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = TagsService()
        let expandedScope = scope.map { NSString(string: $0).expandingTildeInPath }
        var files = try service.findByTag(name: tag, scope: expandedScope)

        if let limit = limit, files.count > limit {
            files = Array(files.prefix(limit))
        }

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let results = files.map { ["path": $0] }
            let data = try encoder.encode(results)
            print(String(data: data, encoding: .utf8)!)
        } else {
            if files.isEmpty {
                print("No files found with tag '\(tag)'")
            } else {
                print("Files with tag '\(tag)' (\(files.count)):")
                for file in files {
                    print("  \(file)")
                }
            }
        }
    }
}
