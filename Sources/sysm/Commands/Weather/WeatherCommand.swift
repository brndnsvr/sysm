import ArgumentParser
import Foundation

struct WeatherCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "weather",
        abstract: "Get weather information",
        subcommands: [
            WeatherCurrent.self,
            WeatherForecast.self,
            WeatherHourly.self,
        ],
        defaultSubcommand: WeatherCurrent.self
    )
}
