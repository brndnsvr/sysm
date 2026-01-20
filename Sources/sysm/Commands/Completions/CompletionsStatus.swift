import ArgumentParser
import Foundation

struct CompletionsStatus: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Show completion installation status"
    )

    mutating func run() throws {
        let currentShell = Shell.detect()
        let shellName = currentShell?.rawValue ?? "unknown"

        print("Current shell: \(shellName)")
        print("")
        print("Completion status:")

        for shell in Shell.allCases {
            let marker = shell == currentShell ? "*" : " "
            if let path = shell.findInstalledPath() {
                print("  \(marker) \(shell.rawValue): installed (\(path))")
            } else {
                print("  \(marker) \(shell.rawValue): not installed")
            }
        }

        print("")
        print("To install completions for your shell:")
        print("  sysm completions install")
        print("")
        print("To install for a specific shell:")
        print("  sysm completions install <bash|zsh|fish>")
    }
}
