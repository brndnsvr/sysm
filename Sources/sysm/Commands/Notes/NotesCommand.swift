import ArgumentParser
import Foundation
import SysmCore

struct NotesCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "notes",
        abstract: "Manage Apple Notes",
        subcommands: [
            NotesCheck.self,
            NotesList.self,
            NotesFolders.self,
            NotesCreate.self,
            NotesEdit.self,
            NotesDelete.self,
            NotesCreateFolder.self,
            NotesDeleteFolder.self,
            NotesImport.self,
        ]
    )
}
