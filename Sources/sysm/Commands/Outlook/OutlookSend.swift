import ArgumentParser
import Foundation
import SysmCore

struct OutlookSend: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "send",
        abstract: "Send an email via Outlook"
    )

    @Option(name: .long, help: "Recipient email address (repeatable)")
    var to: [String]

    @Option(name: .long, help: "CC recipient (repeatable)")
    var cc: [String] = []

    @Option(name: .long, help: "Email subject")
    var subject: String

    @Option(name: .long, help: "Email body")
    var body: String

    @Flag(name: .shortAndLong, help: "Skip confirmation")
    var force = false

    func run() throws {
        if !force {
            print("To:      \(to.joined(separator: ", "))")
            if !cc.isEmpty { print("Cc:      \(cc.joined(separator: ", "))") }
            print("Subject: \(subject)")
            print("Body:    \(body.prefix(100))\(body.count > 100 ? "..." : "")")
            guard CLI.confirm("\nSend this message via Outlook? [y/N] ") else { return }
        }

        let service = Services.outlook()
        try service.send(to: to, cc: cc, subject: subject, body: body)
        print("Message sent via Outlook")
    }
}
