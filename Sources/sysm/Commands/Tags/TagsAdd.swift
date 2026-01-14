import ArgumentParser
import Foundation

struct TagsAdd: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add",
        abstract: "Add a tag to a file or folder"
    )

    @Argument(help: "Path to file or folder")
    var path: String

    @Option(name: .shortAndLong, help: "Tag name to add")
    var tag: String

    @Option(name: .shortAndLong, help: "Color code (0=none, 1=red, 2=orange, 3=yellow, 4=green, 5=blue, 6=purple, 7=grey)")
    var color: Int = 0

    func validate() throws {
        guard color >= 0 && color <= 7 else {
            throw TagsError.invalidColor(color)
        }
    }

    func run() throws {
        let service = TagsService()
        let expandedPath = NSString(string: path).expandingTildeInPath
        try service.addTag(path: expandedPath, name: tag, color: color)
        print("Added tag '\(tag)' to \(path)")
    }
}
