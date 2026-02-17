import ArgumentParser
import Foundation
import SysmCore

struct OutlookTasks: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tasks",
        abstract: "List Outlook tasks"
    )

    @Option(name: .long, help: "Filter by priority: high, normal, low")
    var priority: String?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.outlook()
        let tasks = try service.getTasks(priority: priority)

        if json {
            try OutputFormatter.printJSON(tasks)
        } else {
            if tasks.isEmpty {
                print("No tasks found")
            } else {
                let label = priority.map { "Tasks (\($0) priority)" } ?? "Tasks"
                print("Outlook \(label) (\(tasks.count)):\n")
                for task in tasks {
                    let status = task.isComplete ? "[x]" : "[ ]"
                    let due = task.dueDate.map { " (due: \($0))" } ?? ""
                    print("  \(status) [\(task.id)] \(task.name)\(due)")
                    print("       Priority: \(task.priority)")
                }
            }
        }
    }
}
