import Foundation

/// WeatherKit-based weather service (requires code signing with WeatherKit entitlement)
///
/// To use WeatherKit:
/// 1. Register an App ID with WeatherKit capability in Apple Developer portal
/// 2. Create a provisioning profile with WeatherKit entitlement
/// 3. Build and sign: make release-signed SIGNING_IDENTITY="Developer ID Application: ..."
///
/// Without proper signing, WeatherKit will fail with auth service errors.
/// Use the default Open-Meteo backend (--backend open-meteo) for unsigned builds.
struct WeatherKitService: WeatherServiceProtocol {

    private func checkAvailability() throws {
        // WeatherKit requires:
        // - macOS 13.0+
        // - Code signing with com.apple.developer.weatherkit entitlement
        // - Registered App ID with WeatherKit capability
        if #available(macOS 13.0, *) {
            // macOS version is sufficient, but entitlement check happens at runtime
            // when we try to access WeatherKit. The service will fail if not properly signed.
        } else {
            throw WeatherError.apiError("WeatherKit requires macOS 13.0 or later")
        }
    }

    func getCurrentWeather(location: String) async throws -> CurrentWeather {
        try checkAvailability()

        // WeatherKit implementation would go here when properly signed
        // For now, provide clear error about requirements
        throw WeatherError.apiError("""
            WeatherKit requires code signing with WeatherKit entitlement.

            To enable WeatherKit:
            1. Register App ID with WeatherKit in Apple Developer portal
            2. Create provisioning profile with WeatherKit capability
            3. Run: make release-signed SIGNING_IDENTITY="Developer ID Application: Your Name (TEAM_ID)"

            For unsigned builds, use: --backend open-meteo (default)
            """)
    }

    func getForecast(location: String, days: Int) async throws -> Forecast {
        try checkAvailability()

        throw WeatherError.apiError("""
            WeatherKit requires code signing with WeatherKit entitlement.
            Use --backend open-meteo for unsigned builds.
            """)
    }

    func getHourlyForecast(location: String, hours: Int) async throws -> HourlyForecast {
        try checkAvailability()

        throw WeatherError.apiError("""
            WeatherKit requires code signing with WeatherKit entitlement.
            Use --backend open-meteo for unsigned builds.
            """)
    }
}

// MARK: - Future WeatherKit Implementation
//
// When the app is properly signed with WeatherKit entitlement, replace the stub
// implementations above with actual WeatherKit calls:
//
// import WeatherKit
// import CoreLocation
//
// @available(macOS 13.0, *)
// extension WeatherKitService {
//     private var weatherService: WeatherKit.WeatherService { .shared }
//
//     func getCurrentWeatherKit(location: String) async throws -> CurrentWeather {
//         let coords = try await resolveLocation(location)
//         let clLocation = CLLocation(latitude: coords.latitude, longitude: coords.longitude)
//         let weather = try await weatherService.weather(for: clLocation)
//         // Map WeatherKit.CurrentWeather to our CurrentWeather model
//         ...
//     }
// }
