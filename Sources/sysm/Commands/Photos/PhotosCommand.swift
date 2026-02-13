import ArgumentParser
import SysmCore

struct PhotosCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "photos",
        abstract: "Access Photos library",
        subcommands: [
            PhotosAlbums.self,
            PhotosList.self,
            PhotosVideos.self,
            PhotosRecent.self,
            PhotosSearch.self,
            PhotosExport.self,
            PhotosMetadata.self,
            PhotosPeople.self,
            PhotosFavorite.self,
            PhotosHidden.self,
        ]
    )
}
