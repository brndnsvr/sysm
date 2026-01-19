import Foundation

/// Protocol defining weather service operations for fetching weather data.
///
/// Implementations fetch weather data from external APIs (WeatherKit or Open-Meteo),
/// supporting current conditions, daily forecasts, and hourly forecasts.
public protocol WeatherServiceProtocol: Sendable {
    /// Fetches current weather for a location.
    /// - Parameter location: Location name or coordinates (lat,lon).
    /// - Returns: Current weather conditions.
    func getCurrentWeather(location: String) async throws -> CurrentWeather

    /// Fetches a multi-day forecast for a location.
    /// - Parameters:
    ///   - location: Location name or coordinates (lat,lon).
    ///   - days: Number of days to forecast.
    /// - Returns: Daily forecast data.
    func getForecast(location: String, days: Int) async throws -> Forecast

    /// Fetches an hourly forecast for a location.
    /// - Parameters:
    ///   - location: Location name or coordinates (lat,lon).
    ///   - hours: Number of hours to forecast.
    /// - Returns: Hourly forecast data.
    func getHourlyForecast(location: String, hours: Int) async throws -> HourlyForecast
}
