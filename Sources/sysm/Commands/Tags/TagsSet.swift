import ArgumentParser
import Foundation
import SysmCore

struct TagsSet: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "set",
        abstract: "Set tags on a file, replacing all existing tags"
    )

    @Argument(help: "Path to file or folder")
    var path: String

    @Option(name: .shortAndLong, help: "Comma-separated tags (e.g., 'work,important' or 'work:1,important:4' with colors)")
    var tags: String

    func run() throws {
        let service = Services.tags()
        let expandedPath = NSString(string: path).expandingTildeInPath

        let parsedTags = try parseTags(tags)
        try service.setTags(path: expandedPath, tags: parsedTags)

        if parsedTags.isEmpty {
            print("Cleared all tags from \(path)")
        } else {
            let tagNames = parsedTags.map { $0.formatted() }.joined(separator: ", ")
            print("Set tags on \(path): \(tagNames)")
        }
    }

    private func parseTags(_ input: String) throws -> [TagsService.FinderTag] {
        if input.trimmingCharacters(in: .whitespaces).isEmpty {
            return []
        }

        return try input.components(separatedBy: ",").map { part in
            let trimmed = part.trimmingCharacters(in: .whitespaces)
            if trimmed.contains(":") {
                let components = trimmed.components(separatedBy: ":")
                let name = components[0]
                guard let color = Int(components[1]), color >= 0, color <= 7 else {
                    throw TagsError.invalidColor(Int(components[1]) ?? -1)
                }
                return TagsService.FinderTag(name: name, color: color)
            } else {
                return TagsService.FinderTag(name: trimmed, color: 0)
            }
        }
    }
}
