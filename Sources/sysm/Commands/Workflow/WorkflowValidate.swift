import ArgumentParser
import Foundation
import SysmCore

struct WorkflowValidate: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "validate",
        abstract: "Check workflow syntax and structure"
    )

    // MARK: - Arguments

    @Argument(help: "Path to workflow YAML file")
    var file: String

    // MARK: - Options

    @Flag(name: .long, help: "Output as JSON")
    var json: Bool = false

    @Flag(name: .long, help: "Only show errors, not warnings")
    var errorsOnly: Bool = false

    // MARK: - Execution

    func run() throws {
        let engine = Services.workflow()

        // Load and parse
        let workflow: Workflow
        do {
            workflow = try engine.load(path: file)
        } catch {
            if json {
                let output: [String: Any] = [
                    "valid": false,
                    "errors": [error.localizedDescription],
                    "warnings": [] as [String]
                ]
                if let data = try? JSONSerialization.data(withJSONObject: output, options: .prettyPrinted),
                   let str = String(data: data, encoding: .utf8) {
                    print(str)
                }
            } else {
                print("Error: \(error.localizedDescription)")
            }
            throw ExitCode.failure
        }

        // Validate
        let result = engine.validate(workflow: workflow)

        if json {
            var output: [String: Any] = [
                "valid": result.valid,
                "errors": result.errors
            ]
            if !errorsOnly {
                output["warnings"] = result.warnings
            }
            output["workflow"] = [
                "name": workflow.name,
                "description": workflow.description ?? "",
                "steps": workflow.steps.count
            ]
            if let data = try? JSONSerialization.data(withJSONObject: output, options: .prettyPrinted),
               let str = String(data: data, encoding: .utf8) {
                print(str)
            }
        } else {
            print("Workflow: \(workflow.name)")
            if let desc = workflow.description {
                print("Description: \(desc)")
            }
            print("Steps: \(workflow.steps.count)")
            print("")

            if result.valid {
                print("Status: Valid")
            } else {
                print("Status: Invalid")
                print("\nErrors:")
                for error in result.errors {
                    print("  - \(error)")
                }
            }

            if !errorsOnly && !result.warnings.isEmpty {
                print("\nWarnings:")
                for warning in result.warnings {
                    print("  - \(warning)")
                }
            }
        }

        if !result.valid {
            throw ExitCode.failure
        }
    }
}
