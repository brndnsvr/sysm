import XCTest
@testable import SysmCore

final class WeatherModelTests: XCTestCase {

    // MARK: - uvIndexDescription

    func testUVIndexLow() {
        XCTAssertEqual(uvIndexDescription(0), "Low")
        XCTAssertEqual(uvIndexDescription(1), "Low")
        XCTAssertEqual(uvIndexDescription(2), "Low")
    }

    func testUVIndexModerate() {
        XCTAssertEqual(uvIndexDescription(3), "Moderate")
        XCTAssertEqual(uvIndexDescription(4), "Moderate")
        XCTAssertEqual(uvIndexDescription(5), "Moderate")
    }

    func testUVIndexHigh() {
        XCTAssertEqual(uvIndexDescription(6), "High")
        XCTAssertEqual(uvIndexDescription(7), "High")
    }

    func testUVIndexVeryHigh() {
        XCTAssertEqual(uvIndexDescription(8), "Very High")
        XCTAssertEqual(uvIndexDescription(9), "Very High")
        XCTAssertEqual(uvIndexDescription(10), "Very High")
    }

    func testUVIndexExtreme() {
        XCTAssertEqual(uvIndexDescription(11), "Extreme")
        XCTAssertEqual(uvIndexDescription(15), "Extreme")
    }

    // MARK: - parseCoordinates

    func testParseValidCoordinates() {
        let result = parseCoordinates("37.7749,-122.4194")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.latitude, 37.7749, accuracy: 0.0001)
        XCTAssertEqual(result!.longitude, -122.4194, accuracy: 0.0001)
    }

    func testParseCoordinatesWithSpaces() {
        let result = parseCoordinates("37.7749, -122.4194")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.latitude, 37.7749, accuracy: 0.0001)
        XCTAssertEqual(result!.longitude, -122.4194, accuracy: 0.0001)
    }

    func testParseInvalidFormat() {
        XCTAssertNil(parseCoordinates("not-a-coord"))
        XCTAssertNil(parseCoordinates("37.7749"))
        XCTAssertNil(parseCoordinates(""))
        XCTAssertNil(parseCoordinates("a,b"))
        XCTAssertNil(parseCoordinates("37.7749,"))
    }

    func testParseOutOfRange() {
        XCTAssertNil(parseCoordinates("91.0,0.0"))
        XCTAssertNil(parseCoordinates("-91.0,0.0"))
        XCTAssertNil(parseCoordinates("0.0,181.0"))
        XCTAssertNil(parseCoordinates("0.0,-181.0"))
    }

    func testParseBoundaryValues() {
        XCTAssertNotNil(parseCoordinates("90.0,180.0"))
        XCTAssertNotNil(parseCoordinates("-90.0,-180.0"))
        XCTAssertNotNil(parseCoordinates("0.0,0.0"))
    }

    // MARK: - WeatherCondition

    func testWeatherConditionRawValueInit() {
        XCTAssertEqual(WeatherCondition(rawValue: 0), .clear)
        XCTAssertEqual(WeatherCondition(rawValue: 3), .overcast)
        XCTAssertEqual(WeatherCondition(rawValue: 95), .thunderstorm)
        XCTAssertNil(WeatherCondition(rawValue: 999))
    }

    func testWeatherConditionDescription() {
        XCTAssertEqual(WeatherCondition.clear.description, "Clear")
        XCTAssertEqual(WeatherCondition.partlyCloudy.description, "Partly cloudy")
        XCTAssertEqual(WeatherCondition.rainHeavy.description, "Heavy rain")
        XCTAssertEqual(WeatherCondition.thunderstorm.description, "Thunderstorm")
    }

    func testWeatherConditionEmoji() {
        XCTAssertEqual(WeatherCondition.clear.emoji, "☀️")
        XCTAssertEqual(WeatherCondition.partlyCloudy.emoji, "🌤️")
        XCTAssertEqual(WeatherCondition.overcast.emoji, "☁️")
        XCTAssertEqual(WeatherCondition.snowHeavy.emoji, "🌨️")
        XCTAssertEqual(WeatherCondition.thunderstorm.emoji, "⛈️")
    }

    func testWeatherConditionCodableDecodesUnknownAsDefault() throws {
        // Unknown weather code 999 should decode as .clear (the default)
        let json = "999"
        let data = json.data(using: .utf8)!
        let condition = try JSONDecoder().decode(WeatherCondition.self, from: data)
        XCTAssertEqual(condition, .clear)
    }

    func testWeatherConditionCodableRoundTrip() throws {
        let original = WeatherCondition.thunderstormWithHailHeavy
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WeatherCondition.self, from: data)
        XCTAssertEqual(original, decoded)
    }

    // MARK: - DetailedWeather.formatted()

    func testDetailedWeatherFormatted() {
        let weather = DetailedWeather(
            location: "San Francisco",
            latitude: 37.7749,
            longitude: -122.4194,
            temperature: 68.0,
            apparentTemperature: 65.0,
            humidity: 72,
            windSpeed: 12.0,
            windDirection: 270,
            windGust: nil,
            pressure: 30.12,
            dewPoint: 55.0,
            visibility: 10.0,
            uvIndex: 5,
            uvIndexDescription: "Moderate",
            cloudCover: 45,
            condition: .partlyCloudy,
            time: Date(),
            timezone: "America/Los_Angeles"
        )

        let output = weather.formatted()
        XCTAssertTrue(output.contains("San Francisco"))
        XCTAssertTrue(output.contains("68°F"))
        XCTAssertTrue(output.contains("20°C"))
        XCTAssertTrue(output.contains("Humidity: 72%"))
        XCTAssertTrue(output.contains("12 mph"))
        XCTAssertTrue(output.contains("UV Index: 5"))
        XCTAssertFalse(output.contains("Wind gusts"))
    }

    func testDetailedWeatherFormattedWithGust() {
        let weather = DetailedWeather(
            location: "Chicago",
            latitude: 41.8781,
            longitude: -87.6298,
            temperature: 32.0,
            apparentTemperature: 20.0,
            humidity: 85,
            windSpeed: 25.0,
            windDirection: 180,
            windGust: 40.0,
            pressure: 29.92,
            dewPoint: 28.0,
            visibility: 5.0,
            uvIndex: 1,
            uvIndexDescription: "Low",
            cloudCover: 100,
            condition: .overcast,
            time: Date(),
            timezone: "America/Chicago"
        )

        let output = weather.formatted()
        XCTAssertTrue(output.contains("Wind gusts: 40 mph"))
    }

    // MARK: - Coordinates.displayName

    func testCoordinatesDisplayNameFull() {
        let coords = Coordinates(latitude: 37.7749, longitude: -122.4194, name: "San Francisco", country: "US", admin1: "California")
        XCTAssertEqual(coords.displayName, "San Francisco, California, US")
    }

    func testCoordinatesDisplayNameNoAdmin1() {
        let coords = Coordinates(latitude: 0, longitude: 0, name: "Test", country: "US", admin1: nil)
        XCTAssertEqual(coords.displayName, "Test, US")
    }

    func testCoordinatesDisplayNameNoCountry() {
        let coords = Coordinates(latitude: 0, longitude: 0, name: "Test", country: nil, admin1: "State")
        XCTAssertEqual(coords.displayName, "Test, State")
    }

    func testCoordinatesDisplayNameNameOnly() {
        let coords = Coordinates(latitude: 0, longitude: 0, name: "Test", country: nil, admin1: nil)
        XCTAssertEqual(coords.displayName, "Test")
    }

    // MARK: - AlertSeverity.emoji

    func testAlertSeverityEmoji() {
        XCTAssertEqual(AlertSeverity.extreme.emoji, "🔴")
        XCTAssertEqual(AlertSeverity.severe.emoji, "🟠")
        XCTAssertEqual(AlertSeverity.moderate.emoji, "🟡")
        XCTAssertEqual(AlertSeverity.minor.emoji, "🟢")
        XCTAssertEqual(AlertSeverity.unknown.emoji, "⚪")
    }

    // MARK: - CurrentWeather.formatted()

    func testCurrentWeatherFormatted() throws {
        let json = """
        {
            "location": "Portland",
            "latitude": 45.5231,
            "longitude": -122.6765,
            "temperature": 55.0,
            "apparentTemperature": 52.0,
            "humidity": 80,
            "windSpeed": 8.0,
            "windDirection": 0,
            "condition": 2,
            "time": "2024-06-15T12:00:00Z",
            "timezone": "America/Los_Angeles"
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let weather = try decoder.decode(CurrentWeather.self, from: json.data(using: .utf8)!)
        let output = weather.formatted()

        XCTAssertTrue(output.contains("Portland"))
        XCTAssertTrue(output.contains("55°F"))
        XCTAssertTrue(output.contains("12°C"))
        XCTAssertTrue(output.contains("Humidity: 80%"))
        XCTAssertTrue(output.contains("8 mph"))
        XCTAssertTrue(output.contains("N"))
    }

    // MARK: - WeatherError

    func testWeatherErrorDescriptions() {
        XCTAssertNotNil(WeatherError.locationNotFound("NYC").errorDescription)
        XCTAssertTrue(WeatherError.locationNotFound("NYC").errorDescription!.contains("NYC"))
        XCTAssertNotNil(WeatherError.networkError("timeout").errorDescription)
        XCTAssertNotNil(WeatherError.apiError("rate limit").errorDescription)
        XCTAssertNotNil(WeatherError.invalidResponse.errorDescription)
    }
}
