import ArgumentParser
import Foundation
import SysmCore

struct KeychainSet: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "set",
        abstract: "Set a keychain item value"
    )

    @Argument(help: "Service name")
    var service: String

    @Argument(help: "Account name")
    var account: String

    @Option(name: .shortAndLong, help: "Value to store")
    var value: String

    @Option(name: .shortAndLong, help: "Optional label for the item")
    var label: String?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let svc = Services.keychain()
        try svc.set(service: service, account: account, value: value, label: label)

        if json {
            try OutputFormatter.printJSON(["status": "saved", "service": service, "account": account])
        } else {
            print("Saved to keychain: \(service)/\(account)")
        }
    }
}
