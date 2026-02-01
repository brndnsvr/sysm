import Foundation

/// Protocol defining workflow engine operations for YAML-based automation workflows.
///
/// Implementations provide workflow file loading, validation, and execution,
/// supporting multi-step automation with dry-run capabilities.
public protocol WorkflowEngineProtocol: Sendable {
    /// Lists all workflows in a directory.
    /// - Parameter directory: Optional directory to search (defaults to ~/.sysm/workflows).
    /// - Returns: Array of tuples with workflow path and parsed workflow.
    func listWorkflows(in directory: String?) throws -> [(path: String, workflow: Workflow)]

    /// Loads a workflow from a file.
    /// - Parameter path: Path to the workflow YAML file.
    /// - Returns: The parsed workflow.
    func load(path: String) throws -> Workflow

    /// Parses a workflow from YAML content.
    /// - Parameter yaml: The YAML content to parse.
    /// - Returns: The parsed workflow.
    func parse(yaml: String) throws -> Workflow

    /// Executes a workflow.
    /// - Parameters:
    ///   - workflow: The workflow to execute.
    ///   - dryRun: If true, simulates execution without making changes.
    ///   - verbose: If true, outputs detailed execution information.
    /// - Returns: Execution result with step outcomes.
    func run(workflow: Workflow, dryRun: Bool, verbose: Bool) throws -> WorkflowResult

    /// Validates a workflow for correctness.
    /// - Parameter workflow: The workflow to validate.
    /// - Returns: Validation result with any errors or warnings.
    func validate(workflow: Workflow) -> WorkflowValidationResult
}
