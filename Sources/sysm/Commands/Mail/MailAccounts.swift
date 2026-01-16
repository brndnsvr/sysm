import ArgumentParser
import Foundation

struct MailAccounts: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "accounts",
        abstract: "List configured email accounts"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.mail()
        let accounts = try service.getAccounts()

        if json {
            try OutputFormatter.printJSON(accounts)
        } else {
            if accounts.isEmpty {
                print("No email accounts configured")
            } else {
                print("Email Accounts (\(accounts.count)):")
                for account in accounts {
                    print("  - \(account.name)")
                    print("    \(account.email)")
                }
            }
        }
    }
}
