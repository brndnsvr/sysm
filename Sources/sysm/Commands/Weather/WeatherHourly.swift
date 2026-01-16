import ArgumentParser
import Foundation

struct WeatherHourly: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "hourly",
        abstract: "Get hourly weather forecast"
    )

    @Argument(help: "Location (city name or lat,lon)")
    var location: String

    @Option(name: .shortAndLong, help: "Number of hours (1-168)")
    var hours: Int = 24

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.weather()
        let forecast = try await service.getHourlyForecast(location: location, hours: hours)

        if json {
            try OutputFormatter.printJSON(forecast)
        } else {
            print(forecast.formatted())
        }
    }
}
