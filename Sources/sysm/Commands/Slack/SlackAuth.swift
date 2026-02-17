import ArgumentParser
import Foundation
import SysmCore

struct SlackAuth: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "auth",
        abstract: "Configure Slack authentication"
    )

    @Option(name: .long, help: "Slack bot or user token (xoxb-... or xoxp-...)")
    var token: String?

    @Flag(name: .long, help: "Remove stored token")
    var remove = false

    @Flag(name: .long, help: "Show current auth status")
    var status = false

    func run() throws {
        let service = Services.slack()

        if status {
            if service.isConfigured() {
                print("Slack: configured")
            } else {
                print("Slack: not configured")
                print("  Set up: sysm slack auth --token xoxb-your-token")
            }
            return
        }

        if remove {
            try service.removeToken()
            print("Slack token removed")
            return
        }

        guard let token = token else {
            if service.isConfigured() {
                print("Slack: configured")
            } else {
                print("Slack: not configured")
                print("  Set up: sysm slack auth --token xoxb-your-token")
            }
            return
        }

        guard token.hasPrefix("xoxb-") || token.hasPrefix("xoxp-") else {
            print("Invalid token format. Token should start with xoxb- (bot) or xoxp- (user)")
            throw ExitCode.failure
        }

        try service.setToken(token)
        print("Slack token saved to Keychain")
    }
}
