import ArgumentParser
import Foundation

struct CompletionsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "completions",
        abstract: "Manage shell completions for sysm",
        subcommands: [
            CompletionsInstall.self,
            CompletionsUninstall.self,
            CompletionsShow.self,
            CompletionsStatus.self,
        ]
    )
}

enum Shell: String, CaseIterable, ExpressibleByArgument {
    case bash
    case zsh
    case fish

    static func detect() -> Shell? {
        guard let shellPath = ProcessInfo.processInfo.environment["SHELL"] else {
            return nil
        }
        let shellName = URL(fileURLWithPath: shellPath).lastPathComponent
        return Shell(rawValue: shellName)
    }

    var completionFileName: String {
        switch self {
        case .bash: return "sysm.bash"
        case .zsh: return "_sysm"
        case .fish: return "sysm.fish"
        }
    }

    var systemPaths: [String] {
        switch self {
        case .bash:
            return [
                "/opt/homebrew/etc/bash_completion.d",
                "/usr/local/etc/bash_completion.d",
                "\(NSHomeDirectory())/.bash_completion.d"
            ]
        case .zsh:
            return [
                "/opt/homebrew/share/zsh/site-functions",
                "/usr/local/share/zsh/site-functions",
                "\(NSHomeDirectory())/.zsh/completions"
            ]
        case .fish:
            return [
                "\(NSHomeDirectory())/.config/fish/completions",
                "/opt/homebrew/share/fish/vendor_completions.d",
                "/usr/local/share/fish/vendor_completions.d"
            ]
        }
    }

    func findInstallPath() -> String? {
        for path in systemPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return nil
    }

    func findInstalledPath() -> String? {
        for path in systemPaths {
            let fullPath = "\(path)/\(completionFileName)"
            if FileManager.default.fileExists(atPath: fullPath) {
                return fullPath
            }
        }
        return nil
    }
}
