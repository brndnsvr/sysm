import Foundation

/// Represents a YAML-defined automation workflow.
public struct Workflow: Codable, Sendable {
    public let name: String
    public let description: String?
    public let version: String?
    public let author: String?
    public let triggers: [WorkflowTrigger]?
    public let env: [String: String]?
    public let steps: [WorkflowStep]
    public let onError: [WorkflowErrorHandler]?

    enum CodingKeys: String, CodingKey {
        case name, description, version, author, triggers, env, steps
        case onError = "on_error"
    }

    public init(
        name: String,
        description: String? = nil,
        version: String? = nil,
        author: String? = nil,
        triggers: [WorkflowTrigger]? = nil,
        env: [String: String]? = nil,
        steps: [WorkflowStep],
        onError: [WorkflowErrorHandler]? = nil
    ) {
        self.name = name
        self.description = description
        self.version = version
        self.author = author
        self.triggers = triggers
        self.env = env
        self.steps = steps
        self.onError = onError
    }
}

/// Trigger configuration for a workflow.
public struct WorkflowTrigger: Codable, Sendable {
    public let schedule: String?
    public let manual: Bool?
    public let event: String?

    public init(schedule: String? = nil, manual: Bool? = nil, event: String? = nil) {
        self.schedule = schedule
        self.manual = manual
        self.event = event
    }
}

/// A single step in a workflow.
public struct WorkflowStep: Codable, Sendable {
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

    public init(
        name: String,
        run: String,
        shell: String? = nil,
        output: String? = nil,
        when: String? = nil,
        timeout: Int? = nil,
        continueOnError: Bool? = nil,
        retries: Int? = nil,
        retryDelay: Int? = nil
    ) {
        self.name = name
        self.run = run
        self.shell = shell
        self.output = output
        self.when = when
        self.timeout = timeout
        self.continueOnError = continueOnError
        self.retries = retries
        self.retryDelay = retryDelay
    }
}

/// Error handler configuration for a workflow.
public struct WorkflowErrorHandler: Codable, Sendable {
    public let notify: String?
    public let run: String?

    public init(notify: String? = nil, run: String? = nil) {
        self.notify = notify
        self.run = run
    }
}

/// Execution context holding variables and environment during workflow execution.
public struct WorkflowExecutionContext: Sendable {
    public var variables: [String: String]
    public var env: [String: String]
    public var workingDirectory: String

    public init(workingDirectory: String = FileManager.default.currentDirectoryPath) {
        self.variables = [:]
        self.env = ProcessInfo.processInfo.environment
        self.workingDirectory = workingDirectory
    }

    public mutating func set(_ key: String, value: String) {
        variables[key] = value
    }

    public func get(_ key: String) -> String? {
        return variables[key]
    }
}

/// Result of executing a single workflow step.
public struct WorkflowStepResult: Codable, Sendable {
    public let name: String
    public let success: Bool
    public let exitCode: Int32
    public let stdout: String
    public let stderr: String
    public let duration: Double
    public let skipped: Bool

    public init(
        name: String,
        success: Bool,
        exitCode: Int32,
        stdout: String,
        stderr: String,
        duration: Double,
        skipped: Bool
    ) {
        self.name = name
        self.success = success
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
        self.duration = duration
        self.skipped = skipped
    }

    public static func skipped(name: String) -> WorkflowStepResult {
        return WorkflowStepResult(
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

/// Result of executing an entire workflow.
public struct WorkflowResult: Codable, Sendable {
    public let workflow: String
    public let success: Bool
    public let totalDuration: Double
    public let steps: [WorkflowStepResult]
    public let error: String?

    public init(
        workflow: String,
        success: Bool,
        totalDuration: Double,
        steps: [WorkflowStepResult],
        error: String?
    ) {
        self.workflow = workflow
        self.success = success
        self.totalDuration = totalDuration
        self.steps = steps
        self.error = error
    }

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

/// Result of validating a workflow.
public struct WorkflowValidationResult: Sendable {
    public let valid: Bool
    public let errors: [String]
    public let warnings: [String]

    public init(valid: Bool, errors: [String], warnings: [String]) {
        self.valid = valid
        self.errors = errors
        self.warnings = warnings
    }

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

/// Errors that can occur during workflow operations.
public enum WorkflowError: LocalizedError, Sendable {
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
