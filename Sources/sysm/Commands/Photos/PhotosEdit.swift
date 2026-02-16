import ArgumentParser
import Foundation
import SysmCore

struct PhotosEdit: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "edit",
        abstract: "Edit photo title or description"
    )

    @Argument(help: "Asset ID (use 'sysm photos list --json' to find IDs)")
    var assetId: String

    @Option(name: .long, help: "Set the title")
    var title: String?

    @Option(name: .long, help: "Set the description/caption")
    var description: String?

    func validate() throws {
        if title == nil && description == nil {
            throw ValidationError("At least one of --title or --description is required")
        }
    }

    func run() async throws {
        let service = Services.photos()

        if let title = title {
            let success = try await service.setTitle(assetId: assetId, title: title)
            if success {
                print("Title set to: \(title)")
            } else {
                fputs("Failed to set title\n", stderr)
                throw ExitCode.failure
            }
        }

        if let description = description {
            let success = try await service.setDescription(assetId: assetId, description: description)
            if success {
                print("Description set to: \(description)")
            } else {
                fputs("Failed to set description\n", stderr)
                throw ExitCode.failure
            }
        }
    }
}
