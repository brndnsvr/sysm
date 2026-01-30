import ArgumentParser
import Foundation
import SysmCore

struct MailRead: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "read",
        abstract: "Read a specific message"
    )

    @Argument(help: "Message ID")
    var id: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.mail()

        guard let message = try service.getMessage(id: id) else {
            fputs("Message not found: \(id)\n", stderr)
            throw ExitCode.failure
        }

        if json {
            try OutputFormatter.printJSON(message)
        } else {
            // Status indicators
            var status: [String] = []
            if !message.isRead { status.append("Unread") }
            if message.isFlagged { status.append("Flagged") }
            if !status.isEmpty {
                print("Status: \(status.joined(separator: ", "))")
            }

            print("Subject: \(message.subject)")
            print("From: \(message.from)")
            print("To: \(message.to)")
            if let cc = message.cc {
                print("CC: \(cc)")
            }
            if let replyTo = message.replyTo {
                print("Reply-To: \(replyTo)")
            }
            print("Date: \(message.dateReceived)")
            if let dateSent = message.dateSent, dateSent != message.dateReceived {
                print("Sent: \(dateSent)")
            }
            if let mailbox = message.mailbox {
                var location = mailbox
                if let account = message.accountName {
                    location = "\(account)/\(mailbox)"
                }
                print("Mailbox: \(location)")
            }
            if !message.attachments.isEmpty {
                print("Attachments: \(message.attachments.count)")
                for att in message.attachments {
                    let sizeStr = formatFileSize(att.size)
                    print("  - \(att.name) (\(att.mimeType), \(sizeStr))")
                }
            }
            print(String(repeating: "-", count: 60))
            print(message.content)
        }
    }

    private func formatFileSize(_ bytes: Int) -> String {
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024)
        } else {
            return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
        }
    }
}
