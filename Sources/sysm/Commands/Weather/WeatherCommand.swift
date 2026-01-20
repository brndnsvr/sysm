import ArgumentParser
import Foundation
import SysmCore

/// Weather data backend selection
enum WeatherBackend: String, ExpressibleByArgument, CaseIterable {
    case openMeteo = "open-meteo"
    case weatherKit = "weatherkit"

    static var defaultValue: WeatherBackend { .weatherKit }

    /// Get the appropriate weather service for this backend
    func service() -> any WeatherServiceProtocol {
        switch self {
        case .openMeteo:
            return Services.weather()
        case .weatherKit:
            return Services.weatherKit()
        }
    }
}

struct WeatherCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "weather",
        abstract: "Get weather information",
        subcommands: [
            WeatherCurrent.self,
            WeatherForecast.self,
            WeatherHourly.self,
            WeatherDetailed.self,
            WeatherAlerts.self,
        ]
    )
}
