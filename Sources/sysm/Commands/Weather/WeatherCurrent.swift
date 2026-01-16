import ArgumentParser
import Foundation

struct WeatherCurrent: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "current",
        abstract: "Get current weather conditions"
    )

    @Argument(help: "Location (city name or lat,lon)")
    var location: String

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.weather()
        let weather = try await service.getCurrentWeather(location: location)

        if json {
            try OutputFormatter.printJSON(weather)
        } else {
            print(weather.formatted())
        }
    }
}
