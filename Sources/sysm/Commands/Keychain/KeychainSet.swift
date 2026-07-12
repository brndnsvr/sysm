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

    @Flag(name: .long, help: "Read the value from non-terminal stdin")
    var valueStdin = false

    @Option(name: .long, help: "Read the value from an inherited file descriptor (3 or greater)")
    var valueFd: Int?

    @Option(name: .shortAndLong, help: "Optional label for the item")
    var label: String?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func validate() throws {
        _ = try valueSource()
    }

    func run() throws {
        try run(service: Services.keychain(), secretReader: SecretInputReader())
    }

    func run(
        service: any KeychainServiceProtocol,
        secretReader: any SecretInputReading
    ) throws {
        let value = try secretReader.read(
            from: valueSource(),
            prompt: "Keychain value: ",
            maximumBytes: 65_536
        )
        try service.set(service: self.service, account: account, value: value, label: label)

        if json {
            try OutputFormatter.printJSON(["status": "saved", "service": self.service, "account": account])
        } else {
            print("Saved to keychain: \(self.service)/\(account)")
        }
    }

    private func valueSource() throws -> SecretInputSource {
        guard let source = try CLI.secretSource(
            standardInput: valueStdin,
            fileDescriptor: valueFd,
            defaultToPrompt: true,
            label: "Keychain value"
        ) else {
            throw ValidationError("Keychain value input is required")
        }
        return source
    }
}
