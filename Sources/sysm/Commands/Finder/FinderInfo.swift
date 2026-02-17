import ArgumentParser
import Foundation
import SysmCore

struct FinderInfo: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "info",
        abstract: "Show file or folder information"
    )

    @Argument(help: "Path to inspect")
    var path: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.finder()
        let info = try service.getInfo(path: path)

        if json {
            try OutputFormatter.printJSON(info)
        } else {
            print("Name:       \(info.name)")
            print("Kind:       \(info.kind)")
            print("Size:       \(info.sizeFormatted)")
            print("Path:       \(info.path)")
            if let created = info.created {
                print("Created:    \(formatDate(created))")
            }
            if let modified = info.modified {
                print("Modified:   \(formatDate(modified))")
            }
            if info.isDirectory { print("Type:       Directory") }
            if info.isHidden { print("Hidden:     Yes") }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
