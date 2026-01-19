import Foundation

public struct WeatherService: WeatherServiceProtocol {
    private let baseURL = "https://api.open-meteo.com/v1"
    private let geocodeURL = "https://geocoding-api.open-meteo.com/v1"

    // MARK: - Public API

    public func getCurrentWeather(location: String) async throws -> CurrentWeather {
        let coords = try await resolveLocation(location)

        let params = [
            "latitude": String(coords.latitude),
            "longitude": String(coords.longitude),
            "current": "temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,wind_direction_10m",
            "temperature_unit": "fahrenheit",
            "wind_speed_unit": "mph",
            "timezone": "auto"
        ]

        let data = try await fetch(path: "/forecast", params: params)
        let response = try JSONDecoder().decode(CurrentWeatherResponse.self, from: data)

        guard let current = response.current else {
            throw WeatherError.invalidResponse
        }

        return CurrentWeather(
            location: coords.displayName,
            latitude: coords.latitude,
            longitude: coords.longitude,
            temperature: current.temperature_2m,
            apparentTemperature: current.apparent_temperature,
            humidity: Int(current.relative_humidity_2m),
            windSpeed: current.wind_speed_10m,
            windDirection: Int(current.wind_direction_10m),
            condition: WeatherCondition(rawValue: current.weather_code) ?? .clear,
            time: parseISO8601(current.time) ?? Date(),
            timezone: response.timezone
        )
    }

    public func getForecast(location: String, days: Int = 7) async throws -> Forecast {
        let coords = try await resolveLocation(location)

        let params = [
            "latitude": String(coords.latitude),
            "longitude": String(coords.longitude),
            "daily": "temperature_2m_max,temperature_2m_min,weather_code,precipitation_sum,sunrise,sunset",
            "temperature_unit": "fahrenheit",
            "precipitation_unit": "inch",
            "timezone": "auto",
            "forecast_days": String(min(days, 16))
        ]

        let data = try await fetch(path: "/forecast", params: params)
        let response = try JSONDecoder().decode(ForecastResponse.self, from: data)

        guard let daily = response.daily else {
            throw WeatherError.invalidResponse
        }

        var forecasts: [DayForecast] = []
        for i in 0..<daily.time.count {
            guard let date = parseDate(daily.time[i]) else { continue }
            forecasts.append(DayForecast(
                date: date,
                high: daily.temperature_2m_max[i],
                low: daily.temperature_2m_min[i],
                condition: WeatherCondition(rawValue: daily.weather_code[i]) ?? .clear,
                precipitation: daily.precipitation_sum[i],
                sunrise: parseISO8601(daily.sunrise[i]) ?? date,
                sunset: parseISO8601(daily.sunset[i]) ?? date
            ))
        }

        return Forecast(
            location: coords.displayName,
            days: forecasts,
            timezone: response.timezone
        )
    }

    public func getHourlyForecast(location: String, hours: Int = 24) async throws -> HourlyForecast {
        let coords = try await resolveLocation(location)

        // Calculate how many days we need to cover the requested hours
        let daysNeeded = max(1, (hours + 23) / 24)

        let params = [
            "latitude": String(coords.latitude),
            "longitude": String(coords.longitude),
            "hourly": "temperature_2m,precipitation_probability,weather_code",
            "temperature_unit": "fahrenheit",
            "timezone": "auto",
            "forecast_days": String(min(daysNeeded, 16))
        ]

        let data = try await fetch(path: "/forecast", params: params)
        let response = try JSONDecoder().decode(HourlyResponse.self, from: data)

        guard let hourly = response.hourly else {
            throw WeatherError.invalidResponse
        }

        var forecasts: [HourForecast] = []
        let count = min(hours, hourly.time.count)
        for i in 0..<count {
            guard let time = parseISO8601(hourly.time[i]) else { continue }
            forecasts.append(HourForecast(
                time: time,
                temperature: hourly.temperature_2m[i],
                precipitationProbability: hourly.precipitation_probability[i],
                condition: WeatherCondition(rawValue: hourly.weather_code[i]) ?? .clear
            ))
        }

        return HourlyForecast(
            location: coords.displayName,
            hours: forecasts,
            timezone: response.timezone
        )
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

    private func geocode(_ name: String) async throws -> Coordinates {
        let params = [
            "name": name,
            "count": "1",
            "language": "en",
            "format": "json"
        ]

        var components = URLComponents(string: geocodeURL + "/search")!
        components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }

        guard let url = components.url else {
            throw WeatherError.networkError("Invalid geocoding URL")
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherError.networkError("Invalid response")
        }

        if httpResponse.statusCode != 200 {
            throw WeatherError.apiError("Geocoding failed with status \(httpResponse.statusCode)")
        }

        let geocodeResponse = try JSONDecoder().decode(GeocodeResponse.self, from: data)

        guard let result = geocodeResponse.results?.first else {
            throw WeatherError.locationNotFound(name)
        }

        return Coordinates(
            latitude: result.latitude,
            longitude: result.longitude,
            name: result.name,
            country: result.country,
            admin1: result.admin1
        )
    }

    // MARK: - HTTP Helpers

    private func fetch(path: String, params: [String: String]) async throws -> Data {
        var components = URLComponents(string: baseURL + path)!
        components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }

        guard let url = components.url else {
            throw WeatherError.networkError("Invalid URL")
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherError.networkError("Invalid response")
        }

        if httpResponse.statusCode != 200 {
            // Try to parse error message
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw WeatherError.apiError(errorResponse.reason ?? "Unknown error")
            }
            throw WeatherError.apiError("Request failed with status \(httpResponse.statusCode)")
        }

        return data
    }

    // MARK: - Date Parsing

    private func parseISO8601(_ string: String) -> Date? {
        // Try full ISO8601 format first (with timezone)
        let iso8601 = ISO8601DateFormatter()
        iso8601.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        if let date = iso8601.date(from: string) {
            return date
        }

        // Fall back to simple datetime format (yyyy-MM-ddTHH:mm)
        let simple = DateFormatter()
        simple.dateFormat = "yyyy-MM-dd'T'HH:mm"
        simple.timeZone = TimeZone(identifier: "UTC")
        return simple.date(from: string)
    }

    private func parseDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.date(from: string)
    }
}

// MARK: - API Response Models

private struct CurrentWeatherResponse: Codable {
    public let latitude: Double
    public let longitude: Double
    public let timezone: String
    public let current: CurrentData?

    public struct CurrentData: Codable {
        let time: String
        let temperature_2m: Double
        let relative_humidity_2m: Double
        let apparent_temperature: Double
        let weather_code: Int
        let wind_speed_10m: Double
        let wind_direction_10m: Double
    }
}

private struct ForecastResponse: Codable {
    public let latitude: Double
    public let longitude: Double
    public let timezone: String
    public let daily: DailyData?

    public struct DailyData: Codable {
        let time: [String]
        let temperature_2m_max: [Double]
        let temperature_2m_min: [Double]
        let weather_code: [Int]
        let precipitation_sum: [Double]
        let sunrise: [String]
        let sunset: [String]
    }
}

private struct HourlyResponse: Codable {
    public let latitude: Double
    public let longitude: Double
    public let timezone: String
    public let hourly: HourlyData?

    public struct HourlyData: Codable {
        let time: [String]
        let temperature_2m: [Double]
        let precipitation_probability: [Int]
        let weather_code: [Int]
    }
}

private struct GeocodeResponse: Codable {
    public let results: [GeocodeResult]?

    public struct GeocodeResult: Codable {
        let name: String
        let latitude: Double
        let longitude: Double
        let country: String?
        let admin1: String?
    }
}

private struct ErrorResponse: Codable {
    public let error: Bool?
    public let reason: String?
}
