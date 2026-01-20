import ArgumentParser
import Foundation
import SysmCore

struct WeatherDetailed: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "detailed",
        abstract: "Show detailed weather including UV index, pressure, visibility"
    )

    @Argument(help: "Location (city name or lat,lon coordinates)")
    var location: String

    @Option(name: .long, help: "Weather data backend (weatherkit or open-meteo)")
    var backend: WeatherBackend = .weatherKit

    func run() async throws {
        let service = backend.service()

        do {
            let weather = try await service.getDetailedWeather(location: location)
            print(weather.formatted())
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }
}
