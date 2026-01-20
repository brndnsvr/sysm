import ArgumentParser
import Foundation

struct CompletionsInstall: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "install",
        abstract: "Install shell completions for the current shell"
    )

    @Argument(help: "Shell to install completions for (bash, zsh, fish). Auto-detected if not specified.")
    var shell: Shell?

    @Flag(name: .long, help: "Create user directory if system paths aren't writable")
    var userDir = false

    mutating func run() throws {
        let targetShell = shell ?? Shell.detect()
        guard let targetShell else {
            throw ValidationError("Could not detect shell. Please specify: sysm completions install <bash|zsh|fish>")
        }

        // Generate completion script
        let script = try generateCompletionScript(for: targetShell)

        // Find installation path
        guard let installDir = findOrCreateInstallDir(for: targetShell) else {
            printInstallInstructions(for: targetShell, script: script)
            return
        }

        let installPath = "\(installDir)/\(targetShell.completionFileName)"

        // Write the completion file
        do {
            try script.write(toFile: installPath, atomically: true, encoding: .utf8)
            print("Installed \(targetShell.rawValue) completions to: \(installPath)")
            print("")
            printPostInstallInstructions(for: targetShell)
        } catch {
            // Try with elevated permissions hint
            print("Could not write to \(installPath)")
            print("Try: sudo sysm completions install \(targetShell.rawValue)")
            print("")
            print("Or install to user directory:")
            print("  sysm completions install \(targetShell.rawValue) --user-dir")
            throw ExitCode.failure
        }
    }

    private func generateCompletionScript(for shell: Shell) throws -> String {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["sysm", "--generate-completion-script", shell.rawValue]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let script = String(data: data, encoding: .utf8), !script.isEmpty else {
            throw ValidationError("Failed to generate completion script")
        }
        return script
    }

    private func findOrCreateInstallDir(for shell: Shell) -> String? {
        // First try existing system paths
        if let path = shell.findInstallPath() {
            if FileManager.default.isWritableFile(atPath: path) {
                return path
            }
        }

        // If --user-dir flag, create user directory
        if userDir {
            let userPath: String
            switch shell {
            case .bash:
                userPath = "\(NSHomeDirectory())/.bash_completion.d"
            case .zsh:
                userPath = "\(NSHomeDirectory())/.zsh/completions"
            case .fish:
                userPath = "\(NSHomeDirectory())/.config/fish/completions"
            }

            do {
                try FileManager.default.createDirectory(
                    atPath: userPath,
                    withIntermediateDirectories: true
                )
                return userPath
            } catch {
                return nil
            }
        }

        // Return first system path even if not writable (will fail with helpful message)
        return shell.systemPaths.first
    }

    private func printInstallInstructions(for shell: Shell, script: String) {
        print("No writable completion directory found for \(shell.rawValue).")
        print("")
        print("Option 1: Install with sudo")
        print("  sudo sysm completions install \(shell.rawValue)")
        print("")
        print("Option 2: Install to user directory")
        print("  sysm completions install \(shell.rawValue) --user-dir")
        print("")
        print("Option 3: Manual installation")
        print("  sysm completions show \(shell.rawValue) > ~/.local/share/\(shell.completionFileName)")
    }

    private func printPostInstallInstructions(for shell: Shell) {
        switch shell {
        case .bash:
            print("Restart your shell or run:")
            print("  source ~/.bashrc")
        case .zsh:
            print("Restart your shell or run:")
            print("  exec zsh")
        case .fish:
            print("Completions are available immediately in new terminals.")
        }
    }
}
