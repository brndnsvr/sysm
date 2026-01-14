import ArgumentParser
import Foundation

struct WorkflowNew: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "new",
        abstract: "Create a new workflow from template"
    )

    // MARK: - Arguments

    @Argument(help: "Name for the new workflow")
    var name: String

    // MARK: - Options

    @Option(name: .long, help: "Output directory (default: ~/.sysm/workflows/)")
    var dir: String?

    @Option(name: .shortAndLong, help: "Description for the workflow")
    var description: String?

    @Flag(name: .long, help: "Overwrite existing file")
    var force: Bool = false

    @Flag(name: .long, help: "Print to stdout instead of creating file")
    var stdout: Bool = false

    // MARK: - Execution

    func run() throws {
        // Generate workflow content
        let content = generateWorkflow()

        if stdout {
            print(content)
            return
        }

        // Determine output path
        let outputDir: String
        if let d = dir {
            outputDir = (d as NSString).expandingTildeInPath
        } else {
            outputDir = (("~/.sysm/workflows") as NSString).expandingTildeInPath
        }

        // Create directory if needed
        try FileManager.default.createDirectory(
            atPath: outputDir,
            withIntermediateDirectories: true,
            attributes: nil
        )

        let filename = name.hasSuffix(".yaml") || name.hasSuffix(".yml") ? name : "\(name).yaml"
        let outputPath = (outputDir as NSString).appendingPathComponent(filename)

        // Check for existing file
        if FileManager.default.fileExists(atPath: outputPath) && !force {
            throw ValidationError("File already exists: \(outputPath)\nUse --force to overwrite")
        }

        // Write file
        try content.write(toFile: outputPath, atomically: true, encoding: .utf8)

        print("Created workflow: \(outputPath)")
        print("\nRun with: sysm workflow run \(outputPath)")
        print("Validate with: sysm workflow validate \(outputPath)")
    }

    // MARK: - Template Generation

    private func generateWorkflow() -> String {
        let desc = description ?? "A sysm workflow"
        let safeName = name.replacingOccurrences(of: " ", with: "-").lowercased()

        // Note: Template variables use {{ var }} syntax which conflicts with YAML
        // flow mappings. Always use multiline (|) or quoted strings for run commands
        // that contain template variables.
        return """
name: \(safeName)
description: \(desc)
version: "1.0.0"

steps:
  - name: hello
    run: echo "Hello from \(safeName)!"
    output: greeting

  - name: show-greeting
    run: |
      echo "Previous step said: {{ greeting }}"

# Workflow features (uncomment to use):
#
# Triggers:
#   triggers:
#     - schedule: "0 9 * * *"   # Cron syntax
#     - manual: true
#
# Environment variables:
#   env:
#     MY_VAR: "value"
#
# Conditional execution:
#   - name: conditional-step
#     run: echo "Only runs if condition is true"
#     when: '{{ some_var }}'
#
# Retries and timeout:
#   - name: retry-example
#     run: curl https://api.example.com/data
#     retries: 3
#     retry_delay: 5
#     timeout: 30
#
# Continue on error:
#   - name: optional-step
#     run: echo "This might fail"
#     continue_on_error: true
"""
    }
}
