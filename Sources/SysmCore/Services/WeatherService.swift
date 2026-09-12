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
        let times = OpenMeteoTimeParser(timezone: response.timezone, utcOffsetSeconds: response.utc_offset_seconds)

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
            time: times.dateTime(current.time) ?? Date(),
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
        let times = OpenMeteoTimeParser(timezone: response.timezone, utcOffsetSeconds: response.utc_offset_seconds)

        guard let daily = response.daily else {
            throw WeatherError.invalidResponse
        }

        var forecasts: [DayForecast] = []
        for i in 0..<daily.time.count {
            guard let date = times.date(daily.time[i]) else { continue }
            forecasts.append(DayForecast(
                date: date,
                high: daily.temperature_2m_max[i],
                low: daily.temperature_2m_min[i],
                condition: WeatherCondition(rawValue: daily.weather_code[i]) ?? .clear,
                precipitation: daily.precipitation_sum[i],
                sunrise: times.dateTime(daily.sunrise[i]) ?? date,
                sunset: times.dateTime(daily.sunset[i]) ?? date
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

        // forecast_hours starts the series at the current hour. forecast_days
        // starts it at local midnight, so the first rows were hours already past.
        let params = [
            "latitude": String(coords.latitude),
            "longitude": String(coords.longitude),
            "hourly": "temperature_2m,precipitation_probability,weather_code",
            "temperature_unit": "fahrenheit",
            "timezone": "auto",
            "forecast_hours": String(min(max(hours, 1), 16 * 24))
        ]

        let data = try await fetch(path: "/forecast", params: params)
        let response = try JSONDecoder().decode(HourlyResponse.self, from: data)
        let times = OpenMeteoTimeParser(timezone: response.timezone, utcOffsetSeconds: response.utc_offset_seconds)

        guard let hourly = response.hourly else {
            throw WeatherError.invalidResponse
        }

        var forecasts: [HourForecast] = []
        let count = min(hours, hourly.time.count)
        for i in 0..<count {
            guard let time = times.dateTime(hourly.time[i]) else { continue }
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

    public func getAlerts(location: String) async throws -> [WeatherAlert] {
        // Open-Meteo has no alerts endpoint. Returning [] made
        // `sysm weather alerts` report "No active weather alerts" unchecked.
        throw WeatherError.alertsUnavailable
    }

    public func getDetailedWeather(location: String) async throws -> DetailedWeather {
        let coords = try await resolveLocation(location)

        let params = [
            "latitude": String(coords.latitude),
            "longitude": String(coords.longitude),
            "current": "temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,wind_direction_10m,wind_gusts_10m,pressure_msl,cloud_cover,uv_index",
            "hourly": "visibility,dew_point_2m",
            "temperature_unit": "fahrenheit",
            "wind_speed_unit": "mph",
            "timezone": "auto",
            "forecast_hours": "1"
        ]

        let data = try await fetch(path: "/forecast", params: params)
        let response = try JSONDecoder().decode(DetailedWeatherResponse.self, from: data)
        let times = OpenMeteoTimeParser(timezone: response.timezone, utcOffsetSeconds: response.utc_offset_seconds)

        guard let current = response.current else {
            throw WeatherError.invalidResponse
        }

        // Get visibility and dew point from hourly (first hour)
        let visibility = response.hourly?.visibility?.first ?? 10.0
        let dewPoint = response.hourly?.dew_point_2m?.first ?? 0.0

        // Convert pressure from hPa to inHg
        let pressureInHg = (current.pressure_msl ?? 1013.25) * 0.02953

        let uvValue = Int(current.uv_index ?? 0)

        return DetailedWeather(
            location: coords.displayName,
            latitude: coords.latitude,
            longitude: coords.longitude,
            temperature: current.temperature_2m,
            apparentTemperature: current.apparent_temperature,
            humidity: Int(current.relative_humidity_2m),
            windSpeed: current.wind_speed_10m,
            windDirection: Int(current.wind_direction_10m),
            windGust: current.wind_gusts_10m,
            pressure: pressureInHg,
            dewPoint: dewPoint,
            visibility: visibility * 0.000621371,  // meters to miles
            uvIndex: uvValue,
            uvIndexDescription: uvIndexDescription(uvValue),
            cloudCover: Int(current.cloud_cover ?? 0),
            condition: WeatherCondition(rawValue: current.weather_code) ?? .clear,
            time: times.dateTime(current.time) ?? Date(),
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
}

// MARK: - Time Parsing

/// Reads Open-Meteo's wall-clock strings in the zone the response names.
///
/// With `timezone=auto`, Open-Meteo returns local times with no offset
/// ("2026-09-12T17:00", "2026-09-12"). Reading them as UTC shifts every
/// time by the location's UTC offset. The IANA name keeps a DST change
/// inside a 16-day forecast correct; the fixed offset is only a fallback
/// for a name Foundation does not recognize.
struct OpenMeteoTimeParser {
    let timeZone: TimeZone
    private let dateTimeFormatter: DateFormatter
    private let dateFormatter: DateFormatter

    init(timezone identifier: String, utcOffsetSeconds: Int?) {
        let zone = TimeZone(identifier: identifier)
            ?? utcOffsetSeconds.flatMap { TimeZone(secondsFromGMT: $0) }
            ?? .gmt
        timeZone = zone
        dateTimeFormatter = Self.formatter("yyyy-MM-dd'T'HH:mm", in: zone)
        dateFormatter = Self.formatter("yyyy-MM-dd", in: zone)
    }

    func dateTime(_ string: String) -> Date? {
        dateTimeFormatter.date(from: string)
    }

    func date(_ string: String) -> Date? {
        dateFormatter.date(from: string)
    }

    private static func formatter(_ format: String, in zone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = zone
        formatter.dateFormat = format
        return formatter
    }
}

// MARK: - API Response Models

private struct CurrentWeatherResponse: Codable {
    public let latitude: Double
    public let longitude: Double
    public let timezone: String
    public let utc_offset_seconds: Int?
    public let current: CurrentData?

    public struct CurrentData: Codable, Sendable {
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
    public let utc_offset_seconds: Int?
    public let daily: DailyData?

    public struct DailyData: Codable, Sendable {
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
    public let utc_offset_seconds: Int?
    public let hourly: HourlyData?

    public struct HourlyData: Codable, Sendable {
        let time: [String]
        let temperature_2m: [Double]
        let precipitation_probability: [Int]
        let weather_code: [Int]
    }
}

private struct GeocodeResponse: Codable {
    public let results: [GeocodeResult]?

    public struct GeocodeResult: Codable, Sendable {
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

private struct DetailedWeatherResponse: Codable {
    public let latitude: Double
    public let longitude: Double
    public let timezone: String
    public let utc_offset_seconds: Int?
    public let current: DetailedCurrentData?
    public let hourly: DetailedHourlyData?

    public struct DetailedCurrentData: Codable, Sendable {
        let time: String
        let temperature_2m: Double
        let relative_humidity_2m: Double
        let apparent_temperature: Double
        let weather_code: Int
        let wind_speed_10m: Double
        let wind_direction_10m: Double
        let wind_gusts_10m: Double?
        let pressure_msl: Double?
        let cloud_cover: Double?
        let uv_index: Double?
    }

    public struct DetailedHourlyData: Codable, Sendable {
        let time: [String]?
        let visibility: [Double]?
        let dew_point_2m: [Double]?
    }
}
