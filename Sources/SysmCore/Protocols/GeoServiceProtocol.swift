import Foundation

/// Protocol for geocoding and location utilities.
public protocol GeoServiceProtocol: Sendable {
    /// Geocode an address string to coordinates.
    func geocode(_ address: String) async throws -> GeoLocation

    /// Reverse geocode coordinates to an address.
    func reverseGeocode(latitude: Double, longitude: Double) async throws -> GeoLocation

    /// Calculate distance between two coordinate pairs in kilometers.
    func distance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double
}
