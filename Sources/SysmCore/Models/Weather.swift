import Foundation

// MARK: - Public Models

/// Current weather conditions for a location.
public struct CurrentWeather: Codable {
    public let location: String
    public let latitude: Double
    public let longitude: Double
    public let temperature: Double
    public let apparentTemperature: Double
    public let humidity: Int
    public let windSpeed: Double
    public let windDirection: Int
    public let condition: WeatherCondition
    public let time: Date
    public let timezone: String

    public func formatted() -> String {
        let tempF = temperature
        let tempC = fahrenheitToCelsius(tempF)
        let feelsF = apparentTemperature
        let feelsC = fahrenheitToCelsius(feelsF)

        return """
        Weather for \(location)
          Temperature: \(Int(tempF))°F (\(Int(tempC))°C)
          Feels like: \(Int(feelsF))°F (\(Int(feelsC))°C)
          Humidity: \(humidity)%
          Wind: \(Int(windSpeed)) mph \(windDirectionString(windDirection))
          Conditions: \(condition.description)

          Updated: \(formattedTime(time, timezone: timezone))
        """
    }
}

/// Multi-day weather forecast for a location.
public struct Forecast: Codable {
    public let location: String
    public let days: [DayForecast]
    public let timezone: String

    public func formatted() -> String {
        var lines = ["7-Day Forecast for \(location)", ""]
        for day in days {
            let highF = Int(day.high)
            let lowF = Int(day.low)
            let dateStr = shortDate(day.date, timezone: timezone)
            let precip = day.precipitation > 0 ? String(format: " (%.1f\")", day.precipitation) : ""
            lines.append("  \(dateStr)  \(day.condition.emoji)  \(highF)°/\(lowF)°  \(day.condition.description)\(precip)")
        }
        return lines.joined(separator: "\n")
    }
}

/// Weather forecast for a single day.
public struct DayForecast: Codable {
    public let date: Date
    public let high: Double
    public let low: Double
    public let condition: WeatherCondition
    public let precipitation: Double
    public let sunrise: Date
    public let sunset: Date
}

/// Hourly weather forecast for a location.
public struct HourlyForecast: Codable {
    public let location: String
    public let hours: [HourForecast]
    public let timezone: String

    public func formatted() -> String {
        var lines = ["Hourly Forecast for \(location)", ""]
        for hour in hours {
            let tempF = Int(hour.temperature)
            let timeStr = hourTime(hour.time, timezone: timezone)
            let precip = hour.precipitationProbability > 0 ? " \(hour.precipitationProbability)%" : ""
            lines.append("  \(timeStr)  \(hour.condition.emoji)  \(tempF)°F  \(hour.condition.description)\(precip)")
        }
        return lines.joined(separator: "\n")
    }
}

/// Weather forecast for a single hour.
public struct HourForecast: Codable {
    public let time: Date
    public let temperature: Double
    public let precipitationProbability: Int
    public let condition: WeatherCondition
}

/// Weather alert (severe weather warning).
public struct WeatherAlert: Codable {
    public let id: String
    public let event: String
    public let severity: AlertSeverity
    public let urgency: AlertUrgency
    public let headline: String
    public let description: String
    public let source: String
    public let effectiveTime: Date
    public let expiresTime: Date
    public let affectedRegions: [String]

    public init(
        id: String,
        event: String,
        severity: AlertSeverity,
        urgency: AlertUrgency,
        headline: String,
        description: String,
        source: String,
        effectiveTime: Date,
        expiresTime: Date,
        affectedRegions: [String]
    ) {
        self.id = id
        self.event = event
        self.severity = severity
        self.urgency = urgency
        self.headline = headline
        self.description = description
        self.source = source
        self.effectiveTime = effectiveTime
        self.expiresTime = expiresTime
        self.affectedRegions = affectedRegions
    }

    public func formatted() -> String {
        let df = DateFormatter()
        df.dateFormat = "MMM d, h:mm a"

        return """
        [\(severity.emoji) \(severity.rawValue.uppercased())] \(event)
          \(headline)
          Source: \(source)
          Effective: \(df.string(from: effectiveTime))
          Expires: \(df.string(from: expiresTime))
          Regions: \(affectedRegions.joined(separator: ", "))
        """
    }
}

/// Alert severity levels.
public enum AlertSeverity: String, Codable {
    case extreme
    case severe
    case moderate
    case minor
    case unknown

    public var emoji: String {
        switch self {
        case .extreme: return "🔴"
        case .severe: return "🟠"
        case .moderate: return "🟡"
        case .minor: return "🟢"
        case .unknown: return "⚪"
        }
    }
}

/// Alert urgency levels.
public enum AlertUrgency: String, Codable {
    case immediate
    case expected
    case future
    case past
    case unknown
}

/// Detailed weather including UV index and air quality.
public struct DetailedWeather: Codable {
    public let location: String
    public let latitude: Double
    public let longitude: Double
    public let temperature: Double
    public let apparentTemperature: Double
    public let humidity: Int
    public let windSpeed: Double
    public let windDirection: Int
    public let windGust: Double?
    public let pressure: Double
    public let dewPoint: Double
    public let visibility: Double
    public let uvIndex: Int
    public let uvIndexDescription: String
    public let cloudCover: Int
    public let condition: WeatherCondition
    public let time: Date
    public let timezone: String

    public init(
        location: String,
        latitude: Double,
        longitude: Double,
        temperature: Double,
        apparentTemperature: Double,
        humidity: Int,
        windSpeed: Double,
        windDirection: Int,
        windGust: Double?,
        pressure: Double,
        dewPoint: Double,
        visibility: Double,
        uvIndex: Int,
        uvIndexDescription: String,
        cloudCover: Int,
        condition: WeatherCondition,
        time: Date,
        timezone: String
    ) {
        self.location = location
        self.latitude = latitude
        self.longitude = longitude
        self.temperature = temperature
        self.apparentTemperature = apparentTemperature
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.windDirection = windDirection
        self.windGust = windGust
        self.pressure = pressure
        self.dewPoint = dewPoint
        self.visibility = visibility
        self.uvIndex = uvIndex
        self.uvIndexDescription = uvIndexDescription
        self.cloudCover = cloudCover
        self.condition = condition
        self.time = time
        self.timezone = timezone
    }

    public func formatted() -> String {
        let tempF = temperature
        let tempC = (tempF - 32) * 5 / 9
        let feelsF = apparentTemperature
        let feelsC = (feelsF - 32) * 5 / 9
        let dewF = dewPoint
        let dewC = (dewF - 32) * 5 / 9

        var lines = [
            "Detailed Weather for \(location)",
            "",
            "Temperature: \(Int(tempF))°F (\(Int(tempC))°C)",
            "Feels like: \(Int(feelsF))°F (\(Int(feelsC))°C)",
            "Humidity: \(humidity)%",
            "Dew point: \(Int(dewF))°F (\(Int(dewC))°C)",
            "",
            "Wind: \(Int(windSpeed)) mph \(windDirectionStr(windDirection))",
        ]

        if let gust = windGust, gust > 0 {
            lines.append("Wind gusts: \(Int(gust)) mph")
        }

        lines += [
            "",
            "Pressure: \(String(format: "%.2f", pressure)) inHg",
            "Visibility: \(String(format: "%.1f", visibility)) mi",
            "Cloud cover: \(cloudCover)%",
            "",
            "UV Index: \(uvIndex) (\(uvIndexDescription))",
            "",
            "Conditions: \(condition.emoji) \(condition.description)",
        ]

        return lines.joined(separator: "\n")
    }

    private func windDirectionStr(_ degrees: Int) -> String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                          "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((Double(degrees) + 11.25) / 22.5) % 16
        return directions[index]
    }
}

/// UV index description helper
public func uvIndexDescription(_ index: Int) -> String {
    switch index {
    case 0...2: return "Low"
    case 3...5: return "Moderate"
    case 6...7: return "High"
    case 8...10: return "Very High"
    default: return "Extreme"
    }
}

/// Geographic coordinates with location metadata.
public struct Coordinates: Codable {
    public let latitude: Double
    public let longitude: Double
    public let name: String
    public let country: String?
    public let admin1: String?

    public var displayName: String {
        var parts = [name]
        if let admin1 = admin1 {
            parts.append(admin1)
        }
        if let country = country {
            parts.append(country)
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Weather Condition (WMO Weather Codes)

/// Weather condition based on WMO (World Meteorological Organization) codes.
public enum WeatherCondition: Int, Codable {
    case clear = 0
    case mainlyClear = 1
    case partlyCloudy = 2
    case overcast = 3
    case fog = 45
    case depositingRimeFog = 48
    case drizzleLight = 51
    case drizzleModerate = 53
    case drizzleDense = 55
    case freezingDrizzleLight = 56
    case freezingDrizzleDense = 57
    case rainSlight = 61
    case rainModerate = 63
    case rainHeavy = 65
    case freezingRainLight = 66
    case freezingRainHeavy = 67
    case snowSlight = 71
    case snowModerate = 73
    case snowHeavy = 75
    case snowGrains = 77
    case rainShowersSlight = 80
    case rainShowersModerate = 81
    case rainShowersViolent = 82
    case snowShowersSlight = 85
    case snowShowersHeavy = 86
    case thunderstorm = 95
    case thunderstormWithHailSlight = 96
    case thunderstormWithHailHeavy = 99

    public var description: String {
        switch self {
        case .clear: return "Clear"
        case .mainlyClear: return "Mainly clear"
        case .partlyCloudy: return "Partly cloudy"
        case .overcast: return "Overcast"
        case .fog, .depositingRimeFog: return "Fog"
        case .drizzleLight, .drizzleModerate, .drizzleDense: return "Drizzle"
        case .freezingDrizzleLight, .freezingDrizzleDense: return "Freezing drizzle"
        case .rainSlight: return "Light rain"
        case .rainModerate: return "Rain"
        case .rainHeavy: return "Heavy rain"
        case .freezingRainLight, .freezingRainHeavy: return "Freezing rain"
        case .snowSlight: return "Light snow"
        case .snowModerate: return "Snow"
        case .snowHeavy: return "Heavy snow"
        case .snowGrains: return "Snow grains"
        case .rainShowersSlight, .rainShowersModerate: return "Rain showers"
        case .rainShowersViolent: return "Violent rain showers"
        case .snowShowersSlight, .snowShowersHeavy: return "Snow showers"
        case .thunderstorm: return "Thunderstorm"
        case .thunderstormWithHailSlight, .thunderstormWithHailHeavy: return "Thunderstorm with hail"
        }
    }

    public var emoji: String {
        switch self {
        case .clear, .mainlyClear: return "☀️"
        case .partlyCloudy: return "🌤️"
        case .overcast: return "☁️"
        case .fog, .depositingRimeFog: return "🌫️"
        case .drizzleLight, .drizzleModerate, .drizzleDense: return "🌧️"
        case .freezingDrizzleLight, .freezingDrizzleDense: return "🌧️"
        case .rainSlight, .rainModerate, .rainHeavy: return "🌧️"
        case .freezingRainLight, .freezingRainHeavy: return "🌧️"
        case .snowSlight, .snowModerate, .snowHeavy, .snowGrains: return "🌨️"
        case .rainShowersSlight, .rainShowersModerate, .rainShowersViolent: return "🌦️"
        case .snowShowersSlight, .snowShowersHeavy: return "🌨️"
        case .thunderstorm, .thunderstormWithHailSlight, .thunderstormWithHailHeavy: return "⛈️"
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)
        self = WeatherCondition(rawValue: rawValue) ?? .clear
    }
}

// MARK: - Weather Errors

public enum WeatherError: LocalizedError {
    case locationNotFound(String)
    case networkError(String)
    case apiError(String)
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .locationNotFound(let location):
            return "Could not find location '\(location)'. Try city name or lat,lon format."
        case .networkError(let message):
            return "Network error: \(message)"
        case .apiError(let message):
            return "Weather service error: \(message)"
        case .invalidResponse:
            return "Invalid response from weather service"
        }
    }
}

// MARK: - Helper Functions

private func fahrenheitToCelsius(_ f: Double) -> Double {
    return (f - 32) * 5 / 9
}

private func windDirectionString(_ degrees: Int) -> String {
    let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                      "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
    let index = Int((Double(degrees) + 11.25) / 22.5) % 16
    return directions[index]
}

private func formattedTime(_ date: Date, timezone: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm"
    if let tz = TimeZone(identifier: timezone) {
        formatter.timeZone = tz
    }
    return formatter.string(from: date)
}

private func shortDate(_ date: Date, timezone: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEE dd"
    if let tz = TimeZone(identifier: timezone) {
        formatter.timeZone = tz
    }
    return formatter.string(from: date)
}

private func hourTime(_ date: Date, timezone: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    if let tz = TimeZone(identifier: timezone) {
        formatter.timeZone = tz
    }
    return formatter.string(from: date)
}

// MARK: - Coordinate Parsing

/// Parses a "lat,lon" string into Coordinates.
/// - Parameter input: String in format "lat,lon" (e.g., "37.7749,-122.4194")
/// - Returns: Coordinates if valid, nil otherwise
func parseCoordinates(_ input: String) -> Coordinates? {
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
