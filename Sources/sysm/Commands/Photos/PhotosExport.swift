import ArgumentParser
import Foundation
import SysmCore

struct PhotosExport: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "export",
        abstract: "Export a photo to a file"
    )

    @Argument(help: "Photo asset ID (use 'recent' or 'list' to find)")
    var assetId: String

    @Option(name: .shortAndLong, help: "Output file path")
    var output: String?

    func run() async throws {
        let service = Services.photos()

        let outputPath: String
        if let output = output {
            outputPath = NSString(string: output).expandingTildeInPath
        } else {
            // Default to current directory with asset ID
            let sanitizedId = assetId.replacingOccurrences(of: "/", with: "_")
            outputPath = FileManager.default.currentDirectoryPath + "/\(sanitizedId).jpg"
        }

        try await service.exportPhoto(assetId: assetId, outputPath: outputPath)
        print("Exported photo to: \(outputPath)")
    }
}
