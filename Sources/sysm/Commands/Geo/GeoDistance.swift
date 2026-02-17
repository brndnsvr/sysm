import ArgumentParser
import Foundation
import SysmCore

struct GeoDistance: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "distance",
        abstract: "Calculate distance between two coordinates"
    )

    @Argument(help: "First point as 'lat,lon' (e.g. 40.7128,-74.0060)")
    var from: String

    @Argument(help: "Second point as 'lat,lon' (e.g. 34.0522,-118.2437)")
    var to: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.geo()

        let (lat1, lon1) = try parseCoordPair(from)
        let (lat2, lon2) = try parseCoordPair(to)

        let km = service.distance(lat1: lat1, lon1: lon1, lat2: lat2, lon2: lon2)
        let miles = km * 0.621371

        if json {
            let result = DistanceResult(
                from: CoordPair(latitude: lat1, longitude: lon1),
                to: CoordPair(latitude: lat2, longitude: lon2),
                distanceKm: round(km * 100) / 100,
                distanceMiles: round(miles * 100) / 100
            )
            try OutputFormatter.printJSON(result)
        } else {
            print("From: \(lat1), \(lon1)")
            print("To:   \(lat2), \(lon2)")
            print("Distance: \(String(format: "%.2f", km)) km (\(String(format: "%.2f", miles)) mi)")
        }
    }

    private func parseCoordPair(_ input: String) throws -> (Double, Double) {
        let parts = input.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2,
              let lat = Double(parts[0]),
              let lon = Double(parts[1]),
              lat >= -90, lat <= 90,
              lon >= -180, lon <= 180 else {
            throw GeoError.invalidCoordinates(0, 0)
        }
        return (lat, lon)
    }
}

private struct DistanceResult: Encodable {
    let from: CoordPair
    let to: CoordPair
    let distanceKm: Double
    let distanceMiles: Double
}

private struct CoordPair: Encodable {
    let latitude: Double
    let longitude: Double
}
