import ArgumentParser
import Foundation
import SysmCore

struct AIPrompt: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "prompt",
        abstract: "Send a prompt to Apple Intelligence"
    )

    @Argument(help: "Prompt text")
    var text: String

    @Option(name: .long, help: "System prompt for context")
    var system: String?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.foundationModels()
        let response = try await service.prompt(text: text, systemPrompt: system)

        if json {
            try OutputFormatter.printJSON(response)
        } else {
            print(response.content)
        }
    }
}
