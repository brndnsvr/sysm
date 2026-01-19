import ArgumentParser
import Foundation
import SysmCore

struct ExecCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "exec",
        abstract: "Execute scripts and commands",
        discussion: """
        Run shell scripts, Python, AppleScript, or Swift code.

        Examples:
          sysm exec ./script.sh
          sysm exec -c "echo hello" --shell bash
          sysm exec --python ./analyze.py
          sysm exec --applescript -c 'tell app "Finder" to get name of front window'
        """,
        subcommands: [
            ExecRun.self,
        ],
        defaultSubcommand: ExecRun.self
    )
}
