import ArgumentParser
import Foundation

struct TagsRemove: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "remove",
        abstract: "Remove a tag from a file or folder"
    )

    @Argument(help: "Path to file or folder")
    var path: String

    @Option(name: .shortAndLong, help: "Tag name to remove")
    var tag: String

    func run() throws {
        let service = Services.tags()
        let expandedPath = NSString(string: path).expandingTildeInPath
        try service.removeTag(path: expandedPath, name: tag)
        print("Removed tag '\(tag)' from \(path)")
    }
}
