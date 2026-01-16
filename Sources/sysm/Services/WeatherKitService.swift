import Foundation
import WeatherKit
import CoreLocation

/// WeatherKit-based weather service (requires code signing with WeatherKit entitlement)
struct WeatherKitService: WeatherServiceProtocol {

    private let geocoder = CLGeocoder()

    // MARK: - Public API

    func getCurrentWeather(location: String) async throws -> CurrentWeather {
        guard #available(macOS 13.0, *) else {
            throw WeatherError.apiError("WeatherKit requires macOS 13.0 or later")
        }

        let coords = try await resolveLocation(location)
        let clLocation = CLLocation(latitude: coords.latitude, longitude: coords.longitude)

        do {
            let weather = try await WeatherKit.WeatherService.shared.weather(for: clLocation, including: .current)

            return CurrentWeather(
                location: coords.displayName,
                latitude: coords.latitude,
                longitude: coords.longitude,
                temperature: weather.temperature.converted(to: UnitTemperature.fahrenheit).value,
                apparentTemperature: weather.apparentTemperature.converted(to: UnitTemperature.fahrenheit).value,
                humidity: Int(weather.humidity * 100),
                windSpeed: weather.wind.speed.converted(to: UnitSpeed.milesPerHour).value,
                windDirection: Int(weather.wind.direction.value),
                condition: mapCondition(weather.condition),
                time: weather.date,
                timezone: TimeZone.current.identifier
            )
        } catch {
            throw handleWeatherKitError(error)
        }
    }

    func getForecast(location: String, days: Int = 7) async throws -> Forecast {
        guard #available(macOS 13.0, *) else {
            throw WeatherError.apiError("WeatherKit requires macOS 13.0 or later")
        }

        let coords = try await resolveLocation(location)
        let clLocation = CLLocation(latitude: coords.latitude, longitude: coords.longitude)

        do {
            let weather = try await WeatherKit.WeatherService.shared.weather(for: clLocation, including: .daily)

            var forecasts: [DayForecast] = []
            for day in weather.forecast.prefix(min(days, 10)) {
                forecasts.append(DayForecast(
                    date: day.date,
                    high: day.highTemperature.converted(to: UnitTemperature.fahrenheit).value,
                    low: day.lowTemperature.converted(to: UnitTemperature.fahrenheit).value,
                    condition: mapCondition(day.condition),
                    precipitation: day.precipitationAmount.converted(to: UnitLength.inches).value,
                    sunrise: day.sun.sunrise ?? day.date,
                    sunset: day.sun.sunset ?? day.date
                ))
            }

            return Forecast(
                location: coords.displayName,
                days: forecasts,
                timezone: TimeZone.current.identifier
            )
        } catch {
            throw handleWeatherKitError(error)
        }
    }

    func getHourlyForecast(location: String, hours: Int = 24) async throws -> HourlyForecast {
        guard #available(macOS 13.0, *) else {
            throw WeatherError.apiError("WeatherKit requires macOS 13.0 or later")
        }

        let coords = try await resolveLocation(location)
        let clLocation = CLLocation(latitude: coords.latitude, longitude: coords.longitude)

        do {
            let weather = try await WeatherKit.WeatherService.shared.weather(for: clLocation, including: .hourly)

            var forecasts: [HourForecast] = []
            for hour in weather.forecast.prefix(min(hours, 168)) {
                forecasts.append(HourForecast(
                    time: hour.date,
                    temperature: hour.temperature.converted(to: UnitTemperature.fahrenheit).value,
                    precipitationProbability: Int(hour.precipitationChance * 100),
                    condition: mapCondition(hour.condition)
                ))
            }

            return HourlyForecast(
                location: coords.displayName,
                hours: forecasts,
                timezone: TimeZone.current.identifier
            )
        } catch {
            throw handleWeatherKitError(error)
        }
    }

    // MARK: - Location Resolution

    private func resolveLocation(_ location: String) async throws -> Coordinates {
        // Check if it's already coordinates (lat,lon format)
        if let coords = parseCoordinates(location) {
            return coords
        }

        // Otherwise geocode the location name
        return try await geocode(location)
    }

    private func parseCoordinates(_ input: String) -> Coordinates? {
        let parts = input.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2,
              let lat = Double(parts[0]),
              let lon = Double(parts[1]),
              lat >= -90 && lat <= 90,
              lon >= -180 && lon <= 180 else {
            return nil
        }
        return Coordinates(
            latitude: lat,
            longitude: lon,
            name: String(format: "%.4f, %.4f", lat, lon),
            country: nil,
            admin1: nil
        )
    }

    private func geocode(_ name: String) async throws -> Coordinates {
        do {
            let placemarks = try await geocoder.geocodeAddressString(name)

            guard let placemark = placemarks.first,
                  let location = placemark.location else {
                throw WeatherError.locationNotFound(name)
            }

            let displayName = [
                placemark.locality,
                placemark.administrativeArea,
                placemark.country
            ].compactMap { $0 }.joined(separator: ", ")

            return Coordinates(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                name: displayName.isEmpty ? name : displayName,
                country: placemark.country,
                admin1: placemark.administrativeArea
            )
        } catch let error as WeatherError {
            throw error
        } catch {
            throw WeatherError.locationNotFound(name)
        }
    }

    // MARK: - Condition Mapping

    @available(macOS 13.0, *)
    private func mapCondition(_ condition: WeatherKit.WeatherCondition) -> WeatherCondition {
        switch condition {
        // Clear
        case .clear:
            return .clear
        case .mostlyClear:
            return .mainlyClear
        case .partlyCloudy:
            return .partlyCloudy
        case .mostlyCloudy, .cloudy:
            return .overcast

        // Fog
        case .foggy, .haze, .smoky, .blowingDust:
            return .fog

        // Drizzle
        case .drizzle:
            return .drizzleModerate
        case .freezingDrizzle:
            return .freezingDrizzleLight

        // Rain
        case .rain:
            return .rainModerate
        case .heavyRain:
            return .rainHeavy
        case .sunShowers:
            return .rainShowersSlight
        case .freezingRain:
            return .freezingRainLight

        // Snow
        case .flurries, .sunFlurries:
            return .snowSlight
        case .snow:
            return .snowModerate
        case .heavySnow, .blizzard, .blowingSnow:
            return .snowHeavy
        case .sleet, .wintryMix:
            return .freezingRainLight

        // Thunderstorms
        case .thunderstorms, .isolatedThunderstorms, .scatteredThunderstorms:
            return .thunderstorm
        case .strongStorms:
            return .thunderstormWithHailHeavy

        // Other conditions - map to closest equivalent
        case .hail:
            return .thunderstormWithHailSlight
        case .hot, .frigid, .breezy, .windy:
            return .clear  // Temperature/wind indicated by other fields
        case .hurricane, .tropicalStorm:
            return .thunderstormWithHailHeavy

        @unknown default:
            return .clear
        }
    }

    // MARK: - Error Handling

    private func handleWeatherKitError(_ error: Error) -> WeatherError {
        let nsError = error as NSError

        // Check for common WeatherKit errors
        if nsError.domain == "WeatherDaemon.WDSJWTAuthenticatorServiceListener.Errors" {
            return .apiError("""
                WeatherKit authentication failed.

                Ensure:
                1. App ID is registered with WeatherKit capability at developer.apple.com
                2. Binary is signed with proper entitlements
                3. Wait 30+ minutes after enabling capability for provisioning

                For now, use: --backend open-meteo
                """)
        }

        if nsError.domain == "NSCocoaErrorDomain" && nsError.code == 4099 {
            return .apiError("""
                WeatherKit service connection failed.

                The app may not be properly signed or entitled.
                Use: --backend open-meteo
                """)
        }

        // Generic error
        return .apiError("WeatherKit error: \(error.localizedDescription)")
    }
}
