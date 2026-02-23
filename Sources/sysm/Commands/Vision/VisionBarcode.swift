import ArgumentParser
import Foundation
import SysmCore

struct VisionBarcode: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "barcode",
        abstract: "Detect barcodes in an image"
    )

    @Argument(help: "Image path")
    var image: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.vision()
        let results = try service.detectBarcodes(imagePath: image)

        if json {
            try OutputFormatter.printJSON(results)
        } else {
            if results.isEmpty {
                print("No barcodes detected")
            } else {
                for barcode in results {
                    print("  [\(barcode.symbology)] \(barcode.payload ?? "(no payload)")")
                }
            }
        }
    }
}
