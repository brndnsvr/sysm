import Foundation

/// Protocol defining weather service operations for fetching weather data.
///
/// This protocol provides access to weather data through external APIs (WeatherKit or Open-Meteo),
/// supporting current conditions, daily forecasts, hourly forecasts, weather alerts, and detailed
/// meteorological data including UV index and air quality.
///
/// ## Data Sources
///
/// Implementations may use:
/// - Apple WeatherKit API (requires API key)
/// - Open-Meteo API (free, no key required)
/// - Other weather data providers
///
/// ## Usage Example
///
/// ```swift
/// let service = WeatherService()
///
/// // Get current weather
/// let current = try await service.getCurrentWeather(location: "San Francisco, CA")
/// print("Temperature: \(current.temperature)°F")
/// print("Conditions: \(current.conditions)")
///
/// // Get forecast
/// let forecast = try await service.getForecast(location: "37.7749,-122.4194", days: 7)
/// for day in forecast.days {
///     print("\(day.date): High \(day.high)°F, Low \(day.low)°F")
/// }
///
/// // Get hourly forecast
/// let hourly = try await service.getHourlyForecast(location: "San Francisco", hours: 24)
///
/// // Check for weather alerts
/// let alerts = try await service.getAlerts(location: "94102")
/// for alert in alerts {
///     print("Alert: \(alert.title) - \(alert.severity)")
/// }
/// ```
///
/// ## Thread Safety
///
/// Implementations are marked as `Sendable` and safe to use across actor boundaries.
/// All weather operations are asynchronous.
///
/// ## Error Handling
///
/// Methods can throw ``WeatherError`` variants:
/// - ``WeatherError/invalidLocation(_:)`` - Location not found or invalid format
/// - ``WeatherError/apiError(_:)`` - Weather API returned an error
/// - ``WeatherError/networkError(_:)`` - Network connection failed
/// - ``WeatherError/authenticationFailed`` - API key invalid or missing
/// - ``WeatherError/rateLimitExceeded`` - Too many API requests
///
public protocol WeatherServiceProtocol: Sendable {
    // MARK: - Current Conditions

    /// Fetches current weather for a location.
    ///
    /// Returns real-time weather conditions including temperature, feels-like temperature,
    /// conditions description, humidity, wind, and pressure.
    ///
    /// - Parameter location: Location as city name, address, or coordinates (lat,lon).
    /// - Returns: ``CurrentWeather`` object with current conditions.
    /// - Throws:
    ///   - ``WeatherError/invalidLocation(_:)`` if location cannot be resolved.
    ///   - ``WeatherError/apiError(_:)`` if weather data fetch failed.
    ///   - ``WeatherError/networkError(_:)`` if network connection failed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // By city name
    /// let weather1 = try await service.getCurrentWeather(location: "Tokyo")
    ///
    /// // By coordinates
    /// let weather2 = try await service.getCurrentWeather(location: "35.6762,139.6503")
    ///
    /// // By ZIP code (US)
    /// let weather3 = try await service.getCurrentWeather(location: "10001")
    /// ```
    func getCurrentWeather(location: String) async throws -> CurrentWeather

    // MARK: - Forecasts

    /// Fetches a multi-day forecast for a location.
    ///
    /// Returns daily weather forecasts with high/low temperatures, conditions, precipitation
    /// probability, and other daily summary data.
    ///
    /// - Parameters:
    ///   - location: Location as city name, address, or coordinates (lat,lon).
    ///   - days: Number of days to forecast (typically 1-14 depending on provider).
    /// - Returns: ``Forecast`` object containing daily forecasts.
    /// - Throws:
    ///   - ``WeatherError/invalidLocation(_:)`` if location cannot be resolved.
    ///   - ``WeatherError/apiError(_:)`` if weather data fetch failed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let forecast = try await service.getForecast(location: "London", days: 7)
    /// print("7-day forecast for \(forecast.location):")
    /// for day in forecast.days {
    ///     print("  \(day.date): \(day.conditions), H:\(day.high)° L:\(day.low)°")
    /// }
    /// ```
    func getForecast(location: String, days: Int) async throws -> Forecast

    /// Fetches an hourly forecast for a location.
    ///
    /// Returns hour-by-hour weather forecast with temperature, conditions, precipitation
    /// probability, and wind information.
    ///
    /// - Parameters:
    ///   - location: Location as city name, address, or coordinates (lat,lon).
    ///   - hours: Number of hours to forecast (typically 1-48 depending on provider).
    /// - Returns: ``HourlyForecast`` object containing hourly forecasts.
    /// - Throws:
    ///   - ``WeatherError/invalidLocation(_:)`` if location cannot be resolved.
    ///   - ``WeatherError/apiError(_:)`` if weather data fetch failed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let hourly = try await service.getHourlyForecast(location: "Paris", hours: 24)
    /// print("Next 24 hours:")
    /// for hour in hourly.hours {
    ///     print("  \(hour.time): \(hour.temperature)°, \(hour.conditions)")
    /// }
    /// ```
    func getHourlyForecast(location: String, hours: Int) async throws -> HourlyForecast

    // MARK: - Alerts

    /// Fetches weather alerts for a location.
    ///
    /// Returns active weather alerts such as severe weather warnings, watches, and advisories.
    ///
    /// - Parameter location: Location as city name, address, or coordinates (lat,lon).
    /// - Returns: Array of ``WeatherAlert`` objects, empty if no active alerts.
    /// - Throws:
    ///   - ``WeatherError/invalidLocation(_:)`` if location cannot be resolved.
    ///   - ``WeatherError/apiError(_:)`` if alert data fetch failed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let alerts = try await service.getAlerts(location: "Miami, FL")
    /// if alerts.isEmpty {
    ///     print("No active weather alerts")
    /// } else {
    ///     print("\(alerts.count) active alerts:")
    ///     for alert in alerts {
    ///         print("  [\(alert.severity)] \(alert.title)")
    ///         print("    \(alert.description)")
    ///     }
    /// }
    /// ```
    func getAlerts(location: String) async throws -> [WeatherAlert]

    // MARK: - Detailed Data

    /// Fetches detailed weather data including UV index and air quality.
    ///
    /// Returns comprehensive weather information including current conditions plus additional
    /// data such as UV index, air quality index (AQI), visibility, dew point, and more.
    ///
    /// - Parameter location: Location as city name, address, or coordinates (lat,lon).
    /// - Returns: ``DetailedWeather`` object with comprehensive weather data.
    /// - Throws:
    ///   - ``WeatherError/invalidLocation(_:)`` if location cannot be resolved.
    ///   - ``WeatherError/apiError(_:)`` if weather data fetch failed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let detailed = try await service.getDetailedWeather(location: "Seattle")
    /// print("Temperature: \(detailed.temperature)°F")
    /// print("Feels like: \(detailed.feelsLike)°F")
    /// print("Humidity: \(detailed.humidity)%")
    /// print("UV Index: \(detailed.uvIndex)")
    /// print("AQI: \(detailed.airQualityIndex ?? "N/A")")
    /// print("Visibility: \(detailed.visibility) miles")
    /// print("Dew point: \(detailed.dewPoint)°F")
    /// ```
    ///
    /// ## Available Data
    ///
    /// DetailedWeather typically includes:
    /// - All current weather data
    /// - UV index and recommendations
    /// - Air quality index (AQI) and pollutant levels
    /// - Visibility distance
    /// - Dew point
    /// - Cloud cover percentage
    /// - Sunrise/sunset times
    func getDetailedWeather(location: String) async throws -> DetailedWeather
}
