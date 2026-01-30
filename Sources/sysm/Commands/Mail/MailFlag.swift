import ArgumentParser
import Foundation
import SysmCore

struct MailFlag: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "flag",
        abstract: "Flag or unflag a message"
    )

    @Argument(help: "Message ID")
    var id: String

    @Flag(name: .long, help: "Flag the message")
    var flag = false

    @Flag(name: .long, help: "Unflag the message")
    var unflag = false

    func validate() throws {
        if flag == unflag {
            throw ValidationError("Specify either --flag or --unflag")
        }
    }

    func run() throws {
        let service = Services.mail()

        do {
            try service.flagMessage(id: id, flagged: flag)
            print("Message \(flag ? "flagged" : "unflagged")")
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }
}
