import ArgumentParser
import Foundation

struct NotesCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "notes",
        abstract: "Manage Apple Notes",
        subcommands: [
            NotesCheck.self,
            NotesList.self,
            NotesFolders.self,
            NotesImport.self,
        ],
        defaultSubcommand: NotesCheck.self
    )
}
