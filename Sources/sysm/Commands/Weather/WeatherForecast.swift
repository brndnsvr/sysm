import ArgumentParser
import Foundation
import SysmCore

struct WeatherForecast: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "forecast",
        abstract: "Get weather forecast"
    )

    @Argument(help: "Location (city name or lat,lon)")
    var location: String

    @Option(name: .shortAndLong, help: "Number of days (1-16)")
    var days: Int = 7

    @Option(name: .long, help: "Weather data backend (open-meteo, weatherkit)")
    var backend: WeatherBackend = .weatherKit

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = backend.service()
        let forecast = try await service.getForecast(location: location, days: days)

        if json {
            try OutputFormatter.printJSON(forecast)
        } else {
            print(forecast.formatted())
        }
    }
}
