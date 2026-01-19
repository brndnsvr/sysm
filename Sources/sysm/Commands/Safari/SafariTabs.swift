import ArgumentParser
import Foundation
import SysmCore

struct SafariTabs: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tabs",
        abstract: "List open Safari tabs"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.safari()
        let tabs = try service.getOpenTabs()

        if json {
            try OutputFormatter.printJSON(tabs)
        } else {
            if tabs.isEmpty {
                print("No Safari tabs open (is Safari running?)")
            } else {
                print("Safari Tabs (\(tabs.count)):")

                // Group by window
                let grouped = Dictionary(grouping: tabs) { $0.windowIndex }
                let sortedWindows = grouped.keys.sorted()

                for windowIndex in sortedWindows {
                    print("\n  Window \(windowIndex):")
                    if let windowTabs = grouped[windowIndex] {
                        for tab in windowTabs.sorted(by: { $0.tabIndex < $1.tabIndex }) {
                            print("    [\(tab.tabIndex)] \(tab.title)")
                            print("        \(tab.url)")
                        }
                    }
                }
            }
        }
    }
}
