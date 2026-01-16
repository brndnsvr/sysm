import Foundation

/// Protocol defining workflow engine operations for YAML-based automation workflows.
///
/// Implementations provide workflow file loading, validation, and execution,
/// supporting multi-step automation with dry-run capabilities.
protocol WorkflowEngineProtocol {
    /// Lists all workflows in a directory.
    /// - Parameter directory: Optional directory to search (defaults to ~/.sysm/workflows).
    /// - Returns: Array of tuples with workflow path and parsed workflow.
    func listWorkflows(in directory: String?) throws -> [(path: String, workflow: WorkflowEngine.Workflow)]

    /// Loads a workflow from a file.
    /// - Parameter path: Path to the workflow YAML file.
    /// - Returns: The parsed workflow.
    func load(path: String) throws -> WorkflowEngine.Workflow

    /// Executes a workflow.
    /// - Parameters:
    ///   - workflow: The workflow to execute.
    ///   - dryRun: If true, simulates execution without making changes.
    ///   - verbose: If true, outputs detailed execution information.
    /// - Returns: Execution result with step outcomes.
    func run(workflow: WorkflowEngine.Workflow, dryRun: Bool, verbose: Bool) throws -> WorkflowEngine.WorkflowResult

    /// Validates a workflow for correctness.
    /// - Parameter workflow: The workflow to validate.
    /// - Returns: Validation result with any errors or warnings.
    func validate(workflow: WorkflowEngine.Workflow) -> WorkflowEngine.ValidationResult
}
