import ArgumentParser
import Foundation

struct SafariReadingList: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "rl",
        abstract: "Manage Safari reading list"
    )

    @Argument(help: "URL to add to reading list (omit to list items)")
    var url: String?

    @Option(name: .long, help: "Title for the reading list item")
    var title: String?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.safari()

        if let url = url {
            // Add mode
            try service.addToReadingList(url: url, title: title)
            if !json {
                print("Added to reading list: \(title ?? url)")
            }
        } else {
            // List mode
            let items = try service.getReadingList()

            if json {
                try OutputFormatter.printJSON(items)
            } else {
                if items.isEmpty {
                    print("Reading list is empty")
                } else {
                    print("Reading List (\(items.count) items):")
                    for item in items {
                        print("  - \(item.title)")
                        print("    \(item.url)")
                        if let preview = item.preview, !preview.isEmpty {
                            let truncated = preview.prefix(80)
                            print("    \(truncated)\(preview.count > 80 ? "..." : "")")
                        }
                    }
                }
            }
        }
    }
}
