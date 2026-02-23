import ArgumentParser
import Foundation
import SysmCore

struct KeychainDelete: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a keychain item"
    )

    @Argument(help: "Service name")
    var service: String

    @Argument(help: "Account name")
    var account: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let svc = Services.keychain()
        try svc.delete(service: service, account: account)

        if json {
            try OutputFormatter.printJSON(["status": "deleted", "service": service, "account": account])
        } else {
            print("Deleted from keychain: \(service)/\(account)")
        }
    }
}
