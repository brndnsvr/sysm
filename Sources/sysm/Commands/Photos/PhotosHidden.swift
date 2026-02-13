import ArgumentParser
import Foundation
import SysmCore

struct PhotosHidden: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "hidden",
        abstract: "Hide or unhide photos"
    )

    @Argument(help: "Photo asset IDs")
    var assetIds: [String]

    @Flag(name: .long, help: "Unhide photos instead of hiding")
    var unhide = false

    func run() async throws {
        let service = Services.photos()

        var successCount = 0
        for assetId in assetIds {
            do {
                let success = try await service.setHidden(assetId: assetId, isHidden: !unhide)
                if success {
                    successCount += 1
                }
            } catch {
                fputs("Error processing \(assetId): \(error.localizedDescription)\n", stderr)
            }
        }

        if unhide {
            print("Unhid \(successCount) photo(s)")
        } else {
            print("Hid \(successCount) photo(s)")
        }
    }
}
