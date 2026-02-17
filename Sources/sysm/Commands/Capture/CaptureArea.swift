import ArgumentParser
import Foundation
import SysmCore

struct CaptureArea: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "area",
        abstract: "Capture a screen area"
    )

    @Option(name: .shortAndLong, help: "Output file path")
    var output: String = "~/Desktop/screenshot.png"

    @Option(name: .long, help: "Rectangle as x,y,width,height (interactive if omitted)")
    var rect: String?

    func run() throws {
        let service = Services.screenCapture()

        var captureRect: CaptureRect?
        if let rectStr = rect {
            let parts = rectStr.split(separator: ",").compactMap { Int($0) }
            guard parts.count == 4 else {
                throw ValidationError("Rectangle must be in format: x,y,width,height")
            }
            captureRect = CaptureRect(x: parts[0], y: parts[1], width: parts[2], height: parts[3])
        }

        if captureRect == nil {
            print("Select an area to capture...")
        }
        try service.captureArea(outputPath: output, rect: captureRect)
        let expanded = (output as NSString).expandingTildeInPath
        print("Screenshot saved to: \(expanded)")
    }
}
