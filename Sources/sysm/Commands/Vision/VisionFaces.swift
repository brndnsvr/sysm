import ArgumentParser
import Foundation
import SysmCore

struct VisionFaces: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "faces",
        abstract: "Detect faces in an image"
    )

    @Argument(help: "Image path")
    var image: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.vision()
        let results = try service.detectFaces(imagePath: image)

        if json {
            try OutputFormatter.printJSON(results)
        } else {
            if results.isEmpty {
                print("No faces detected")
            } else {
                print("Found \(results.count) face(s)")
                for (i, face) in results.enumerated() {
                    let confidence = String(format: "%.1f%%", face.confidence * 100)
                    let roll = face.roll.map { String(format: "%.2f", $0) } ?? "N/A"
                    let yaw = face.yaw.map { String(format: "%.2f", $0) } ?? "N/A"
                    print("  Face \(i + 1): confidence \(confidence), roll: \(roll), yaw: \(yaw)")
                }
            }
        }
    }
}
