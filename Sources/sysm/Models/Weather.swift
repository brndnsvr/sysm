import Foundation

// MARK: - Public Models

struct CurrentWeather: Codable {
    let location: String
    let latitude: Double
    let longitude: Double
    let temperature: Double
    let apparentTemperature: Double
    let humidity: Int
    let windSpeed: Double
    let windDirection: Int
    let condition: WeatherCondition
    let time: Date
    let timezone: String

    func formatted() -> String {
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

struct Forecast: Codable {
    let location: String
    let days: [DayForecast]
    let timezone: String

    func formatted() -> String {
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

struct DayForecast: Codable {
    let date: Date
    let high: Double
    let low: Double
    let condition: WeatherCondition
    let precipitation: Double
    let sunrise: Date
    let sunset: Date
}

struct HourlyForecast: Codable {
    let location: String
    let hours: [HourForecast]
    let timezone: String

    func formatted() -> String {
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

struct HourForecast: Codable {
    let time: Date
    let temperature: Double
    let precipitationProbability: Int
    let condition: WeatherCondition
}

struct Coordinates: Codable {
    let latitude: Double
    let longitude: Double
    let name: String
    let country: String?
    let admin1: String?

    var displayName: String {
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

enum WeatherCondition: Int, Codable {
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

    var description: String {
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

    var emoji: String {
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

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)
        self = WeatherCondition(rawValue: rawValue) ?? .clear
    }
}

// MARK: - Weather Errors

enum WeatherError: LocalizedError {
    case locationNotFound(String)
    case networkError(String)
    case apiError(String)
    case invalidResponse

    var errorDescription: String? {
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
