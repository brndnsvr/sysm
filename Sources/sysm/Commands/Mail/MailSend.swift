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

    @Option(name: .long, help: "Email body (plain text)")
    var body: String = ""

    @Option(name: .long, help: "HTML email body")
    var htmlBody: String?

    @Option(name: .long, help: "Path to HTML file for body")
    var htmlFile: String?

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

        // Validate HTML options
        if htmlBody != nil && htmlFile != nil {
            throw MailError.sendFailed("Cannot specify both --html-body and --html-file")
        }

        // Determine body content and type
        let finalBody: String
        let isHTML: Bool

        if let htmlBodyContent = htmlBody {
            finalBody = htmlBodyContent
            isHTML = true
        } else if let htmlFilePath = htmlFile {
            let expandedPath = (htmlFilePath as NSString).expandingTildeInPath
            guard let htmlContent = try? String(contentsOfFile: expandedPath, encoding: .utf8) else {
                throw MailError.sendFailed("Failed to read HTML file: \(expandedPath)")
            }
            finalBody = htmlContent
            isHTML = true
        } else if !body.isEmpty {
            finalBody = body
            isHTML = false
        } else {
            throw MailError.sendFailed("Must specify either --body, --html-body, or --html-file")
        }

        if !force {
            print("Send email to '\(to)'")
            print("Subject: \(subject)")
            print("Body type: \(isHTML ? "HTML" : "plain text")")
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

        try service.sendMessage(
            to: to,
            cc: cc,
            bcc: bcc,
            subject: subject,
            body: finalBody,
            isHTML: isHTML,
            accountName: account
        )
        print("Message sent")
    }
}
