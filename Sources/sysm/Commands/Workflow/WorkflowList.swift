import ArgumentParser
import Foundation
import SysmCore

struct WorkflowList: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List saved workflows"
    )

    // MARK: - Options

    @Option(name: .long, help: "Directory to search for workflows")
    var dir: String?

    @Flag(name: .long, help: "Output as JSON")
    var json: Bool = false

    @Flag(name: .shortAndLong, help: "Show detailed information")
    var verbose: Bool = false

    // MARK: - Execution

    func run() throws {
        let engine = Services.workflow()

        let workflows = try engine.listWorkflows(in: dir)

        if workflows.isEmpty {
            let searchDir = dir ?? "~/.sysm/workflows/"
            if json {
                print("[]")
            } else {
                print("No workflows found in \(searchDir)")
                print("\nCreate a workflow with: sysm workflow new <name>")
            }
            return
        }

        if json {
            var output: [[String: Any]] = []
            for (path, workflow) in workflows {
                var item: [String: Any] = [
                    "path": path,
                    "name": workflow.name,
                    "steps": workflow.steps.count
                ]
                if let desc = workflow.description {
                    item["description"] = desc
                }
                if let version = workflow.version {
                    item["version"] = version
                }
                if let triggers = workflow.triggers {
                    item["triggers"] = triggers.compactMap { trigger -> String? in
                        if let schedule = trigger.schedule {
                            return "schedule: \(schedule)"
                        }
                        if trigger.manual == true {
                            return "manual"
                        }
                        return trigger.event
                    }
                }
                output.append(item)
            }
            if let data = try? JSONSerialization.data(withJSONObject: output, options: .prettyPrinted),
               let str = String(data: data, encoding: .utf8) {
                print(str)
            }
        } else {
            print("Workflows (\(workflows.count)):\n")
            for (path, workflow) in workflows {
                print("  \(workflow.name)")
                if let desc = workflow.description {
                    print("    \(desc)")
                }
                if verbose {
                    print("    Path: \(path)")
                    print("    Steps: \(workflow.steps.count)")
                    if let version = workflow.version {
                        print("    Version: \(version)")
                    }
                    if let triggers = workflow.triggers, !triggers.isEmpty {
                        let triggerStrs = triggers.compactMap { trigger -> String? in
                            if let schedule = trigger.schedule {
                                return "schedule(\(schedule))"
                            }
                            if trigger.manual == true {
                                return "manual"
                            }
                            return trigger.event
                        }
                        print("    Triggers: \(triggerStrs.joined(separator: ", "))")
                    }
                }
                print("")
            }
        }
    }
}
