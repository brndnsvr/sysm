import ArgumentParser
import Foundation

struct MailDraft: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "draft",
        abstract: "Create a new email draft (opens Mail.app)"
    )

    @Option(name: .long, help: "Recipient email address")
    var to: String?

    @Option(name: .long, help: "Email subject")
    var subject: String?

    @Option(name: .long, help: "Email body")
    var body: String?

    func run() throws {
        let service = Services.mail()
        try service.createDraft(to: to, subject: subject, body: body)
        print("Draft created and Mail.app opened")
    }
}
