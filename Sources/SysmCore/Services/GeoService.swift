import CoreLocation
import Foundation

public actor GeoService: GeoServiceProtocol {
    private let geocoder = CLGeocoder()

    public init() {}

    public func geocode(_ address: String) async throws -> GeoLocation {
        do {
            let placemarks = try await geocoder.geocodeAddressString(address)

            guard let placemark = placemarks.first,
                  let location = placemark.location else {
                throw GeoError.locationNotFound(address)
            }

            return geoLocation(from: placemark, location: location)
        } catch let error as GeoError {
            throw error
        } catch {
            throw GeoError.geocodingFailed(error.localizedDescription)
        }
    }

    public func reverseGeocode(latitude: Double, longitude: Double) async throws -> GeoLocation {
        guard latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180 else {
            throw GeoError.invalidCoordinates(latitude, longitude)
        }

        let clLocation = CLLocation(latitude: latitude, longitude: longitude)

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(clLocation)

            guard let placemark = placemarks.first else {
                throw GeoError.locationNotFound("\(latitude), \(longitude)")
            }

            return geoLocation(from: placemark, location: clLocation)
        } catch let error as GeoError {
            throw error
        } catch {
            throw GeoError.geocodingFailed(error.localizedDescription)
        }
    }

    public nonisolated func distance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let loc1 = CLLocation(latitude: lat1, longitude: lon1)
        let loc2 = CLLocation(latitude: lat2, longitude: lon2)
        return loc1.distance(from: loc2) / 1000.0
    }

    // MARK: - Private

    private func geoLocation(from placemark: CLPlacemark, location: CLLocation) -> GeoLocation {
        let displayName = [
            placemark.name,
            placemark.locality,
            placemark.administrativeArea,
            placemark.country,
        ]
        .compactMap { $0 }
        .reduce(into: [String]()) { result, part in
            if !result.contains(part) { result.append(part) }
        }
        .joined(separator: ", ")

        return GeoLocation(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            name: displayName.isEmpty ? "\(location.coordinate.latitude), \(location.coordinate.longitude)" : displayName,
            street: [placemark.subThoroughfare, placemark.thoroughfare]
                .compactMap { $0 }
                .joined(separator: " ")
                .nilIfEmpty,
            city: placemark.locality,
            state: placemark.administrativeArea,
            postalCode: placemark.postalCode,
            country: placemark.country,
            countryCode: placemark.isoCountryCode,
            timezone: placemark.timeZone?.identifier
        )
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
