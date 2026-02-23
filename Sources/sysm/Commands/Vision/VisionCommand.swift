import ArgumentParser
import SysmCore

struct VisionCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "vision",
        abstract: "Image analysis with Vision framework",
        subcommands: [
            VisionBarcode.self,
            VisionFaces.self,
            VisionClassify.self,
            VisionRectangles.self,
        ]
    )
}
