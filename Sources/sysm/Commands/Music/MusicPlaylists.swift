import ArgumentParser
import Foundation

struct MusicPlaylists: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "playlists",
        abstract: "List playlists"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = MusicService()
        let playlists = try service.listPlaylists()

        if json {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(playlists)
            print(String(data: data, encoding: .utf8)!)
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
