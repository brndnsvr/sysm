import ArgumentParser

struct GeoCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "geo",
        abstract: "Geocoding and location utilities",
        subcommands: [
            GeoLookup.self,
            GeoReverse.self,
            GeoDistance.self,
        ]
    )
}
