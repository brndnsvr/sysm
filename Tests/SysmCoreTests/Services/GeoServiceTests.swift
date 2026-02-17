import XCTest
@testable import SysmCore

final class GeoServiceTests: XCTestCase {

    // MARK: - distance() (nonisolated, uses CLLocation)

    func testDistanceKnownCoordinates() {
        let service = GeoService()
        // NYC (40.7128, -74.0060) to London (51.5074, -0.1278)
        // ~5570 km
        let dist = service.distance(lat1: 40.7128, lon1: -74.0060, lat2: 51.5074, lon2: -0.1278)
        XCTAssertEqual(dist, 5570, accuracy: 50) // Within 50km
    }

    func testDistanceSamePoint() {
        let service = GeoService()
        let dist = service.distance(lat1: 37.7749, lon1: -122.4194, lat2: 37.7749, lon2: -122.4194)
        XCTAssertEqual(dist, 0.0, accuracy: 0.001)
    }

    func testDistanceAntipodal() {
        let service = GeoService()
        // North pole to south pole = ~20,000 km
        let dist = service.distance(lat1: 90.0, lon1: 0.0, lat2: -90.0, lon2: 0.0)
        XCTAssertEqual(dist, 20015, accuracy: 100) // Within 100km
    }

    func testDistanceShortRange() {
        let service = GeoService()
        // ~1km apart in SF
        let dist = service.distance(lat1: 37.7749, lon1: -122.4194, lat2: 37.7839, lon2: -122.4194)
        XCTAssertEqual(dist, 1.0, accuracy: 0.5) // Within 0.5km
    }

    func testDistanceReturnedInKm() {
        let service = GeoService()
        // Very short distance should be small number (km not meters)
        let dist = service.distance(lat1: 37.7749, lon1: -122.4194, lat2: 37.7750, lon2: -122.4194)
        XCTAssertLessThan(dist, 1.0) // Should be < 1km
        XCTAssertGreaterThan(dist, 0.0)
    }

    // MARK: - reverseGeocode() coordinate validation

    func testReverseGeocodeInvalidLatitude() async {
        let service = GeoService()
        do {
            _ = try await service.reverseGeocode(latitude: 91.0, longitude: 0.0)
            XCTFail("Expected invalidCoordinates error")
        } catch {
            guard case GeoError.invalidCoordinates = error else {
                XCTFail("Expected invalidCoordinates, got \(error)")
                return
            }
        }
    }

    func testReverseGeocodeInvalidLongitude() async {
        let service = GeoService()
        do {
            _ = try await service.reverseGeocode(latitude: 0.0, longitude: 181.0)
            XCTFail("Expected invalidCoordinates error")
        } catch {
            guard case GeoError.invalidCoordinates = error else {
                XCTFail("Expected invalidCoordinates, got \(error)")
                return
            }
        }
    }

    func testReverseGeocodeNegativeInvalidLatitude() async {
        let service = GeoService()
        do {
            _ = try await service.reverseGeocode(latitude: -91.0, longitude: 0.0)
            XCTFail("Expected invalidCoordinates error")
        } catch {
            guard case GeoError.invalidCoordinates = error else {
                XCTFail("Expected invalidCoordinates, got \(error)")
                return
            }
        }
    }

    func testReverseGeocodeBoundaryCoordinatesPass() async {
        // Boundary values should NOT throw invalidCoordinates
        // (they may throw geocodingFailed due to no network, but not invalidCoordinates)
        let service = GeoService()
        do {
            _ = try await service.reverseGeocode(latitude: 90.0, longitude: 180.0)
            // If it succeeds, that's fine
        } catch {
            // Should not be invalidCoordinates for valid boundary
            if case GeoError.invalidCoordinates = error {
                XCTFail("Boundary coordinates (90, 180) should be valid")
            }
            // geocodingFailed is acceptable (no network in test environment)
        }
    }
}
