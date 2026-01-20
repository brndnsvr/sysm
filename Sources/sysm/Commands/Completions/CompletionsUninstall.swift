import ArgumentParser
import Foundation

struct CompletionsUninstall: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "uninstall",
        abstract: "Remove installed shell completions"
    )

    @Argument(help: "Shell to uninstall completions for (bash, zsh, fish). Auto-detected if not specified.")
    var shell: Shell?

    mutating func run() throws {
        let targetShell = shell ?? Shell.detect()
        guard let targetShell else {
            throw ValidationError("Could not detect shell. Please specify: sysm completions uninstall <bash|zsh|fish>")
        }

        guard let installedPath = targetShell.findInstalledPath() else {
            print("No \(targetShell.rawValue) completions found to uninstall.")
            return
        }

        do {
            try FileManager.default.removeItem(atPath: installedPath)
            print("Removed: \(installedPath)")
            print("Restart your shell for changes to take effect.")
        } catch {
            print("Could not remove \(installedPath)")
            print("Try: sudo sysm completions uninstall \(targetShell.rawValue)")
            throw ExitCode.failure
        }
    }
}
