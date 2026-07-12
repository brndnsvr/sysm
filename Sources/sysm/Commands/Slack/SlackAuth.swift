import ArgumentParser
import Foundation
import SysmCore

struct SlackAuth: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "auth",
        abstract: "Configure Slack authentication"
    )

    @Flag(name: .long, help: "Prompt securely for a Slack bot or user token")
    var configure = false

    @Flag(name: .long, help: "Read the Slack token from non-terminal stdin")
    var tokenStdin = false

    @Option(name: .long, help: "Read the Slack token from an inherited file descriptor (3 or greater)")
    var tokenFd: Int?

    @Flag(name: .long, help: "Remove stored token")
    var remove = false

    @Flag(name: .long, help: "Show current auth status")
    var status = false

    func validate() throws {
        if status && remove {
            throw ValidationError("Choose only one operation: --status or --remove")
        }

        let sourceSelected = configure || tokenStdin || tokenFd != nil
        if (status || remove) && sourceSelected {
            throw ValidationError("Authentication input cannot be combined with --status or --remove")
        }

        _ = try secretSource()
    }

    func run() throws {
        try run(service: Services.slack(), secretReader: SecretInputReader())
    }

    func run(
        service: any SlackServiceProtocol,
        secretReader: any SecretInputReading
    ) throws {
        if status {
            if service.isConfigured() {
                print("Slack: configured")
            } else {
                print("Slack: not configured")
                print("  Set up interactively: sysm slack auth --configure")
            }
            return
        }

        if remove {
            try service.removeToken()
            print("Slack token removed")
            return
        }

        guard let source = try secretSource() else {
            if service.isConfigured() {
                print("Slack: configured")
            } else {
                print("Slack: not configured")
                print("  Set up interactively: sysm slack auth --configure")
            }
            return
        }

        let token = try secretReader.read(
            from: source,
            prompt: "Slack token: ",
            maximumBytes: 65_536
        )

        guard token.hasPrefix("xoxb-") || token.hasPrefix("xoxp-") else {
            print("Invalid token format. Token should start with xoxb- (bot) or xoxp- (user)")
            throw ExitCode.failure
        }

        try service.setToken(token)
        print("Slack token saved to Keychain")
    }

    private func secretSource() throws -> SecretInputSource? {
        try CLI.secretSource(
            prompt: configure,
            standardInput: tokenStdin,
            fileDescriptor: tokenFd,
            defaultToPrompt: false,
            label: "Slack token"
        )
    }
}
