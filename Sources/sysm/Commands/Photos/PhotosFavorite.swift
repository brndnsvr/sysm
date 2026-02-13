import ArgumentParser
import Foundation
import SysmCore

struct PhotosFavorite: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "favorite",
        abstract: "Mark photos as favorite or unfavorite"
    )

    @Argument(help: "Photo asset IDs")
    var assetIds: [String]

    @Flag(name: .long, help: "Remove from favorites instead of adding")
    var unfavorite = false

    func run() async throws {
        let service = Services.photos()

        var successCount = 0
        for assetId in assetIds {
            do {
                let success = try await service.setFavorite(assetId: assetId, isFavorite: !unfavorite)
                if success {
                    successCount += 1
                }
            } catch {
                fputs("Error processing \(assetId): \(error.localizedDescription)\n", stderr)
            }
        }

        if unfavorite {
            print("Removed \(successCount) photo(s) from favorites")
        } else {
            print("Marked \(successCount) photo(s) as favorite")
        }
    }
}
