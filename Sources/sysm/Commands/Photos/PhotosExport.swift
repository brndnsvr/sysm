import ArgumentParser
import Foundation
import SysmCore

struct PhotosExport: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "export",
        abstract: "Export a photo or video to a file"
    )

    @Argument(help: "Asset ID (use 'recent', 'list', or 'videos' to find IDs)")
    var assetId: String

    @Option(name: .shortAndLong, help: "Output file path")
    var output: String?

    @Flag(name: .long, help: "Export as video (for video assets)")
    var video = false

    func run() async throws {
        let service = Services.photos()

        // Get metadata to determine asset type if not specified
        let metadata = try await service.getMetadata(assetId: assetId)
        let isVideo = video || metadata.mediaType == "Video"

        let outputPath: String
        if let output = output {
            outputPath = NSString(string: output).expandingTildeInPath
        } else {
            // Default to current directory with original filename
            let filename = metadata.filename
            outputPath = FileManager.default.currentDirectoryPath + "/\(filename)"
        }

        if isVideo {
            try await service.exportVideo(assetId: assetId, outputPath: outputPath)
            print("Exported video to: \(outputPath)")
        } else {
            try await service.exportPhoto(assetId: assetId, outputPath: outputPath)
            print("Exported photo to: \(outputPath)")
        }
    }
}
