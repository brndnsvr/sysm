import ArgumentParser
import Foundation
import SysmCore

struct KeychainGet: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get a keychain item value"
    )

    @Argument(help: "Service name")
    var service: String

    @Argument(help: "Account name")
    var account: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let svc = Services.keychain()
        let detail = try svc.get(service: service, account: account)

        if json {
            try OutputFormatter.printJSON(detail)
        } else {
            print(detail.value)
        }
    }
}
