import ArgumentParser
import Foundation
import SysmCore

struct NotesFolders: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "folders",
        abstract: "List all note folders"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.notes()
        let folders = try service.listFolders()

        if json {
            try OutputFormatter.printJSON(folders)
        } else {
            print("Note Folders:")
            for folder in folders {
                print("  - \(folder)")
            }
        }
    }
}
