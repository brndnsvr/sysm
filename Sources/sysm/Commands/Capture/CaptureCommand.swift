import ArgumentParser
import SysmCore

struct CaptureCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "capture",
        abstract: "Take screenshots",
        subcommands: [
            CaptureScreen.self,
            CaptureWindow.self,
            CaptureArea.self,
        ]
    )
}
