import ArgumentParser
import Foundation
import SysmCore

struct GeoReverse: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "reverse",
        abstract: "Reverse geocode coordinates to an address"
    )

    @Argument(help: "Latitude")
    var latitude: Double

    @Argument(help: "Longitude")
    var longitude: Double

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.geo()
        let location = try await service.reverseGeocode(latitude: latitude, longitude: longitude)

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
