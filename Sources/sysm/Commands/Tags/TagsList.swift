import ArgumentParser
import Foundation

struct TagsList: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List tags on a file or folder"
    )

    @Argument(help: "Path to file or folder")
    var path: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.tags()
        let expandedPath = NSString(string: path).expandingTildeInPath
        let tags = try service.getTags(path: expandedPath)

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(tags)
            print(String(data: data, encoding: .utf8)!)
        } else {
            if tags.isEmpty {
                print("No tags on: \(path)")
            } else {
                print("Tags on \(path):")
                for tag in tags {
                    print("  - \(tag.formatted())")
                }
            }
        }
    }
}
