import ArgumentParser
import Foundation
import SysmCore

struct CaptureScreen: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "screen",
        abstract: "Capture the full screen"
    )

    @Option(name: .shortAndLong, help: "Output file path")
    var output: String = "~/Desktop/screenshot.png"

    @Option(name: .shortAndLong, help: "Display number (for multi-monitor)")
    var display: Int?

    func run() throws {
        let service = Services.screenCapture()
        try service.captureScreen(outputPath: output, display: display)
        let expanded = (output as NSString).expandingTildeInPath
        print("Screenshot saved to: \(expanded)")
    }
}
