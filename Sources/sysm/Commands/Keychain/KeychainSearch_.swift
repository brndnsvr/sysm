import ArgumentParser
import Foundation
import SysmCore

struct KeychainSearch_: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search",
        abstract: "Search keychain items"
    )

    @Argument(help: "Search query (matches service, account, or label)")
    var query: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let svc = Services.keychain()
        let items = try svc.search(query: query)

        if json {
            try OutputFormatter.printJSON(items)
        } else {
            if items.isEmpty {
                print("No keychain items matching '\(query)'")
            } else {
                for item in items {
                    let label = item.label.map { " (\($0))" } ?? ""
                    print("\(item.service)\t\(item.account)\(label)")
                }
            }
        }
    }
}
