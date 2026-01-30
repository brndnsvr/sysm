import ArgumentParser
import Foundation
import SysmCore

struct MailSend: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "send",
        abstract: "Send an email message"
    )

    @Option(name: .long, help: "Recipient email address")
    var to: String

    @Option(name: .long, help: "Email subject")
    var subject: String

    @Option(name: .long, help: "Email body")
    var body: String = ""

    @Option(name: .long, help: "CC recipient email address")
    var cc: String?

    @Option(name: .long, help: "BCC recipient email address")
    var bcc: String?

    @Option(name: .long, help: "Send from account name")
    var account: String?

    @Flag(name: .shortAndLong, help: "Skip confirmation prompt")
    var force: Bool = false

    func run() throws {
        let service = Services.mail()

        if !force {
            print("Send email to '\(to)'")
            print("Subject: \(subject)")
            if let cc = cc {
                print("CC: \(cc)")
            }
            if let bcc = bcc {
                print("BCC: \(bcc)")
            }
            print("\nSend this message? [y/N]: ", terminator: "")

            guard let response = readLine(), response.lowercased() == "y" else {
                print("Cancelled")
                return
            }
        }

        do {
            try service.sendMessage(
                to: to,
                cc: cc,
                bcc: bcc,
                subject: subject,
                body: body,
                accountName: account
            )
            print("Message sent")
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }
}
