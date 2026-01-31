import ArgumentParser
import Foundation
import SysmCore

struct ExecRun: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Run a script or inline code"
    )

    // MARK: - Arguments

    @Argument(help: "Script file to execute (optional if using -c)")
    var script: String?

    @Option(name: .shortAndLong, help: "Inline code to execute")
    var code: String?

    @Option(name: .long, help: "Arguments to pass to the script")
    var args: [String] = []

    // MARK: - Script Type Options

    @Option(name: .long, help: "Shell type: bash, zsh, fish")
    var shell: String?

    @Flag(name: .long, help: "Run as Python script")
    var python: Bool = false

    @Flag(name: .long, help: "Run as AppleScript")
    var applescript: Bool = false

    @Flag(name: .long, help: "Run as Swift script")
    var swift: Bool = false

    // MARK: - Execution Options

    @Option(name: .long, help: "Timeout in seconds (default: 300)")
    var timeout: Int = 300

    @Flag(name: .long, help: "Stream output in real-time")
    var stream: Bool = false

    // MARK: - Output Options

    @Flag(name: .long, help: "Output as JSON")
    var json: Bool = false

    @Flag(name: .long, help: "Suppress output, only show exit code")
    var quiet: Bool = false

    // MARK: - Validation

    func validate() throws {
        if script == nil && code == nil {
            throw ValidationError("Provide a script file or use -c for inline code")
        }
        if script != nil && code != nil {
            throw ValidationError("Cannot specify both script file and inline code")
        }

        // Check mutual exclusivity of type flags
        let typeFlags = [shell != nil, python, applescript, swift]
        if typeFlags.filter({ $0 }).count > 1 {
            throw ValidationError("Specify only one of: --shell, --python, --applescript, --swift")
        }
    }

    // MARK: - Execution

    func run() throws {
        let runner = Services.scriptRunner()

        // Determine script type
        let scriptType = try determineScriptType()

        let result: ScriptRunner.ExecutionResult

        if let codeString = code {
            // Run inline code
            guard let type = scriptType else {
                throw ExecError.typeRequired
            }
            result = try runner.runCode(
                code: codeString,
                scriptType: type,
                args: args,
                timeout: TimeInterval(timeout),
                env: [:]
            )
        } else if let scriptPath = script {
            // Run script file
            let expandedPath = (scriptPath as NSString).expandingTildeInPath
            let resolvedPath = (expandedPath as NSString).standardizingPath

            // Validate path is within allowed directories
            let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
            guard resolvedPath.hasPrefix(homeDir) || resolvedPath.hasPrefix("/tmp") else {
                throw ExecError.invalidPath(scriptPath)
            }

            result = try runner.runFile(
                path: expandedPath,
                args: args,
                scriptType: scriptType,
                timeout: TimeInterval(timeout),
                env: [:]
            )
        } else {
            throw ExecError.noInput
        }

        // Output results
        if json {
            try OutputFormatter.printJSON(result)
        } else if quiet {
            // Exit with script's exit code
            if !result.success {
                throw ExitCode(result.exitCode)
            }
        } else {
            print(result.formatted())
            if !result.success {
                throw ExitCode(result.exitCode)
            }
        }
    }

    // MARK: - Helpers

    private func determineScriptType() throws -> ScriptRunner.ScriptType? {
        if let shellType = shell {
            guard let type = ScriptRunner.ScriptType(rawValue: shellType) else {
                throw ExecError.invalidShell(shellType)
            }
            return type
        }

        if python { return .python3 }
        if applescript { return .applescript }
        if swift { return .swift }

        // For inline code without type flag, default to bash
        if code != nil && script == nil {
            return .bash
        }

        // For script files, let ScriptRunner auto-detect
        return nil
    }
}

// MARK: - Errors

enum ExecError: LocalizedError {
    case noInput
    case typeRequired
    case invalidShell(String)
    case invalidPath(String)

    var errorDescription: String? {
        switch self {
        case .noInput:
            return "No script or code provided"
        case .typeRequired:
            return "Specify script type with --shell, --python, --applescript, or --swift"
        case .invalidShell(let shell):
            return "Invalid shell type: \(shell). Use: bash, zsh, fish"
        case .invalidPath(let path):
            return "Script path must be within home directory or /tmp: \(path)"
        }
    }
}
