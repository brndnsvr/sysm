import ArgumentParser
import Foundation
import SysmCore

struct KeychainList: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List keychain items"
    )

    @Option(name: .shortAndLong, help: "Filter by service name")
    var service: String?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let svc = Services.keychain()
        let items = try svc.list(service: service)

        if json {
            try OutputFormatter.printJSON(items)
        } else {
            if items.isEmpty {
                print("No keychain items found")
            } else {
                for item in items {
                    let label = item.label.map { " (\($0))" } ?? ""
                    print("\(item.service)\t\(item.account)\(label)")
                }
            }
        }
    }
}
