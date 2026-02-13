import ArgumentParser
import Foundation
import SysmCore

struct PhotosAlbums: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "albums",
        abstract: "Manage photo albums",
        subcommands: [
            PhotosAlbumsList.self,
            PhotosAlbumsCreate.self,
            PhotosAlbumsDelete.self,
            PhotosAlbumsRename.self,
            PhotosAlbumsAdd.self,
            PhotosAlbumsRemove.self,
        ],
        defaultSubcommand: PhotosAlbumsList.self
    )
}

struct PhotosAlbumsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List all photo albums"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.photos()
        let albums = try await service.listAlbums()

        if json {
            try OutputFormatter.printJSON(albums)
        } else {
            if albums.isEmpty {
                print("No albums found")
            } else {
                print("Albums (\(albums.count)):\n")
                for album in albums {
                    print("  - \(album.formatted())")
                    print("    ID: \(album.id)")
                }
            }
        }
    }
}

struct PhotosAlbumsCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new photo album"
    )

    @Argument(help: "Album name")
    var name: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.photos()
        let album = try await service.createAlbum(name: name)

        if json {
            try OutputFormatter.printJSON(album)
        } else {
            print("Created album: \(album.title)")
            print("ID: \(album.id)")
        }
    }
}

struct PhotosAlbumsDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a photo album"
    )

    @Argument(help: "Album ID")
    var albumId: String

    func run() async throws {
        let service = Services.photos()
        let success = try await service.deleteAlbum(albumId: albumId)

        if success {
            print("Deleted album \(albumId)")
        } else {
            print("Failed to delete album")
        }
    }
}

struct PhotosAlbumsRename: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "rename",
        abstract: "Rename a photo album"
    )

    @Argument(help: "Album ID")
    var albumId: String

    @Option(name: .long, help: "New album name")
    var newName: String

    func run() async throws {
        let service = Services.photos()
        let success = try await service.renameAlbum(albumId: albumId, newName: newName)

        if success {
            print("Renamed album to '\(newName)'")
        } else {
            print("Failed to rename album")
        }
    }
}

struct PhotosAlbumsAdd: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add",
        abstract: "Add photos to an album"
    )

    @Argument(help: "Album ID")
    var albumId: String

    @Argument(help: "Photo asset IDs")
    var assetIds: [String]

    func run() async throws {
        let service = Services.photos()
        let count = try await service.addPhotosToAlbum(albumId: albumId, assetIds: assetIds)

        print("Added \(count) photo(s) to album")
    }
}

struct PhotosAlbumsRemove: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "remove",
        abstract: "Remove photos from an album"
    )

    @Argument(help: "Album ID")
    var albumId: String

    @Argument(help: "Photo asset IDs")
    var assetIds: [String]

    func run() async throws {
        let service = Services.photos()
        let count = try await service.removePhotosFromAlbum(albumId: albumId, assetIds: assetIds)

        print("Removed \(count) photo(s) from album")
    }
}
