import ArgumentParser
import Foundation
import SysmCore

struct WeatherCurrent: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "current",
        abstract: "Get current weather conditions"
    )

    @Argument(help: "Location (city name or lat,lon)")
    var location: String

    @Option(name: .long, help: "Weather data backend (open-meteo, weatherkit)")
    var backend: WeatherBackend = .weatherKit

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = backend.service()
        let weather = try await service.getCurrentWeather(location: location)

        if json {
            try OutputFormatter.printJSON(weather)
        } else {
            print(weather.formatted())
        }
    }
}
