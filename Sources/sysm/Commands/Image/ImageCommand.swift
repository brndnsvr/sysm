import ArgumentParser
import SysmCore

struct ImageCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "image",
        abstract: "Image processing and analysis",
        subcommands: [
            ImageResize.self,
            ImageConvert.self,
            ImageOCR.self,
            ImageMetadata_.self,
            ImageThumbnail.self,
        ]
    )
}
