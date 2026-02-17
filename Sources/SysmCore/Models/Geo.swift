import Foundation

public struct GeoLocation: Codable {
    public let latitude: Double
    public let longitude: Double
    public let name: String
    public let street: String?
    public let city: String?
    public let state: String?
    public let postalCode: String?
    public let country: String?
    public let countryCode: String?
    public let timezone: String?

    public init(latitude: Double, longitude: Double, name: String, street: String? = nil,
                city: String? = nil, state: String? = nil, postalCode: String? = nil,
                country: String? = nil, countryCode: String? = nil, timezone: String? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.name = name
        self.street = street
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.country = country
        self.countryCode = countryCode
        self.timezone = timezone
    }
}

public enum GeoError: LocalizedError {
    case locationNotFound(String)
    case invalidCoordinates(Double, Double)
    case geocodingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .locationNotFound(let query):
            return "Location not found: '\(query)'"
        case .invalidCoordinates(let lat, let lon):
            return "Invalid coordinates: \(lat), \(lon) (latitude must be -90..90, longitude -180..180)"
        case .geocodingFailed(let message):
            return "Geocoding failed: \(message)"
        }
    }
}
