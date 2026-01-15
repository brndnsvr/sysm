import Foundation

/// Protocol for workflow engine operations
protocol WorkflowEngineProtocol {
    func listWorkflows(in directory: String?) throws -> [(path: String, workflow: WorkflowEngine.Workflow)]
    func load(path: String) throws -> WorkflowEngine.Workflow
    func run(workflow: WorkflowEngine.Workflow, dryRun: Bool, verbose: Bool) throws -> WorkflowEngine.WorkflowResult
    func validate(workflow: WorkflowEngine.Workflow) -> WorkflowEngine.ValidationResult
}
