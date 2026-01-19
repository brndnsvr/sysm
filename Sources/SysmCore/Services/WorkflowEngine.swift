import Foundation
import Yams

public struct WorkflowEngine: WorkflowEngineProtocol {

    // MARK: - Types

    public struct Workflow: Codable {
        public let name: String
        public let description: String?
        public let version: String?
        public let author: String?
        public let triggers: [Trigger]?
        public let env: [String: String]?
        public let steps: [Step]
        public let onError: [ErrorHandler]?

        enum CodingKeys: String, CodingKey {
            case name, description, version, author, triggers, env, steps
            case onError = "on_error"
        }
    }

    public struct Trigger: Codable {
        public let schedule: String?
        public let manual: Bool?
        public let event: String?
    }

    public struct Step: Codable {
        public let name: String
        public let run: String
        public let shell: String?
        public let output: String?
        public let when: String?
        public let timeout: Int?
        public let continueOnError: Bool?
        public let retries: Int?
        public let retryDelay: Int?

        enum CodingKeys: String, CodingKey {
            case name, run, shell, output, when, timeout
            case continueOnError = "continue_on_error"
            case retries
            case retryDelay = "retry_delay"
        }
    }

    public struct ErrorHandler: Codable {
        public let notify: String?
        public let run: String?
    }

    public struct ExecutionContext {
        public var variables: [String: Any]
        public var env: [String: String]
        public var workingDirectory: String

        public init(workingDirectory: String = FileManager.default.currentDirectoryPath) {
            self.variables = [:]
            self.env = ProcessInfo.processInfo.environment
            self.workingDirectory = workingDirectory
        }

        public mutating func set(_ key: String, value: Any) {
            variables[key] = value
        }

        public func get(_ key: String) -> Any? {
            return variables[key]
        }
    }

    public struct StepResult: Codable {
        public let name: String
        public let success: Bool
        public let exitCode: Int32
        public let stdout: String
        public let stderr: String
        public let duration: Double
        public let skipped: Bool

        public static func skipped(name: String) -> StepResult {
            return StepResult(
                name: name,
                success: true,
                exitCode: 0,
                stdout: "",
                stderr: "",
                duration: 0,
                skipped: true
            )
        }
    }

    public struct WorkflowResult: Codable {
        public let workflow: String
        public let success: Bool
        public let totalDuration: Double
        public let steps: [StepResult]
        public let error: String?

        public func formatted(verbose: Bool = false) -> String {
            var output = ""
            let status = success ? "SUCCESS" : "FAILED"
            output += "Workflow: \(workflow)\n"
            output += "Status: \(status)\n"
            output += "Duration: \(String(format: "%.2f", totalDuration))s\n"
            output += "Steps: \(steps.filter { !$0.skipped }.count)/\(steps.count)\n"

            if verbose || !success {
                output += "\nStep Details:\n"
                for step in steps {
                    let stepStatus = step.skipped ? "SKIPPED" : (step.success ? "OK" : "FAILED")
                    output += "  - \(step.name): \(stepStatus)"
                    if !step.skipped {
                        output += " (\(String(format: "%.2f", step.duration))s)"
                    }
                    output += "\n"
                    if verbose && !step.stdout.isEmpty {
                        output += "    stdout: \(step.stdout.prefix(200))\n"
                    }
                    if !step.success && !step.stderr.isEmpty {
                        output += "    stderr: \(step.stderr)\n"
                    }
                }
            }

            if let error = error {
                output += "\nError: \(error)\n"
            }

            return output
        }
    }

    public enum WorkflowError: LocalizedError {
        case fileNotFound(String)
        case parseError(String)
        case stepFailed(String, String)
        case conditionFailed(String)
        case invalidTemplate(String)
        case timeout(String)

        public var errorDescription: String? {
            switch self {
            case .fileNotFound(let path):
                return "Workflow file not found: \(path)"
            case .parseError(let message):
                return "Failed to parse workflow: \(message)"
            case .stepFailed(let step, let message):
                return "Step '\(step)' failed: \(message)"
            case .conditionFailed(let condition):
                return "Condition evaluation failed: \(condition)"
            case .invalidTemplate(let template):
                return "Invalid template: \(template)"
            case .timeout(let step):
                return "Step '\(step)' timed out"
            }
        }
    }

    // MARK: - Loading

    public func load(path: String) throws -> Workflow {
        let expandedPath = (path as NSString).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: expandedPath) else {
            throw WorkflowError.fileNotFound(expandedPath)
        }

        let content = try String(contentsOfFile: expandedPath, encoding: .utf8)
        return try parse(yaml: content)
    }

    public func parse(yaml: String) throws -> Workflow {
        do {
            let decoder = YAMLDecoder()
            return try decoder.decode(Workflow.self, from: yaml)
        } catch {
            throw WorkflowError.parseError(error.localizedDescription)
        }
    }

    // MARK: - Validation

    public struct ValidationResult {
        public let valid: Bool
        public let errors: [String]
        public let warnings: [String]

        public func formatted() -> String {
            var output = ""
            if valid {
                output += "Workflow is valid\n"
            } else {
                output += "Workflow has errors:\n"
                for error in errors {
                    output += "  ERROR: \(error)\n"
                }
            }
            if !warnings.isEmpty {
                output += "Warnings:\n"
                for warning in warnings {
                    output += "  WARN: \(warning)\n"
                }
            }
            return output
        }
    }

    public func validate(workflow: Workflow) -> ValidationResult {
        var errors: [String] = []
        var warnings: [String] = []

        if workflow.name.isEmpty {
            errors.append("Workflow name is required")
        }

        if workflow.steps.isEmpty {
            errors.append("Workflow must have at least one step")
        }

        var stepNames = Set<String>()
        for (index, step) in workflow.steps.enumerated() {
            if step.name.isEmpty {
                errors.append("Step \(index + 1) must have a name")
            } else if stepNames.contains(step.name) {
                errors.append("Duplicate step name: \(step.name)")
            } else {
                stepNames.insert(step.name)
            }

            if step.run.isEmpty {
                errors.append("Step '\(step.name)' must have a 'run' command")
            }

            if let timeout = step.timeout, timeout <= 0 {
                warnings.append("Step '\(step.name)' has invalid timeout: \(timeout)")
            }

            if let retries = step.retries, retries < 0 {
                warnings.append("Step '\(step.name)' has invalid retries: \(retries)")
            }

            // Check for variable references in output
            if let output = step.output {
                if output.contains(" ") || output.contains("-") {
                    warnings.append("Step '\(step.name)' output variable '\(output)' contains spaces or dashes")
                }
            }
        }

        // Check for referenced variables that might not exist
        for step in workflow.steps {
            let pattern = #"\{\{\s*(\w+)"#
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(step.run.startIndex..., in: step.run)
                let matches = regex.matches(in: step.run, range: range)
                for match in matches {
                    if let varRange = Range(match.range(at: 1), in: step.run) {
                        let varName = String(step.run[varRange])
                        // Check if this variable is defined by a previous step
                        let definedOutputs = workflow.steps.prefix(while: { $0.name != step.name }).compactMap { $0.output }
                        if !definedOutputs.contains(varName) && workflow.env?[varName] == nil {
                            warnings.append("Step '\(step.name)' references undefined variable '\(varName)'")
                        }
                    }
                }
            }
        }

        return ValidationResult(
            valid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }

    // MARK: - Execution

    public func run(
        workflow: Workflow,
        dryRun: Bool = false,
        verbose: Bool = false
    ) throws -> WorkflowResult {
        let startTime = Date()
        var context = ExecutionContext()
        var stepResults: [StepResult] = []
        var lastError: String?

        // Add workflow env to context
        if let env = workflow.env {
            for (key, value) in env {
                context.env[key] = value
            }
        }

        for step in workflow.steps {
            // Check condition
            if let condition = step.when {
                let shouldRun = evaluateCondition(condition, context: context)
                if !shouldRun {
                    stepResults.append(StepResult.skipped(name: step.name))
                    if verbose {
                        print("Skipping step '\(step.name)' (condition not met)")
                    }
                    continue
                }
            }

            if verbose {
                print("Running step: \(step.name)")
            }

            let result: StepResult
            if dryRun {
                result = StepResult(
                    name: step.name,
                    success: true,
                    exitCode: 0,
                    stdout: "[dry-run] Would execute: \(step.run)",
                    stderr: "",
                    duration: 0,
                    skipped: false
                )
            } else {
                result = try executeStep(step, context: &context)
            }

            stepResults.append(result)

            if !result.success {
                if step.continueOnError == true {
                    if verbose {
                        print("Step '\(step.name)' failed but continuing (continue_on_error: true)")
                    }
                } else {
                    lastError = "Step '\(step.name)' failed with exit code \(result.exitCode)"
                    break
                }
            }

            // Store output in context
            if let outputVar = step.output, result.success {
                // Try to parse as JSON first
                if let data = result.stdout.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) {
                    context.set(outputVar, value: json)
                } else {
                    context.set(outputVar, value: result.stdout)
                }
            }
        }

        let totalDuration = Date().timeIntervalSince(startTime)
        let allSucceeded = stepResults.allSatisfy { $0.success || $0.skipped }

        return WorkflowResult(
            workflow: workflow.name,
            success: allSucceeded && lastError == nil,
            totalDuration: totalDuration,
            steps: stepResults,
            error: lastError
        )
    }

    // MARK: - Private

    private func executeStep(_ step: Step, context: inout ExecutionContext) throws -> StepResult {
        let startTime = Date()
        let expandedCommand = expandTemplates(step.run, context: context)

        let shellType: ScriptRunner.ScriptType
        if let shell = step.shell {
            shellType = ScriptRunner.ScriptType(rawValue: shell) ?? .bash
        } else {
            shellType = .bash
        }

        let timeout = TimeInterval(step.timeout ?? 300)
        let maxRetries = step.retries ?? 0
        let retryDelay = step.retryDelay ?? 5

        var lastResult: ScriptRunner.ExecutionResult?
        var attempts = 0

        while attempts <= maxRetries {
            attempts += 1

            let runner = ScriptRunner()
            do {
                lastResult = try runner.runCode(
                    code: expandedCommand,
                    scriptType: shellType,
                    timeout: timeout,
                    env: context.env
                )

                if lastResult?.success == true {
                    break
                }

                if attempts <= maxRetries {
                    Thread.sleep(forTimeInterval: TimeInterval(retryDelay))
                }
            } catch {
                if attempts > maxRetries {
                    return StepResult(
                        name: step.name,
                        success: false,
                        exitCode: 1,
                        stdout: "",
                        stderr: error.localizedDescription,
                        duration: Date().timeIntervalSince(startTime),
                        skipped: false
                    )
                }
                Thread.sleep(forTimeInterval: TimeInterval(retryDelay))
            }
        }

        guard let result = lastResult else {
            return StepResult(
                name: step.name,
                success: false,
                exitCode: 1,
                stdout: "",
                stderr: "No result from execution",
                duration: Date().timeIntervalSince(startTime),
                skipped: false
            )
        }

        return StepResult(
            name: step.name,
            success: result.success,
            exitCode: result.exitCode,
            stdout: result.stdout,
            stderr: result.stderr,
            duration: Date().timeIntervalSince(startTime),
            skipped: false
        )
    }

    private func expandTemplates(_ template: String, context: ExecutionContext) -> String {
        var result = template

        // Simple template expansion: {{ variable_name }}
        let pattern = #"\{\{\s*(\w+)(?:\s*\|\s*(\w+))?\s*\}\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return result
        }

        let range = NSRange(result.startIndex..., in: result)
        let matches = regex.matches(in: result, range: range).reversed()

        for match in matches {
            guard let varRange = Range(match.range(at: 1), in: result) else { continue }
            let varName = String(result[varRange])

            var replacement: String
            if let value = context.get(varName) {
                replacement = stringValue(value)
            } else if let envValue = context.env[varName] {
                replacement = envValue
            } else {
                replacement = ""
            }

            // Apply filter if present
            if match.numberOfRanges > 2, let filterRange = Range(match.range(at: 2), in: result) {
                let filter = String(result[filterRange])
                replacement = applyFilter(filter, to: replacement, value: context.get(varName))
            }

            let fullRange = Range(match.range, in: result)!
            result.replaceSubrange(fullRange, with: replacement)
        }

        return result
    }

    private func stringValue(_ value: Any) -> String {
        if let str = value as? String {
            return str
        }
        if let arr = value as? [Any] {
            if let data = try? JSONSerialization.data(withJSONObject: arr),
               let str = String(data: data, encoding: .utf8) {
                return str
            }
            return String(describing: arr)
        }
        if let dict = value as? [String: Any] {
            if let data = try? JSONSerialization.data(withJSONObject: dict),
               let str = String(data: data, encoding: .utf8) {
                return str
            }
            return String(describing: dict)
        }
        return String(describing: value)
    }

    private func applyFilter(_ filter: String, to string: String, value: Any?) -> String {
        switch filter {
        case "length", "count":
            if let arr = value as? [Any] {
                return String(arr.count)
            }
            return String(string.count)
        case "upper":
            return string.uppercased()
        case "lower":
            return string.lowercased()
        case "trim":
            return string.trimmingCharacters(in: .whitespacesAndNewlines)
        case "first":
            if let arr = value as? [Any], let first = arr.first {
                return stringValue(first)
            }
            return String(string.first ?? Character(""))
        case "last":
            if let arr = value as? [Any], let last = arr.last {
                return stringValue(last)
            }
            return String(string.last ?? Character(""))
        case "json":
            if let val = value,
               let data = try? JSONSerialization.data(withJSONObject: val, options: .prettyPrinted),
               let str = String(data: data, encoding: .utf8) {
                return str
            }
            return string
        default:
            return string
        }
    }

    private func evaluateCondition(_ condition: String, context: ExecutionContext) -> Bool {
        let expanded = expandTemplates(condition, context: context)

        // Simple boolean checks
        if expanded.lowercased() == "true" { return true }
        if expanded.lowercased() == "false" { return false }

        // Check for empty string (variable was not set)
        if expanded.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return false }

        // Simple comparison: "var == value" or "var != value"
        if expanded.contains("==") {
            let parts = expanded.components(separatedBy: "==").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if parts.count == 2 {
                return parts[0] == parts[1]
            }
        }

        if expanded.contains("!=") {
            let parts = expanded.components(separatedBy: "!=").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            if parts.count == 2 {
                return parts[0] != parts[1]
            }
        }

        // Non-empty string is truthy
        return true
    }

    // MARK: - Workflow Discovery

    public func listWorkflows(in directory: String? = nil) throws -> [(path: String, workflow: Workflow)] {
        let searchDir: String
        if let dir = directory {
            searchDir = (dir as NSString).expandingTildeInPath
        } else {
            // Default to ~/.sysm/workflows/
            searchDir = (("~/.sysm/workflows") as NSString).expandingTildeInPath
        }

        guard FileManager.default.fileExists(atPath: searchDir) else {
            return []
        }

        let contents = try FileManager.default.contentsOfDirectory(atPath: searchDir)
        var workflows: [(String, Workflow)] = []

        for file in contents {
            let ext = (file as NSString).pathExtension.lowercased()
            guard ext == "yaml" || ext == "yml" else { continue }

            let fullPath = (searchDir as NSString).appendingPathComponent(file)
            do {
                let workflow = try load(path: fullPath)
                workflows.append((fullPath, workflow))
            } catch {
                fputs("Warning: Failed to load workflow '\(file)': \(error.localizedDescription)\n", stderr)
            }
        }

        return workflows.sorted { $0.1.name < $1.1.name }
    }

    // MARK: - Template Generation

    static let workflowTemplate = """
name: my-workflow
description: A new sysm workflow
version: "1.0.0"

# Optional triggers
# triggers:
#   - schedule: "0 9 * * *"  # 9 AM daily
#   - manual: true

# Optional environment variables
# env:
#   MY_VAR: "value"

steps:
  - name: hello
    run: echo "Hello from sysm workflow!"
    output: greeting

  - name: show-greeting
    run: echo "Previous step said: {{ greeting }}"

# Optional error handling
# on_error:
#   - notify: "Workflow failed: {{ error }}"
"""
}
