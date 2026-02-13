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
            NotesShow.self,
            NotesSearch.self,
            NotesFolders.self,
            NotesCreate.self,
            NotesEdit.self,
            NotesAppend.self,
            NotesDelete.self,
            NotesMove.self,
            NotesDuplicate.self,
            NotesCreateFolder.self,
            NotesDeleteFolder.self,
            NotesImport.self,
        ]
    )
}
