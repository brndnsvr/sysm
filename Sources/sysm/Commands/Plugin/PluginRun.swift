import ArgumentParser
import Foundation

struct PluginRun: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Run a plugin command"
    )

    // MARK: - Arguments

    @Argument(help: "Plugin name")
    var plugin: String

    @Argument(help: "Command to run")
    var command: String

    @Argument(parsing: .captureForPassthrough, help: "Arguments for the command")
    var args: [String] = []

    // MARK: - Options

    @Option(name: .long, help: "Timeout in seconds (default: 300)")
    var timeout: Int = 300

    @Flag(name: .long, help: "Output as JSON")
    var json: Bool = false

    // MARK: - Execution

    func run() throws {
        let manager = Services.plugins()

        // Parse arguments into key-value pairs
        var argDict: [String: String] = [:]
        var i = 0
        while i < args.count {
            let arg = args[i]
            if arg.hasPrefix("--") {
                let key = String(arg.dropFirst(2))
                if i + 1 < args.count && !args[i + 1].hasPrefix("--") {
                    argDict[key] = args[i + 1]
                    i += 2
                } else {
                    argDict[key] = "true"
                    i += 1
                }
            } else if arg.hasPrefix("-") && arg.count == 2 {
                let key = String(arg.dropFirst(1))
                if i + 1 < args.count && !args[i + 1].hasPrefix("-") {
                    argDict[key] = args[i + 1]
                    i += 2
                } else {
                    argDict[key] = "true"
                    i += 1
                }
            } else {
                // Positional argument - use index as key
                argDict[String(argDict.count)] = arg
                i += 1
            }
        }

        let result = try manager.runCommand(
            plugin: plugin,
            command: command,
            args: argDict,
            timeout: TimeInterval(timeout)
        )

        if json {
            try OutputFormatter.printJSON(result)
        } else {
            print(result.formatted())
        }

        if !result.success {
            throw ExitCode(result.exitCode)
        }
    }
}
