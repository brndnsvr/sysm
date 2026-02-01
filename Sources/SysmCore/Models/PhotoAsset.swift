import Foundation

/// Represents a photo or video asset from the macOS Photos library.
public struct PhotoAsset: Codable, Sendable {
    public let id: String
    public let filename: String
    public let creationDate: Date?
    public let modificationDate: Date?
    public let mediaType: String
    public let width: Int
    public let height: Int
    public let duration: TimeInterval?
    public let isFavorite: Bool
    public let isHidden: Bool
    public let hasLocation: Bool

    public init(
        id: String,
        filename: String,
        creationDate: Date?,
        modificationDate: Date?,
        mediaType: String,
        width: Int,
        height: Int,
        duration: TimeInterval?,
        isFavorite: Bool,
        isHidden: Bool,
        hasLocation: Bool
    ) {
        self.id = id
        self.filename = filename
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        self.mediaType = mediaType
        self.width = width
        self.height = height
        self.duration = duration
        self.isFavorite = isFavorite
        self.isHidden = isHidden
        self.hasLocation = hasLocation
    }

    public func formatted() -> String {
        let dateStr = creationDate.map { DateFormatters.mediumDateTime.string(from: $0) } ?? "Unknown date"
        let fav = isFavorite ? " *" : ""
        let durationStr = duration.map { " (\(formatDuration($0)))" } ?? ""
        return "\(filename) [\(width)x\(height)]\(durationStr) \(dateStr)\(fav)"
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// Detailed metadata for a photo or video asset including EXIF data.
public struct AssetMetadata: Codable, Sendable {
    public let id: String
    public let filename: String
    public let fileSize: Int64?
    public let creationDate: Date?
    public let modificationDate: Date?
    public let mediaType: String
    public let width: Int
    public let height: Int
    public let duration: TimeInterval?

    // Location
    public let latitude: Double?
    public let longitude: Double?
    public let altitude: Double?

    // Camera info (EXIF)
    public let cameraMake: String?
    public let cameraModel: String?
    public let lensModel: String?
    public let focalLength: Double?
    public let aperture: Double?
    public let iso: Int?
    public let exposureTime: Double?

    // Status
    public let isFavorite: Bool
    public let isHidden: Bool
    public let isBurst: Bool
    public let isScreenshot: Bool
    public let isLivePhoto: Bool
    public let isHDR: Bool

    public init(
        id: String,
        filename: String,
        fileSize: Int64?,
        creationDate: Date?,
        modificationDate: Date?,
        mediaType: String,
        width: Int,
        height: Int,
        duration: TimeInterval?,
        latitude: Double?,
        longitude: Double?,
        altitude: Double?,
        cameraMake: String?,
        cameraModel: String?,
        lensModel: String?,
        focalLength: Double?,
        aperture: Double?,
        iso: Int?,
        exposureTime: Double?,
        isFavorite: Bool,
        isHidden: Bool,
        isBurst: Bool,
        isScreenshot: Bool,
        isLivePhoto: Bool,
        isHDR: Bool
    ) {
        self.id = id
        self.filename = filename
        self.fileSize = fileSize
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        self.mediaType = mediaType
        self.width = width
        self.height = height
        self.duration = duration
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.cameraMake = cameraMake
        self.cameraModel = cameraModel
        self.lensModel = lensModel
        self.focalLength = focalLength
        self.aperture = aperture
        self.iso = iso
        self.exposureTime = exposureTime
        self.isFavorite = isFavorite
        self.isHidden = isHidden
        self.isBurst = isBurst
        self.isScreenshot = isScreenshot
        self.isLivePhoto = isLivePhoto
        self.isHDR = isHDR
    }

    public var locationString: String? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return String(format: "%.6f, %.6f", lat, lon)
    }

    public var exposureString: String? {
        guard let exp = exposureTime else { return nil }
        if exp >= 1 {
            return String(format: "%.1f s", exp)
        } else {
            return String(format: "1/%.0f s", 1 / exp)
        }
    }

    public var apertureString: String? {
        guard let f = aperture else { return nil }
        return String(format: "f/%.1f", f)
    }
}
