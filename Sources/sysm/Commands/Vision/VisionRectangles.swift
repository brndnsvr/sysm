import ArgumentParser
import Foundation
import SysmCore

struct VisionRectangles: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "rectangles",
        abstract: "Detect rectangles in an image"
    )

    @Argument(help: "Image path")
    var image: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.vision()
        let results = try service.detectRectangles(imagePath: image)

        if json {
            try OutputFormatter.printJSON(results)
        } else {
            if results.isEmpty {
                print("No rectangles detected")
            } else {
                print("Found \(results.count) rectangle(s)")
                for (i, rect) in results.enumerated() {
                    let box = rect.boundingBox
                    let confidence = String(format: "%.1f%%", rect.confidence * 100)
                    print("  Rectangle \(i + 1): (\(String(format: "%.3f", box.x)), \(String(format: "%.3f", box.y))) \(String(format: "%.3f", box.width))x\(String(format: "%.3f", box.height)) confidence \(confidence)")
                }
            }
        }
    }
}
