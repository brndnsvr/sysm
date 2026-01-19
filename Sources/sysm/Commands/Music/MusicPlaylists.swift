import ArgumentParser
import Foundation
import SysmCore

struct MusicPlaylists: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "playlists",
        abstract: "List playlists"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.music()
        let playlists = try service.listPlaylists()

        if json {
            try OutputFormatter.printJSON(playlists)
        } else {
            if playlists.isEmpty {
                print("No playlists found")
            } else {
                print("Playlists (\(playlists.count)):\n")
                for playlist in playlists {
                    print("  - \(playlist.formatted())")
                }
            }
        }
    }
}
