import EventKit
import Foundation
import CoreLocation

/// Represents a location with optional geocoordinates for geofencing.
public struct StructuredLocation: Codable {
    public let title: String
    public let address: String?
    public let latitude: Double?
    public let longitude: Double?
    public let radius: Double? // meters

    public init(title: String, address: String? = nil,
                latitude: Double? = nil, longitude: Double? = nil,
                radius: Double? = 100.0) {
        self.title = title
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
    }

    public init?(from ekLocation: EKStructuredLocation) {
        guard let title = ekLocation.title else { return nil }
        self.title = title
        self.address = ekLocation.geoLocation?.description
        self.latitude = ekLocation.geoLocation?.coordinate.latitude
        self.longitude = ekLocation.geoLocation?.coordinate.longitude
        self.radius = ekLocation.radius
    }

    public func toEKStructuredLocation() -> EKStructuredLocation {
        let location = EKStructuredLocation(title: title)
        if let lat = latitude, let lon = longitude {
            location.geoLocation = CLLocation(latitude: lat, longitude: lon)
        }
        if let r = radius {
            location.radius = r
        }
        return location
    }
}
