import ArgumentParser
import Foundation

struct WorkflowRun: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Execute a workflow file"
    )

    // MARK: - Arguments

    @Argument(help: "Path to workflow YAML file")
    var file: String

    // MARK: - Options

    @Flag(name: .long, help: "Show what would run without executing")
    var dryRun: Bool = false

    @Flag(name: .shortAndLong, help: "Show detailed output")
    var verbose: Bool = false

    @Flag(name: .long, help: "Output as JSON")
    var json: Bool = false

    @Option(name: .long, help: "Override workflow working directory")
    var workdir: String?

    // MARK: - Execution

    func run() throws {
        let engine = Services.workflow()

        // Load workflow
        let workflow = try engine.load(path: file)

        // Validate first
        let validation = engine.validate(workflow: workflow)
        if !validation.valid {
            if json {
                let output: [String: Any] = [
                    "success": false,
                    "errors": validation.errors,
                    "warnings": validation.warnings
                ]
                if let data = try? JSONSerialization.data(withJSONObject: output, options: .prettyPrinted),
                   let str = String(data: data, encoding: .utf8) {
                    print(str)
                }
            } else {
                print(validation.formatted())
            }
            throw ExitCode.failure
        }

        // Show warnings if verbose
        if verbose && !validation.warnings.isEmpty {
            for warning in validation.warnings {
                print("Warning: \(warning)")
            }
        }

        // Execute workflow
        let result = try engine.run(
            workflow: workflow,
            dryRun: dryRun,
            verbose: verbose
        )

        // Output results
        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(result)
            print(String(data: data, encoding: .utf8)!)
        } else {
            print(result.formatted(verbose: verbose))
        }

        if !result.success {
            throw ExitCode.failure
        }
    }
}
