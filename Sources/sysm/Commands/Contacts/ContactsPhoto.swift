import ArgumentParser
import Foundation
import SysmCore

struct ContactsPhoto: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "photo",
        abstract: "Manage contact photos",
        subcommands: [
            ContactsPhotoSet.self,
            ContactsPhotoGet.self,
            ContactsPhotoRemove.self,
        ]
    )
}

struct ContactsPhotoSet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "set",
        abstract: "Set a contact's photo from an image file"
    )

    @Argument(help: "Contact identifier")
    var identifier: String

    @Option(name: .long, help: "Path to image file")
    var image: String

    func run() async throws {
        let service = Services.contacts()
        let success = try await service.setContactPhoto(identifier: identifier, imagePath: image)

        if success {
            print("Set photo for contact '\(identifier)'")
        } else {
            print("Failed to set photo")
        }
    }
}

struct ContactsPhotoGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Extract a contact's photo to a file"
    )

    @Argument(help: "Contact identifier")
    var identifier: String

    @Option(name: .long, help: "Output file path")
    var output: String

    func run() async throws {
        let service = Services.contacts()
        let success = try await service.getContactPhoto(identifier: identifier, outputPath: output)

        if success {
            print("Saved photo to \(output)")
        } else {
            print("Failed to get photo")
        }
    }
}

struct ContactsPhotoRemove: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "remove",
        abstract: "Remove a contact's photo"
    )

    @Argument(help: "Contact identifier")
    var identifier: String

    func run() async throws {
        let service = Services.contacts()
        let success = try await service.removeContactPhoto(identifier: identifier)

        if success {
            print("Removed photo from contact '\(identifier)'")
        } else {
            print("Failed to remove photo")
        }
    }
}
