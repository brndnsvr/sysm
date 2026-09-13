import ArgumentParser
import Foundation
import SysmCore

struct TagsAdd: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add",
        abstract: "Add a tag to a file or folder"
    )

    @Argument(help: "Path to file or folder")
    var path: String

    @Option(name: .shortAndLong, help: "Tag name to add")
    var tag: String

    @Option(name: .shortAndLong, help: "Color name or number: none (0), gray (1), green (2), purple (3), blue (4), yellow (5), red (6), orange (7)")
    var color: String = "none"

    func validate() throws {
        guard TagsService.FinderTag.colorCode(from: color) != nil else {
            throw TagsError.invalidColor(color)
        }
    }

    func run() throws {
        let service = Services.tags()
        let expandedPath = NSString(string: path).expandingTildeInPath
        let code = TagsService.FinderTag.colorCode(from: color) ?? 0
        try service.addTag(path: expandedPath, name: tag, color: code)
        let colorNote = code == 0 ? "" : " (\(TagsService.FinderTag.colorNames[code]))"
        print("Added tag '\(tag)'\(colorNote) to \(path)")
    }
}
