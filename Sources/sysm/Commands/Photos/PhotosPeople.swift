import ArgumentParser
import Foundation
import SysmCore

struct PhotosPeople: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "people",
        abstract: "List people detected in Photos or search by person"
    )

    @Argument(help: "Person name to search for (optional - lists all people if omitted)")
    var personName: String?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.photos()

        if let name = personName {
            // Search for photos of a specific person
            let photos = try await service.searchByPerson(personName: name)

            if json {
                try OutputFormatter.printJSON(photos)
            } else {
                if photos.isEmpty {
                    print("No photos found for person '\(name)'")
                    print("\nNote: macOS PhotoKit has limited person/face detection API access.")
                    print("Person detection works best with photos tagged in Photos.app.")
                } else {
                    print("Photos of '\(name)' (\(photos.count)):\n")
                    for photo in photos.prefix(20) {
                        print("  - \(photo.filename) (\(photo.id))")
                        if let date = photo.creationDate {
                            print("    Created: \(DateFormatters.mediumDate.string(from: date))")
                        }
                    }
                    if photos.count > 20 {
                        print("\n  ... and \(photos.count - 20) more (use --json for full list)")
                    }
                }
            }
        } else {
            // List all people
            let people = try await service.listPeople()

            if json {
                try OutputFormatter.printJSON(people)
            } else {
                if people.isEmpty {
                    print("No people found in Photos library")
                    print("\nNote: macOS PhotoKit has limited person/face detection API access.")
                    print("People must be tagged in Photos.app to appear here.")
                } else {
                    print("People (\(people.count)):\n")
                    for person in people {
                        print("  - \(person.formatted())")
                        print("    ID: \(person.id)")
                    }
                }
            }
        }
    }
}
