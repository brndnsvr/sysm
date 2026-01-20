import AVFoundation
import Foundation
import ImageIO
import Photos

public actor PhotosService: PhotosServiceProtocol {
    private let library = PHPhotoLibrary.shared()

    // MARK: - Models

    public struct PhotoAlbum: Codable {
        public let id: String
        public let title: String
        public let count: Int
        public let type: String

        public func formatted() -> String {
            return "\(title) (\(count) photos) [\(type)]"
        }
    }

    public struct PhotoAsset: Codable {
        public let id: String
        public let filename: String
        public let creationDate: Date?
        public let modificationDate: Date?
        public let mediaType: String
        public let width: Int
        public let height: Int
        public let duration: TimeInterval?  // For videos
        public let isFavorite: Bool
        public let isHidden: Bool
        public let hasLocation: Bool

        public func formatted() -> String {
            let dateStr = creationDate.map { formatDate($0) } ?? "Unknown date"
            let fav = isFavorite ? " *" : ""
            let durationStr = duration.map { " (\(formatDuration($0)))" } ?? ""
            return "\(filename) [\(width)x\(height)]\(durationStr) \(dateStr)\(fav)"
        }

        private func formatDate(_ date: Date) -> String {
            DateFormatters.mediumDateTime.string(from: date)
        }

        private func formatDuration(_ duration: TimeInterval) -> String {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    public struct AssetMetadata: Codable {
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

    // MARK: - Authorization

    public func ensureAccess() async throws {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch status {
        case .authorized, .limited:
            return
        case .notDetermined:
            let granted = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            if granted != .authorized && granted != .limited {
                throw PhotosError.accessDenied
            }
        case .denied, .restricted:
            throw PhotosError.accessDenied
        @unknown default:
            throw PhotosError.accessDenied
        }
    }

    // MARK: - Albums

    public func listAlbums() async throws -> [PhotoAlbum] {
        try await ensureAccess()

        var albums: [PhotoAlbum] = []

        // User albums
        let userAlbums = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: nil
        )

        userAlbums.enumerateObjects { collection, _, _ in
            let count = PHAsset.fetchAssets(in: collection, options: nil).count
            albums.append(PhotoAlbum(
                id: collection.localIdentifier,
                title: collection.localizedTitle ?? "Untitled",
                count: count,
                type: "Album"
            ))
        }

        // Smart albums
        let smartAlbums = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .any,
            options: nil
        )

        smartAlbums.enumerateObjects { collection, _, _ in
            // Skip empty smart albums and hidden
            let count = PHAsset.fetchAssets(in: collection, options: nil).count
            if count > 0, collection.assetCollectionSubtype != .smartAlbumAllHidden {
                albums.append(PhotoAlbum(
                    id: collection.localIdentifier,
                    title: collection.localizedTitle ?? "Untitled",
                    count: count,
                    type: "Smart Album"
                ))
            }
        }

        return albums.sorted { $0.title < $1.title }
    }

    // MARK: - Photos

    public func listPhotos(albumId: String?, limit: Int = 50) async throws -> [PhotoAsset] {
        try await ensureAccess()

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = limit

        let assets: PHFetchResult<PHAsset>

        if let albumId = albumId {
            let collections = PHAssetCollection.fetchAssetCollections(
                withLocalIdentifiers: [albumId],
                options: nil
            )
            guard let collection = collections.firstObject else {
                throw PhotosError.albumNotFound(albumId)
            }
            assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
        } else {
            assets = PHAsset.fetchAssets(with: fetchOptions)
        }

        var photos: [PhotoAsset] = []
        assets.enumerateObjects { asset, _, _ in
            photos.append(self.assetToPhoto(asset))
        }

        return photos
    }

    public func getRecentPhotos(limit: Int = 20) async throws -> [PhotoAsset] {
        try await ensureAccess()

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = limit
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

        let assets = PHAsset.fetchAssets(with: fetchOptions)

        var photos: [PhotoAsset] = []
        assets.enumerateObjects { asset, _, _ in
            photos.append(self.assetToPhoto(asset))
        }

        return photos
    }

    public func searchByDate(from: Date, to: Date, limit: Int = 50) async throws -> [PhotoAsset] {
        try await ensureAccess()

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = limit
        fetchOptions.predicate = NSPredicate(
            format: "creationDate >= %@ AND creationDate <= %@",
            from as NSDate,
            to as NSDate
        )

        let assets = PHAsset.fetchAssets(with: fetchOptions)

        var photos: [PhotoAsset] = []
        assets.enumerateObjects { asset, _, _ in
            photos.append(self.assetToPhoto(asset))
        }

        return photos
    }

    // MARK: - Export

    public func exportPhoto(assetId: String, outputPath: String) async throws {
        try await ensureAccess()

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
        guard let asset = assets.firstObject else {
            throw PhotosError.assetNotFound(assetId)
        }

        let options = PHImageRequestOptions()
        options.version = .current
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = true

        var exportError: Error?
        var exportedData: Data?

        PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, uti, _, info in
            if let error = info?[PHImageErrorKey] as? Error {
                exportError = error
            } else {
                exportedData = data
            }
        }

        if let error = exportError {
            throw PhotosError.exportFailed(error.localizedDescription)
        }

        guard let data = exportedData else {
            throw PhotosError.exportFailed("No image data available")
        }

        let url = URL(fileURLWithPath: outputPath)
        try data.write(to: url)
    }

    // MARK: - Videos

    public func listVideos(albumId: String?, limit: Int = 50) async throws -> [PhotoAsset] {
        try await ensureAccess()

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = limit
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)

        let assets: PHFetchResult<PHAsset>

        if let albumId = albumId {
            let collections = PHAssetCollection.fetchAssetCollections(
                withLocalIdentifiers: [albumId],
                options: nil
            )
            guard let collection = collections.firstObject else {
                throw PhotosError.albumNotFound(albumId)
            }
            // Combine predicates for album filtering
            let albumAssets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
            var videos: [PhotoAsset] = []
            albumAssets.enumerateObjects { asset, _, stop in
                if videos.count >= limit {
                    stop.pointee = true
                    return
                }
                videos.append(self.assetToPhoto(asset))
            }
            return videos
        } else {
            assets = PHAsset.fetchAssets(with: fetchOptions)
        }

        var videos: [PhotoAsset] = []
        assets.enumerateObjects { asset, _, _ in
            videos.append(self.assetToPhoto(asset))
        }

        return videos
    }

    public func getRecentVideos(limit: Int = 20) async throws -> [PhotoAsset] {
        try await ensureAccess()

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = limit
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)

        let assets = PHAsset.fetchAssets(with: fetchOptions)

        var videos: [PhotoAsset] = []
        assets.enumerateObjects { asset, _, _ in
            videos.append(self.assetToPhoto(asset))
        }

        return videos
    }

    // MARK: - Video Export

    public func exportVideo(assetId: String, outputPath: String) async throws {
        try await ensureAccess()

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
        guard let asset = assets.firstObject else {
            throw PhotosError.assetNotFound(assetId)
        }

        guard asset.mediaType == .video else {
            throw PhotosError.exportFailed("Asset is not a video")
        }

        let options = PHVideoRequestOptions()
        options.version = .current
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        return try await withCheckedThrowingContinuation { continuation in
            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: PhotosError.exportFailed(error.localizedDescription))
                    return
                }

                guard let urlAsset = avAsset as? AVURLAsset else {
                    continuation.resume(throwing: PhotosError.exportFailed("Unable to access video data"))
                    return
                }

                do {
                    let outputURL = URL(fileURLWithPath: outputPath)
                    try FileManager.default.copyItem(at: urlAsset.url, to: outputURL)
                    continuation.resume(returning: ())
                } catch {
                    continuation.resume(throwing: PhotosError.exportFailed(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Metadata

    public func getMetadata(assetId: String) async throws -> AssetMetadata {
        try await ensureAccess()

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
        guard let asset = assets.firstObject else {
            throw PhotosError.assetNotFound(assetId)
        }

        let resources = PHAssetResource.assetResources(for: asset)
        let filename = resources.first?.originalFilename ?? "Unknown"
        let fileSize = resources.first?.value(forKey: "fileSize") as? Int64

        let mediaType: String
        switch asset.mediaType {
        case .image: mediaType = "Image"
        case .video: mediaType = "Video"
        case .audio: mediaType = "Audio"
        default: mediaType = "Unknown"
        }

        let location = asset.location
        let isScreenshot = asset.mediaSubtypes.contains(.photoScreenshot)
        let isHDR = asset.mediaSubtypes.contains(.photoHDR)
        let isLivePhoto = asset.mediaSubtypes.contains(.photoLive)

        // Get EXIF data for images
        var cameraMake: String?
        var cameraModel: String?
        var lensModel: String?
        var focalLength: Double?
        var aperture: Double?
        var iso: Int?
        var exposureTime: Double?

        if asset.mediaType == .image {
            let imageOptions = PHImageRequestOptions()
            imageOptions.version = .current
            imageOptions.isSynchronous = true
            imageOptions.isNetworkAccessAllowed = true

            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: imageOptions) { data, _, _, _ in
                guard let data = data,
                      let source = CGImageSourceCreateWithData(data as CFData, nil),
                      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
                    return
                }

                if let exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] {
                    lensModel = exif[kCGImagePropertyExifLensModel as String] as? String
                    focalLength = exif[kCGImagePropertyExifFocalLength as String] as? Double
                    aperture = exif[kCGImagePropertyExifFNumber as String] as? Double
                    if let isoArray = exif[kCGImagePropertyExifISOSpeedRatings as String] as? [Int] {
                        iso = isoArray.first
                    }
                    exposureTime = exif[kCGImagePropertyExifExposureTime as String] as? Double
                }

                if let tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
                    cameraMake = tiff[kCGImagePropertyTIFFMake as String] as? String
                    cameraModel = tiff[kCGImagePropertyTIFFModel as String] as? String
                }
            }
        }

        return AssetMetadata(
            id: asset.localIdentifier,
            filename: filename,
            fileSize: fileSize,
            creationDate: asset.creationDate,
            modificationDate: asset.modificationDate,
            mediaType: mediaType,
            width: asset.pixelWidth,
            height: asset.pixelHeight,
            duration: asset.mediaType == .video ? asset.duration : nil,
            latitude: location?.coordinate.latitude,
            longitude: location?.coordinate.longitude,
            altitude: location?.altitude,
            cameraMake: cameraMake,
            cameraModel: cameraModel,
            lensModel: lensModel,
            focalLength: focalLength,
            aperture: aperture,
            iso: iso,
            exposureTime: exposureTime,
            isFavorite: asset.isFavorite,
            isHidden: asset.isHidden,
            isBurst: asset.representsBurst,
            isScreenshot: isScreenshot,
            isLivePhoto: isLivePhoto,
            isHDR: isHDR
        )
    }

    // MARK: - Private Helpers

    private func assetToPhoto(_ asset: PHAsset) -> PhotoAsset {
        let mediaType: String
        switch asset.mediaType {
        case .image: mediaType = "Image"
        case .video: mediaType = "Video"
        case .audio: mediaType = "Audio"
        default: mediaType = "Unknown"
        }

        let resources = PHAssetResource.assetResources(for: asset)
        let filename = resources.first?.originalFilename ?? "Unknown"

        return PhotoAsset(
            id: asset.localIdentifier,
            filename: filename,
            creationDate: asset.creationDate,
            modificationDate: asset.modificationDate,
            mediaType: mediaType,
            width: asset.pixelWidth,
            height: asset.pixelHeight,
            duration: asset.mediaType == .video ? asset.duration : nil,
            isFavorite: asset.isFavorite,
            isHidden: asset.isHidden,
            hasLocation: asset.location != nil
        )
    }
}

public enum PhotosError: LocalizedError {
    case accessDenied
    case albumNotFound(String)
    case assetNotFound(String)
    case exportFailed(String)

    public var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Photos access denied. Grant permission in System Settings > Privacy & Security > Photos"
        case .albumNotFound(let id):
            return "Album not found: \(id)"
        case .assetNotFound(let id):
            return "Photo not found: \(id)"
        case .exportFailed(let reason):
            return "Export failed: \(reason)"
        }
    }
}
