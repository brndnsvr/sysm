import Foundation
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
        public let mediaType: String
        public let width: Int
        public let height: Int
        public let isFavorite: Bool

        public func formatted() -> String {
            let dateStr = creationDate.map { formatDate($0) } ?? "Unknown date"
            let fav = isFavorite ? " *" : ""
            return "\(filename) [\(width)x\(height)] \(dateStr)\(fav)"
        }

        private func formatDate(_ date: Date) -> String {
            DateFormatters.mediumDateTime.string(from: date)
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
            mediaType: mediaType,
            width: asset.pixelWidth,
            height: asset.pixelHeight,
            isFavorite: asset.isFavorite
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
