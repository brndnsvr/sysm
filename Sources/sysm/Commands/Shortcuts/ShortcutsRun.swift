import ArgumentParser
import Foundation

struct ShortcutsRun: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Run a shortcut by name"
    )

    @Argument(help: "Name of the shortcut to run")
    var name: String

    @Option(name: .long, help: "Input text to pass to the shortcut")
    var input: String?

    @Flag(name: .long, help: "Suppress output")
    var quiet = false

    func run() throws {
        let service = ShortcutsService()
        let output = try service.run(name: name, input: input)

        if !quiet {
            if output.isEmpty {
                print("Shortcut '\(name)' completed")
            } else {
                print(output)
            }
        }
    }
}
