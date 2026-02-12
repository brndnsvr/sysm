import ArgumentParser
import Foundation
import SysmCore

struct MailAttachments: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "attachments",
        abstract: "Manage email attachments",
        subcommands: [
            List.self,
            Download.self,
        ]
    )

    struct List: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "list",
            abstract: "List attachments for a message"
        )

        @Argument(help: "Message ID")
        var messageId: String

        @Flag(name: .shortAndLong, help: "Output as JSON")
        var json: Bool = false

        func run() throws {
            let service = Services.mail()
            guard let message = try service.getMessage(id: messageId) else {
                throw MailError.messageNotFound(messageId)
            }

            if json {
                try OutputFormatter.printJSON(message.attachments)
            } else {
                if message.attachments.isEmpty {
                    print("No attachments")
                } else {
                    print("Attachments (\(message.attachments.count)):")
                    for attachment in message.attachments {
                        let sizeStr = attachment.size > 0 ? formatBytes(attachment.size) : "unknown"
                        print("  \(attachment.name) (\(sizeStr)) - \(attachment.mimeType)")
                    }
                }
            }
        }

        private func formatBytes(_ bytes: Int) -> String {
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useKB, .useMB, .useGB]
            formatter.countStyle = .file
            return formatter.string(fromByteCount: Int64(bytes))
        }
    }

    struct Download: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "download",
            abstract: "Download all attachments from a message"
        )

        @Argument(help: "Message ID")
        var messageId: String

        @Option(name: .long, help: "Output directory path")
        var outputDir: String = "."

        @Flag(name: .shortAndLong, help: "Output as JSON")
        var json: Bool = false

        struct DownloadResult: Codable {
            let files: [String]
            let count: Int
        }

        func run() throws {
            let service = Services.mail()

            // Expand tilde in path
            let expandedPath = (outputDir as NSString).expandingTildeInPath

            let downloadedFiles = try service.downloadAttachments(
                messageId: messageId,
                outputDir: expandedPath
            )

            if json {
                let result = DownloadResult(files: downloadedFiles, count: downloadedFiles.count)
                try OutputFormatter.printJSON(result)
            } else {
                if downloadedFiles.isEmpty {
                    print("No attachments to download")
                } else {
                    print("Downloaded \(downloadedFiles.count) attachment(s):")
                    for file in downloadedFiles {
                        print("  \(file)")
                    }
                }
            }
        }
    }
}
