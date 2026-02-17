import XCTest
@testable import SysmCore

final class GeoModelTests: XCTestCase {

    // MARK: - GeoLocation Codable

    func testGeoLocationCodableAllFields() throws {
        let loc = GeoLocation(
            latitude: 37.7749, longitude: -122.4194, name: "San Francisco",
            street: "123 Market St", city: "San Francisco", state: "CA",
            postalCode: "94105", country: "United States", countryCode: "US",
            timezone: "America/Los_Angeles"
        )
        let data = try JSONEncoder().encode(loc)
        let decoded = try JSONDecoder().decode(GeoLocation.self, from: data)
        XCTAssertEqual(decoded.latitude, 37.7749)
        XCTAssertEqual(decoded.longitude, -122.4194)
        XCTAssertEqual(decoded.name, "San Francisco")
        XCTAssertEqual(decoded.street, "123 Market St")
        XCTAssertEqual(decoded.city, "San Francisco")
        XCTAssertEqual(decoded.state, "CA")
        XCTAssertEqual(decoded.postalCode, "94105")
        XCTAssertEqual(decoded.country, "United States")
        XCTAssertEqual(decoded.countryCode, "US")
        XCTAssertEqual(decoded.timezone, "America/Los_Angeles")
    }

    func testGeoLocationCodableOptionals() throws {
        let loc = GeoLocation(latitude: 0.0, longitude: 0.0, name: "Null Island")
        let data = try JSONEncoder().encode(loc)
        let decoded = try JSONDecoder().decode(GeoLocation.self, from: data)
        XCTAssertEqual(decoded.name, "Null Island")
        XCTAssertNil(decoded.street)
        XCTAssertNil(decoded.city)
        XCTAssertNil(decoded.state)
        XCTAssertNil(decoded.postalCode)
        XCTAssertNil(decoded.country)
        XCTAssertNil(decoded.countryCode)
        XCTAssertNil(decoded.timezone)
    }

    // MARK: - GeoError descriptions

    func testGeoErrorLocationNotFound() {
        let error = GeoError.locationNotFound("Narnia")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Narnia"))
    }

    func testGeoErrorInvalidCoordinates() {
        let error = GeoError.invalidCoordinates(91.0, 200.0)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("91"))
    }

    func testGeoErrorGeocodingFailed() {
        let error = GeoError.geocodingFailed("Network timeout")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Network timeout"))
    }
}
