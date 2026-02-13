import Foundation

/// Protocol defining workflow engine operations for YAML-based automation workflows.
///
/// This protocol provides workflow file loading, parsing, validation, and execution capabilities
/// for YAML-defined automation workflows. Supports multi-step workflows with variable substitution,
/// conditional logic, and dry-run mode for safe testing.
///
/// ## Workflow Format
///
/// Workflows are defined in YAML files (`~/.sysm/workflows/*.yml`) with:
/// - Metadata (name, description, version)
/// - Variables for parameterization
/// - Steps with actions and parameters
/// - Conditional execution logic
///
/// ## Usage Example
///
/// ```swift
/// let engine = WorkflowEngine()
///
/// // List available workflows
/// let workflows = try engine.listWorkflows(in: nil)
/// for (path, workflow) in workflows {
///     print("\(workflow.name): \(workflow.description ?? "")")
/// }
///
/// // Load and validate
/// let workflow = try engine.load(path: "~/.sysm/workflows/backup.yml")
/// let validation = engine.validate(workflow: workflow)
/// if !validation.isValid {
///     print("Errors: \(validation.errors)")
/// }
///
/// // Execute with dry-run
/// let dryResult = try engine.run(workflow: workflow, dryRun: true, verbose: true)
/// print("Would execute \(dryResult.steps.count) steps")
///
/// // Execute for real
/// let result = try engine.run(workflow: workflow, dryRun: false, verbose: false)
/// print("Success: \(result.success)")
/// ```
///
/// ## Thread Safety
///
/// Implementations are marked as `Sendable` and safe to use across actor boundaries.
/// Workflow execution is synchronous.
///
/// ## Error Handling
///
/// Methods can throw ``WorkflowError`` variants:
/// - ``WorkflowError/fileNotFound(_:)`` - Workflow file doesn't exist
/// - ``WorkflowError/parseError(_:)`` - YAML parsing failed
/// - ``WorkflowError/validationError(_:)`` - Workflow validation failed
/// - ``WorkflowError/executionFailed(_:step:)`` - Step execution failed
/// - ``WorkflowError/missingVariable(_:)`` - Required variable not provided
///
public protocol WorkflowEngineProtocol: Sendable {
    // MARK: - Discovery

    /// Lists all workflows in a directory.
    ///
    /// Scans the specified directory (or default `~/.sysm/workflows/`) for YAML workflow files
    /// and parses them.
    ///
    /// - Parameter directory: Optional directory to search. If nil, uses `~/.sysm/workflows`.
    /// - Returns: Array of tuples containing file path and parsed ``Workflow`` object.
    /// - Throws:
    ///   - ``WorkflowError/parseError(_:)`` if any workflow file has invalid YAML.
    ///   - File system errors if directory doesn't exist or isn't readable.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let workflows = try engine.listWorkflows(in: "~/my-workflows")
    /// print("Found \(workflows.count) workflows:")
    /// for (path, workflow) in workflows {
    ///     print("  - \(workflow.name) (\(path))")
    /// }
    /// ```
    func listWorkflows(in directory: String?) throws -> [(path: String, workflow: Workflow)]

    // MARK: - Loading & Parsing

    /// Loads a workflow from a file.
    ///
    /// Reads and parses a YAML workflow file.
    ///
    /// - Parameter path: Path to the workflow YAML file (absolute or relative).
    /// - Returns: The parsed ``Workflow`` object.
    /// - Throws:
    ///   - ``WorkflowError/fileNotFound(_:)`` if file doesn't exist.
    ///   - ``WorkflowError/parseError(_:)`` if YAML is invalid.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let workflow = try engine.load(path: "~/.sysm/workflows/deploy.yml")
    /// print("Loaded: \(workflow.name)")
    /// print("Steps: \(workflow.steps.count)")
    /// ```
    func load(path: String) throws -> Workflow

    /// Parses a workflow from YAML content.
    ///
    /// Parses workflow from a YAML string directly, useful for testing or generating
    /// workflows programmatically.
    ///
    /// - Parameter yaml: The YAML content as a string.
    /// - Returns: The parsed ``Workflow`` object.
    /// - Throws: ``WorkflowError/parseError(_:)`` if YAML is invalid.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let yamlContent = """
    /// name: Test Workflow
    /// description: Example workflow
    /// steps:
    ///   - name: Step 1
    ///     action: shell
    ///     params:
    ///       command: echo "Hello"
    /// """
    /// let workflow = try engine.parse(yaml: yamlContent)
    /// ```
    func parse(yaml: String) throws -> Workflow

    // MARK: - Validation

    /// Validates a workflow for correctness.
    ///
    /// Checks the workflow for:
    /// - Required fields (name, steps)
    /// - Valid action types
    /// - Parameter completeness
    /// - Variable references
    /// - Conditional logic syntax
    ///
    /// - Parameter workflow: The workflow to validate.
    /// - Returns: ``WorkflowValidationResult`` with errors and warnings.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let workflow = try engine.load(path: "workflow.yml")
    /// let validation = engine.validate(workflow: workflow)
    ///
    /// if validation.isValid {
    ///     print("Workflow is valid")
    /// } else {
    ///     print("Validation errors:")
    ///     for error in validation.errors {
    ///         print("  - \(error)")
    ///     }
    /// }
    ///
    /// if !validation.warnings.isEmpty {
    ///     print("Warnings:")
    ///     for warning in validation.warnings {
    ///         print("  - \(warning)")
    ///     }
    /// }
    /// ```
    func validate(workflow: Workflow) -> WorkflowValidationResult

    // MARK: - Execution

    /// Executes a workflow.
    ///
    /// Runs all steps in the workflow sequentially. Supports dry-run mode to simulate
    /// execution without making actual changes. Verbose mode provides detailed execution logs.
    ///
    /// - Parameters:
    ///   - workflow: The workflow to execute.
    ///   - dryRun: If true, simulates execution without making changes (reads are still performed).
    ///   - verbose: If true, outputs detailed execution information to stdout.
    /// - Returns: ``WorkflowResult`` with execution outcome and step results.
    /// - Throws:
    ///   - ``WorkflowError/validationError(_:)`` if workflow fails validation.
    ///   - ``WorkflowError/executionFailed(_:step:)`` if a step fails and workflow has no error handling.
    ///   - ``WorkflowError/missingVariable(_:)`` if required variable not provided.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let workflow = try engine.load(path: "deploy.yml")
    ///
    /// // Test with dry-run first
    /// let dryResult = try engine.run(
    ///     workflow: workflow,
    ///     dryRun: true,
    ///     verbose: true
    /// )
    /// print("Dry run: \(dryResult.success ? "OK" : "Failed")")
    ///
    /// // Execute for real if dry-run succeeded
    /// if dryResult.success {
    ///     let result = try engine.run(
    ///         workflow: workflow,
    ///         dryRun: false,
    ///         verbose: false
    ///     )
    ///     print("Execution: \(result.success ? "Success" : "Failed")")
    ///     print("Duration: \(result.duration)s")
    ///     print("Steps completed: \(result.stepsCompleted)/\(result.totalSteps)")
    /// }
    /// ```
    ///
    /// ## Step Execution
    ///
    /// Steps are executed in order. If a step fails:
    /// - Workflow stops unless error handling is configured
    /// - All completed steps are recorded in the result
    /// - Error details are included in the result
    func run(workflow: Workflow, dryRun: Bool, verbose: Bool) throws -> WorkflowResult
}
