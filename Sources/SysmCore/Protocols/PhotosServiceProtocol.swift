import Foundation

/// Protocol defining photos service operations for accessing and managing the macOS Photos library.
///
/// This protocol provides comprehensive read access to the user's photo library through PhotoKit,
/// supporting album management, photo/video queries, metadata access, people/faces detection,
/// export capabilities, and photo organization. All operations require Photos library access
/// permission from the user.
///
/// ## Permission Requirements
///
/// Before using any photo library operations, the app must request and obtain Photos access:
/// - System Settings > Privacy & Security > Photos
/// - Use ``ensureAccess()`` to verify permission before operations
///
/// ## Usage Example
///
/// ```swift
/// let service = PhotosService()
///
/// // Ensure access first
/// try await service.ensureAccess()
///
/// // List all albums
/// let albums = try await service.listAlbums()
/// for album in albums {
///     print("\(album.title): \(album.photoCount) photos")
/// }
///
/// // Get recent photos
/// let recent = try await service.getRecentPhotos(limit: 10)
/// for photo in recent {
///     print("\(photo.filename) - \(photo.creationDate ?? Date())")
/// }
///
/// // Export a photo
/// try await service.exportPhoto(assetId: photo.id, outputPath: "/tmp/photo.jpg")
/// ```
///
/// ## Thread Safety
///
/// Implementations are marked as `Sendable` and safe to use across actor boundaries.
/// PhotoKit operations are performed on appropriate queues internally.
///
/// ## Error Handling
///
/// All methods can throw ``PhotosError`` variants:
/// - ``PhotosError/accessDenied`` - Photos library permission not granted
/// - ``PhotosError/albumNotFound(_:)`` - Album not found by identifier
/// - ``PhotosError/assetNotFound(_:)`` - Photo/video asset not found by identifier
/// - ``PhotosError/exportFailed(_:)`` - Export operation failed
/// - ``PhotosError/saveFailed(_:)`` - Save operation failed
/// - ``PhotosError/personNotFound(_:)`` - Person/face not found by name
///
public protocol PhotosServiceProtocol: Sendable {
    // MARK: - Access Management

    /// Ensures the app has access to the Photos library.
    ///
    /// This method verifies that Photos library permission has been granted. Call this before
    /// any other photo operations to ensure proper access.
    ///
    /// - Throws: ``PhotosError/accessDenied`` if photos access not granted or restricted.
    ///
    /// ## Example
    ///
    /// ```swift
    /// do {
    ///     try await service.ensureAccess()
    ///     print("Photos access verified")
    /// } catch PhotosError.accessDenied {
    ///     print("User denied photos access")
    /// }
    /// ```
    func ensureAccess() async throws

    // MARK: - Album Management

    /// Lists all photo albums in the library.
    ///
    /// Returns both user-created albums and system albums (e.g., Favorites, Recently Added).
    /// Albums include photo counts and creation dates.
    ///
    /// - Returns: Array of ``PhotoAlbum`` objects.
    /// - Throws: ``PhotosError/accessDenied`` if photos access not granted.
    func listAlbums() async throws -> [PhotoAlbum]

    /// Creates a new photo album.
    ///
    /// Creates an empty album with the specified name. Album names do not need to be unique.
    ///
    /// - Parameter name: Display name for the new album.
    /// - Returns: The created ``PhotoAlbum`` object.
    /// - Throws:
    ///   - ``PhotosError/accessDenied`` if photos access not granted.
    ///   - ``PhotosError/saveFailed(_:)`` if creation failed.
    func createAlbum(name: String) async throws -> PhotoAlbum

    /// Deletes a photo album.
    ///
    /// Deletes the album but does not delete the photos in it. Photos remain in the library.
    ///
    /// - Parameter albumId: Album's unique identifier.
    /// - Returns: `true` if deleted successfully.
    /// - Throws:
    ///   - ``PhotosError/accessDenied`` if photos access not granted.
    ///   - ``PhotosError/albumNotFound(_:)`` if album doesn't exist.
    ///   - ``PhotosError/saveFailed(_:)`` if deletion failed.
    func deleteAlbum(albumId: String) async throws -> Bool

    /// Renames a photo album.
    ///
    /// Changes the display name of an existing album.
    ///
    /// - Parameters:
    ///   - albumId: Album's unique identifier.
    ///   - newName: New display name for the album.
    /// - Returns: `true` if renamed successfully.
    /// - Throws:
    ///   - ``PhotosError/accessDenied`` if photos access not granted.
    ///   - ``PhotosError/albumNotFound(_:)`` if album doesn't exist.
    ///   - ``PhotosError/saveFailed(_:)`` if rename failed.
    func renameAlbum(albumId: String, newName: String) async throws -> Bool

    /// Adds photos to an album.
    ///
    /// Adds existing photos to an album. Photos can be in multiple albums.
    ///
    /// - Parameters:
    ///   - albumId: Album's unique identifier.
    ///   - assetIds: Array of photo/video asset identifiers to add.
    /// - Returns: Number of photos successfully added.
    /// - Throws:
    ///   - ``PhotosError/accessDenied`` if photos access not granted.
    ///   - ``PhotosError/albumNotFound(_:)`` if album doesn't exist.
    ///   - ``PhotosError/saveFailed(_:)`` if operation failed.
    func addPhotosToAlbum(albumId: String, assetIds: [String]) async throws -> Int

    /// Removes photos from an album.
    ///
    /// Removes photos from the album but does not delete them from the library.
    ///
    /// - Parameters:
    ///   - albumId: Album's unique identifier.
    ///   - assetIds: Array of photo/video asset identifiers to remove.
    /// - Returns: Number of photos successfully removed.
    /// - Throws:
    ///   - ``PhotosError/accessDenied`` if photos access not granted.
    ///   - ``PhotosError/albumNotFound(_:)`` if album doesn't exist.
    ///   - ``PhotosError/saveFailed(_:)`` if operation failed.
    func removePhotosFromAlbum(albumId: String, assetIds: [String]) async throws -> Int

    // MARK: - Photo Queries

    /// Lists photos, optionally filtered by album.
    ///
    /// Returns photos sorted by creation date (newest first). Can be filtered to a specific album.
    ///
    /// - Parameters:
    ///   - albumId: Optional album identifier to filter by. If nil, returns photos from all albums.
    ///   - limit: Maximum number of photos to return.
    /// - Returns: Array of ``PhotoAsset`` objects.
    /// - Throws:
    ///   - ``PhotosError/accessDenied`` if photos access not granted.
    ///   - ``PhotosError/albumNotFound(_:)`` if specified album doesn't exist.
    func listPhotos(albumId: String?, limit: Int) async throws -> [PhotoAsset]

    /// Lists videos, optionally filtered by album.
    ///
    /// Returns videos sorted by creation date (newest first). Can be filtered to a specific album.
    ///
    /// - Parameters:
    ///   - albumId: Optional album identifier to filter by. If nil, returns videos from all albums.
    ///   - limit: Maximum number of videos to return.
    /// - Returns: Array of ``PhotoAsset`` objects representing videos.
    /// - Throws:
    ///   - ``PhotosError/accessDenied`` if photos access not granted.
    ///   - ``PhotosError/albumNotFound(_:)`` if specified album doesn't exist.
    func listVideos(albumId: String?, limit: Int) async throws -> [PhotoAsset]

    /// Retrieves recently added photos.
    ///
    /// Returns the most recently added photos to the library, sorted by creation date descending.
    ///
    /// - Parameter limit: Maximum number of photos to return.
    /// - Returns: Array of recent ``PhotoAsset`` objects.
    /// - Throws: ``PhotosError/accessDenied`` if photos access not granted.
    func getRecentPhotos(limit: Int) async throws -> [PhotoAsset]

    /// Retrieves recently added videos.
    ///
    /// Returns the most recently added videos to the library, sorted by creation date descending.
    ///
    /// - Parameter limit: Maximum number of videos to return.
    /// - Returns: Array of recent ``PhotoAsset`` objects representing videos.
    /// - Throws: ``PhotosError/accessDenied`` if photos access not granted.
    func getRecentVideos(limit: Int) async throws -> [PhotoAsset]

    /// Searches photos by date range.
    ///
    /// Returns photos whose creation date falls within the specified range.
    ///
    /// - Parameters:
    ///   - from: Start date of the range (inclusive).
    ///   - to: End date of the range (inclusive).
    ///   - limit: Maximum number of photos to return.
    /// - Returns: Array of ``PhotoAsset`` objects within the date range.
    /// - Throws: ``PhotosError/accessDenied`` if photos access not granted.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let lastMonth = Date().addingTimeInterval(-30*24*3600)
    /// let photos = try await service.searchByDate(from: lastMonth, to: Date(), limit: 100)
    /// ```
    func searchByDate(from: Date, to: Date, limit: Int) async throws -> [PhotoAsset]

    // MARK: - Export

    /// Exports a photo to a file.
    ///
    /// Exports the photo in its original format (JPEG, PNG, HEIC, etc.) to the specified path.
    ///
    /// - Parameters:
    ///   - assetId: The photo asset's unique identifier.
    ///   - outputPath: Destination file path for the exported photo.
    /// - Throws:
    ///   - ``PhotosError/accessDenied`` if photos access not granted.
    ///   - ``PhotosError/assetNotFound(_:)`` if photo doesn't exist.
    ///   - ``PhotosError/exportFailed(_:)`` if export operation failed.
    func exportPhoto(assetId: String, outputPath: String) async throws

    /// Exports a video to a file.
    ///
    /// Exports the video in its original format (MOV, MP4, etc.) to the specified path.
    ///
    /// - Parameters:
    ///   - assetId: The video asset's unique identifier.
    ///   - outputPath: Destination file path for the exported video.
    /// - Throws:
    ///   - ``PhotosError/accessDenied`` if photos access not granted.
    ///   - ``PhotosError/assetNotFound(_:)`` if video doesn't exist.
    ///   - ``PhotosError/exportFailed(_:)`` if export operation failed.
    func exportVideo(assetId: String, outputPath: String) async throws

    /// Gets metadata for an asset including EXIF, location, and camera information.
    ///
    /// Returns comprehensive metadata including GPS coordinates, camera settings, dimensions,
    /// file size, and more.
    ///
    /// - Parameter assetId: The asset's unique identifier.
    /// - Returns: ``AssetMetadata`` object with all available metadata.
    /// - Throws:
    ///   - ``PhotosError/accessDenied`` if photos access not granted.
    ///   - ``PhotosError/assetNotFound(_:)`` if asset doesn't exist.
    func getMetadata(assetId: String) async throws -> AssetMetadata

    // MARK: - People & Faces

    /// Lists all people/faces detected in the Photos library.
    ///
    /// Returns people identified by Photos' face detection and recognition, including
    /// both named people and unnamed faces.
    ///
    /// - Returns: Array of ``PhotoPerson`` objects with names and photo counts.
    /// - Throws: ``PhotosError/accessDenied`` if photos access not granted.
    func listPeople() async throws -> [PhotoPerson]

    /// Searches photos by person name.
    ///
    /// Returns photos containing the specified person, as identified by Photos' face recognition.
    ///
    /// - Parameter personName: Name of the person to search for (case-insensitive).
    /// - Returns: Array of ``PhotoAsset`` objects containing the person.
    /// - Throws:
    ///   - ``PhotosError/accessDenied`` if photos access not granted.
    ///   - ``PhotosError/personNotFound(_:)`` if person doesn't exist.
    func searchByPerson(personName: String) async throws -> [PhotoAsset]

    // MARK: - Metadata & Keywords

    /// Sets the title for a photo.
    ///
    /// Updates the photo's title metadata. Visible in Photos app and EXIF data.
    ///
    /// - Parameters:
    ///   - assetId: Asset's unique identifier.
    ///   - title: New title text.
    /// - Returns: `true` if successful.
    /// - Throws:
    ///   - ``PhotosError/accessDenied`` if photos access not granted.
    ///   - ``PhotosError/assetNotFound(_:)`` if asset doesn't exist.
    ///   - ``PhotosError/saveFailed(_:)`` if save operation failed.
    func setTitle(assetId: String, title: String) async throws -> Bool

    /// Sets the description for a photo.
    ///
    /// Updates the photo's description/caption metadata.
    ///
    /// - Parameters:
    ///   - assetId: Asset's unique identifier.
    ///   - description: New description text.
    /// - Returns: `true` if successful.
    /// - Throws:
    ///   - ``PhotosError/accessDenied`` if photos access not granted.
    ///   - ``PhotosError/assetNotFound(_:)`` if asset doesn't exist.
    ///   - ``PhotosError/saveFailed(_:)`` if save operation failed.
    func setDescription(assetId: String, description: String) async throws -> Bool

    /// Marks a photo as favorite or removes favorite status.
    ///
    /// Adds or removes the photo from the Favorites album.
    ///
    /// - Parameters:
    ///   - assetId: Asset's unique identifier.
    ///   - isFavorite: `true` to mark as favorite, `false` to remove favorite.
    /// - Returns: `true` if successful.
    /// - Throws:
    ///   - ``PhotosError/accessDenied`` if photos access not granted.
    ///   - ``PhotosError/assetNotFound(_:)`` if asset doesn't exist.
    ///   - ``PhotosError/saveFailed(_:)`` if save operation failed.
    func setFavorite(assetId: String, isFavorite: Bool) async throws -> Bool

    /// Marks a photo as hidden or visible.
    ///
    /// Hidden photos are moved to the Hidden album and are not visible in the main library views.
    ///
    /// - Parameters:
    ///   - assetId: Asset's unique identifier.
    ///   - isHidden: `true` to hide the photo, `false` to make it visible.
    /// - Returns: `true` if successful.
    /// - Throws:
    ///   - ``PhotosError/accessDenied`` if photos access not granted.
    ///   - ``PhotosError/assetNotFound(_:)`` if asset doesn't exist.
    ///   - ``PhotosError/saveFailed(_:)`` if save operation failed.
    func setHidden(assetId: String, isHidden: Bool) async throws -> Bool
}
