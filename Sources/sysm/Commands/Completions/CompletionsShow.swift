import ArgumentParser
import Foundation

struct CompletionsShow: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "show",
        abstract: "Print completion script to stdout"
    )

    @Argument(help: "Shell to generate completions for (bash, zsh, fish)")
    var shell: Shell

    mutating func run() throws {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["sysm", "--generate-completion-script", shell.rawValue]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        try process.run()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        if let script = String(data: data, encoding: .utf8) {
            print(script, terminator: "")
        }
    }
}
