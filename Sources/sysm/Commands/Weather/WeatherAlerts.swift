import ArgumentParser
import Foundation
import SysmCore

struct WeatherAlerts: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "alerts",
        abstract: "Show active weather alerts for a location"
    )

    @Argument(help: "Location (city name or lat,lon coordinates)")
    var location: String

    @Option(name: .long, help: "Weather data backend (weatherkit or open-meteo)")
    var backend: WeatherBackend = .weatherKit

    func run() async throws {
        let service = backend.service()

        do {
            let alerts = try await service.getAlerts(location: location)

            if alerts.isEmpty {
                print("No active weather alerts for \(location)")
                return
            }

            print("Active Weather Alerts")
            print(String(repeating: "=", count: 50))
            print()

            for alert in alerts {
                print(alert.formatted())
                print()
            }
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            throw ExitCode.failure
        }
    }
}
