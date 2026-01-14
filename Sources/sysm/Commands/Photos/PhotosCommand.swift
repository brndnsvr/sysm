import ArgumentParser

struct PhotosCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "photos",
        abstract: "Access Photos library",
        subcommands: [
            PhotosAlbums.self,
            PhotosList.self,
            PhotosRecent.self,
            PhotosSearch.self,
            PhotosExport.self,
        ],
        defaultSubcommand: PhotosRecent.self
    )
}
