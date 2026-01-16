import ArgumentParser
import Foundation

struct FocusStatus: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Show current Focus mode status"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.focus()
        let status = try service.getStatus()

        if json {
            try OutputFormatter.printJSON(status)
        } else {
            if status.isActive {
                if let activeFocus = status.activeFocus {
                    print("Focus: \(activeFocus) (active)")
                } else if status.dndEnabled {
                    print("Focus: Do Not Disturb (active)")
                } else {
                    print("Focus: Active (unknown mode)")
                }
            } else {
                print("Focus: Off")
            }
        }
    }
}
