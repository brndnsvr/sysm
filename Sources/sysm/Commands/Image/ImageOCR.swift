import ArgumentParser
import Foundation
import SysmCore

struct ImageOCR: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ocr",
        abstract: "Extract text from an image"
    )

    @Argument(help: "Image path")
    var input: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.image()
        let text = try service.ocr(imagePath: input)

        if json {
            try OutputFormatter.printJSON(["text": text])
        } else {
            if text.isEmpty {
                print("No text detected in image")
            } else {
                print(text)
            }
        }
    }
}
