import AVFoundation
import Foundation
import ImageIO
import Photos

public actor PhotosService: PhotosServiceProtocol {
    private let library = PHPhotoLibrary.shared()

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

    public func createAlbum(name: String) async throws -> PhotoAlbum {
        try await ensureAccess()

        // Use a Sendable box to safely extract the placeholder ID from the performChanges closure
        let idBox = AlbumIdBox()

        try await library.performChanges {
            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
            idBox.value = request.placeholderForCreatedAssetCollection.localIdentifier
        }

        guard let id = idBox.value else {
            throw PhotosError.albumCreationFailed(name)
        }

        return PhotoAlbum(id: id, title: name, count: 0, type: "Album")
    }

    public func deleteAlbum(albumId: String) async throws -> Bool {
        try await ensureAccess()

        let collections = PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [albumId],
            options: nil
        )

        guard let collection = collections.firstObject else {
            throw PhotosError.albumNotFound(albumId)
        }

        // Cannot delete smart albums
        if collection.assetCollectionType == .smartAlbum {
            throw PhotosError.cannotModifySmartAlbum
        }

        try await library.performChanges {
            PHAssetCollectionChangeRequest.deleteAssetCollections([collection] as NSFastEnumeration)
        }

        return true
    }

    public func renameAlbum(albumId: String, newName: String) async throws -> Bool {
        try await ensureAccess()

        let collections = PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [albumId],
            options: nil
        )

        guard let collection = collections.firstObject else {
            throw PhotosError.albumNotFound(albumId)
        }

        // Cannot rename smart albums
        if collection.assetCollectionType == .smartAlbum {
            throw PhotosError.cannotModifySmartAlbum
        }

        try await library.performChanges {
            guard let request = PHAssetCollectionChangeRequest(for: collection) else {
                return
            }
            request.title = newName
        }

        return true
    }

    public func addPhotosToAlbum(albumId: String, assetIds: [String]) async throws -> Int {
        try await ensureAccess()

        let collections = PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [albumId],
            options: nil
        )

        guard let collection = collections.firstObject else {
            throw PhotosError.albumNotFound(albumId)
        }

        // Cannot modify smart albums
        if collection.assetCollectionType == .smartAlbum {
            throw PhotosError.cannotModifySmartAlbum
        }

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: assetIds, options: nil)

        try await library.performChanges {
            guard let request = PHAssetCollectionChangeRequest(for: collection) else {
                return
            }
            request.addAssets(assets)
        }

        return assets.count
    }

    public func removePhotosFromAlbum(albumId: String, assetIds: [String]) async throws -> Int {
        try await ensureAccess()

        let collections = PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [albumId],
            options: nil
        )

        guard let collection = collections.firstObject else {
            throw PhotosError.albumNotFound(albumId)
        }

        // Cannot modify smart albums
        if collection.assetCollectionType == .smartAlbum {
            throw PhotosError.cannotModifySmartAlbum
        }

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: assetIds, options: nil)

        try await library.performChanges {
            guard let request = PHAssetCollectionChangeRequest(for: collection) else {
                return
            }
            request.removeAssets(assets)
        }

        return assets.count
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

    // MARK: - People & Faces

    public func listPeople() async throws -> [PhotoPerson] {
        try await ensureAccess()

        var people: [PhotoPerson] = []

        // Fetch people using person type
        let personOptions = PHFetchOptions()
        let personCollections = PHCollection.fetchTopLevelUserCollections(with: personOptions)

        personCollections.enumerateObjects { collection, _, _ in
            if let personCollection = collection as? PHAssetCollection,
               personCollection.assetCollectionType == .album,
               personCollection.localizedTitle?.contains("People") == false {

                // This is a workaround - Photos doesn't expose person collections directly via PhotoKit on macOS
                // We can only access them indirectly
                let assetCount = PHAsset.fetchAssets(in: personCollection, options: nil).count
                if assetCount > 0 {
                    people.append(PhotoPerson(
                        id: personCollection.localIdentifier,
                        name: personCollection.localizedTitle,
                        photoCount: assetCount
                    ))
                }
            }
        }

        return people
    }

    public func searchByPerson(personName: String) async throws -> [PhotoAsset] {
        try await ensureAccess()

        // Note: PhotoKit on macOS has limited person/face detection API access
        // This is a best-effort implementation
        let people = try await listPeople()

        guard let person = people.first(where: {
            $0.name?.lowercased().contains(personName.lowercased()) == true
        }) else {
            return []
        }

        let collections = PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [person.id],
            options: nil
        )

        guard let collection = collections.firstObject else {
            return []
        }

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        let assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)

        var photos: [PhotoAsset] = []
        assets.enumerateObjects { asset, _, _ in
            photos.append(self.assetToPhoto(asset))
        }

        return photos
    }

    // MARK: - Metadata & Keywords

    public func setTitle(assetId: String, title: String) async throws -> Bool {
        try await ensureAccess()

        // PhotoKit on macOS does not expose APIs for editing photo metadata.
        // Throw an error with clear explanation rather than silently succeeding.
        throw PhotosError.metadataEditingNotSupported
    }

    public func setDescription(assetId: String, description: String) async throws -> Bool {
        try await ensureAccess()

        // PhotoKit on macOS does not expose APIs for editing photo metadata.
        // Throw an error with clear explanation rather than silently succeeding.
        throw PhotosError.metadataEditingNotSupported
    }

    public func setFavorite(assetId: String, isFavorite: Bool) async throws -> Bool {
        try await ensureAccess()

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
        guard let asset = assets.firstObject else {
            throw PhotosError.assetNotFound(assetId)
        }

        try await library.performChanges {
            let request = PHAssetChangeRequest(for: asset)
            request.isFavorite = isFavorite
        }

        return true
    }

    public func setHidden(assetId: String, isHidden: Bool) async throws -> Bool {
        try await ensureAccess()

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
        guard let asset = assets.firstObject else {
            throw PhotosError.assetNotFound(assetId)
        }

        try await library.performChanges {
            let request = PHAssetChangeRequest(for: asset)
            request.isHidden = isHidden
        }

        return true
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

/// Thread-safe box for extracting values from @Sendable performChanges closures.
private final class AlbumIdBox: @unchecked Sendable {
    var value: String?
}

public enum PhotosError: LocalizedError {
    case accessDenied
    case albumNotFound(String)
    case assetNotFound(String)
    case exportFailed(String)
    case albumCreationFailed(String)
    case cannotModifySmartAlbum
    case metadataEditingNotSupported

    public var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Photos access denied"
        case .albumNotFound(let id):
            return "Album not found: \(id)"
        case .assetNotFound(let id):
            return "Photo not found: \(id)"
        case .exportFailed(let reason):
            return "Export failed: \(reason)"
        case .albumCreationFailed(let name):
            return "Failed to create album '\(name)'"
        case .cannotModifySmartAlbum:
            return "Cannot modify smart albums"
        case .metadataEditingNotSupported:
            return "Photo metadata editing is not supported on macOS"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .accessDenied:
            return """
            Grant photos access in System Settings:
            1. Open System Settings
            2. Navigate to Privacy & Security > Photos
            3. Enable "Full Access" for Terminal (or your terminal app)
            4. Restart sysm

            Quick: open "x-apple.systempreferences:com.apple.preference.security?Privacy_Photos"
            """
        case .albumNotFound:
            return """
            Album not found with that identifier.

            Try:
            - List all albums: sysm photos albums
            - Use the album ID from the list
            """
        case .assetNotFound:
            return """
            Photo not found with that identifier.

            Try:
            - List recent photos: sysm photos recent --limit 20
            - Search by date: sysm photos search-date --from "2024-01-01"
            - List photos in album: sysm photos album-photos <album-id>
            """
        case .exportFailed(let reason):
            return """
            Export failed: \(reason)

            Try:
            - Verify the output directory exists and is writable
            - Ensure you have sufficient disk space
            - Check that the photo is not in the cloud (download it first in Photos app)
            """
        case .albumCreationFailed(let name):
            return """
            Failed to create album '\(name)'.

            Try:
            - Check if an album with that name already exists
            - Ensure Photos app is not in read-only mode
            - Try a different album name
            """
        case .cannotModifySmartAlbum:
            return """
            Smart albums (Favorites, Recently Added, etc.) cannot be modified.

            These albums are automatically managed by Photos.app.
            To organize photos, create a custom album:
            sysm photos create-album "My Album"
            """
        case .metadataEditingNotSupported:
            return """
            PhotoKit on macOS does not expose APIs for editing photo titles and descriptions.

            This is a framework limitation, not a sysm limitation.

            Workarounds:
            - Edit metadata in Photos.app directly
            - Use third-party tools like exiftool
            - Use Photos.app AppleScript (limited support)
            """
        }
    }
}
