import ArgumentParser
import Foundation
import SysmCore

struct GeoLookup: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "lookup",
        abstract: "Geocode an address to coordinates"
    )

    @Argument(help: "Address or place name to geocode")
    var address: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.geo()
        let location = try await service.geocode(address)

        if json {
            try OutputFormatter.printJSON(location)
        } else {
            print("Location: \(location.name)")
            print("  Latitude:  \(location.latitude)")
            print("  Longitude: \(location.longitude)")
            if let street = location.street { print("  Street:    \(street)") }
            if let city = location.city { print("  City:      \(city)") }
            if let state = location.state { print("  State:     \(state)") }
            if let zip = location.postalCode { print("  Postal:    \(zip)") }
            if let country = location.country { print("  Country:   \(country)") }
            if let tz = location.timezone { print("  Timezone:  \(tz)") }
        }
    }
}
