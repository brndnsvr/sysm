import ArgumentParser
import Foundation
import SysmCore

struct ImageMetadata_: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "metadata",
        abstract: "Show image metadata"
    )

    @Argument(help: "Image path")
    var input: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.image()
        let meta = try service.metadata(imagePath: input)

        if json {
            try OutputFormatter.printJSON(meta)
        } else {
            print("Image: \(meta.path)")
            print("  Dimensions: \(meta.width) x \(meta.height)")
            if let format = meta.format {
                print("  Format: \(format)")
            }
            print("  Size: \(meta.fileSizeFormatted)")
            if let colorSpace = meta.colorSpace {
                print("  Color Space: \(colorSpace)")
            }
            if let dpi = meta.dpi {
                print("  DPI: \(dpi)")
            }
            print("  Has Alpha: \(meta.hasAlpha ? "Yes" : "No")")
        }
    }
}
