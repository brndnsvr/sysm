import Foundation

protocol WeatherServiceProtocol {
    func getCurrentWeather(location: String) async throws -> CurrentWeather
    func getForecast(location: String, days: Int) async throws -> Forecast
    func getHourlyForecast(location: String, hours: Int) async throws -> HourlyForecast
}
