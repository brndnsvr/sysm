import ArgumentParser
import SysmCore

struct KeychainCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "keychain",
        abstract: "Keychain password management",
        subcommands: [
            KeychainGet.self,
            KeychainSet.self,
            KeychainDelete.self,
            KeychainList.self,
            KeychainSearch_.self,
        ]
    )
}
