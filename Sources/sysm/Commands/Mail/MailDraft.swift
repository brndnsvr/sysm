import ArgumentParser
import Foundation
import SysmCore

struct MailDraft: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "draft",
        abstract: "Manage email drafts",
        subcommands: [
            Create.self,
            List.self,
            Delete.self,
        ],
        defaultSubcommand: Create.self
    )

    struct Create: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "create",
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

    struct List: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "list",
            abstract: "List all draft messages"
        )

        @Flag(name: .shortAndLong, help: "Output as JSON")
        var json: Bool = false

        func run() throws {
            let service = Services.mail()
            let drafts = try service.listDrafts()

            if json {
                try OutputFormatter.printJSON(drafts)
            } else {
                if drafts.isEmpty {
                    print("No drafts")
                } else {
                    print("Drafts (\(drafts.count)):")
                    for draft in drafts {
                        let to = draft.from.isEmpty ? "[no recipient]" : draft.from
                        print("  [\(draft.id)] \(draft.subject) → \(to)")
                    }
                }
            }
        }
    }

    struct Delete: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "delete",
            abstract: "Delete a draft message"
        )

        @Argument(help: "Draft message ID")
        var messageId: String

        func run() throws {
            let service = Services.mail()
            try service.deleteDraft(messageId: messageId)
            print("Draft deleted")
        }
    }
}
