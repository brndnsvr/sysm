import ArgumentParser
import Foundation
import SysmCore

struct CaptureWindow: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "window",
        abstract: "Capture a window (interactive selection)"
    )

    @Option(name: .shortAndLong, help: "Output file path")
    var output: String = "~/Desktop/screenshot.png"

    func run() throws {
        let service = Services.screenCapture()
        print("Click on a window to capture it...")
        try service.captureWindow(outputPath: output, title: nil)
        let expanded = (output as NSString).expandingTildeInPath
        print("Screenshot saved to: \(expanded)")
    }
}
