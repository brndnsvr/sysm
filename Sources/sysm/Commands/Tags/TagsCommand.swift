import ArgumentParser

struct TagsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tags",
        abstract: "Manage Finder tags on files",
        subcommands: [
            TagsList.self,
            TagsAdd.self,
            TagsRemove.self,
            TagsFind.self,
        ],
        defaultSubcommand: TagsList.self
    )
}
