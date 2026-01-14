import ArgumentParser
import Foundation

struct WorkflowCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "workflow",
        abstract: "Define and run multi-step automations",
        discussion: """
        Create and execute YAML-based workflows that chain sysm commands
        and shell scripts together.

        Workflows support:
        - Variable passing between steps
        - Conditional execution
        - Error handling and retries
        - Template expansion

        Examples:
          sysm workflow run morning.yaml
          sysm workflow validate my-workflow.yaml
          sysm workflow list
          sysm workflow new backup-routine
        """,
        subcommands: [
            WorkflowRun.self,
            WorkflowValidate.self,
            WorkflowList.self,
            WorkflowNew.self,
        ],
        defaultSubcommand: WorkflowRun.self
    )
}
