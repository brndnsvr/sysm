import Foundation

/// Protocol defining photos service operations for accessing macOS Photos library.
///
/// Implementations provide read access to the user's photo library through PhotoKit,
/// supporting album listing, photo/video queries, metadata, and export.
public protocol PhotosServiceProtocol: Sendable {
    /// Ensures the app has access to the Photos library.
    /// - Throws: If access is denied or cannot be determined.
    func ensureAccess() async throws

    /// Lists all photo albums.
    /// - Returns: Array of albums.
    func listAlbums() async throws -> [PhotoAlbum]

    /// Creates a new photo album.
    /// - Parameter name: Album name.
    /// - Returns: The created album.
    func createAlbum(name: String) async throws -> PhotoAlbum

    /// Deletes a photo album.
    /// - Parameter albumId: Album identifier.
    /// - Returns: True if deleted successfully.
    func deleteAlbum(albumId: String) async throws -> Bool

    /// Renames a photo album.
    /// - Parameters:
    ///   - albumId: Album identifier.
    ///   - newName: New album name.
    /// - Returns: True if renamed successfully.
    func renameAlbum(albumId: String, newName: String) async throws -> Bool

    /// Adds photos to an album.
    /// - Parameters:
    ///   - albumId: Album identifier.
    ///   - assetIds: Array of asset identifiers to add.
    /// - Returns: Number of photos added.
    func addPhotosToAlbum(albumId: String, assetIds: [String]) async throws -> Int

    /// Removes photos from an album.
    /// - Parameters:
    ///   - albumId: Album identifier.
    ///   - assetIds: Array of asset identifiers to remove.
    /// - Returns: Number of photos removed.
    func removePhotosFromAlbum(albumId: String, assetIds: [String]) async throws -> Int

    /// Lists photos, optionally filtered by album.
    /// - Parameters:
    ///   - albumId: Optional album identifier to filter by.
    ///   - limit: Maximum number of photos to return.
    /// - Returns: Array of photo assets.
    func listPhotos(albumId: String?, limit: Int) async throws -> [PhotoAsset]

    /// Lists videos, optionally filtered by album.
    /// - Parameters:
    ///   - albumId: Optional album identifier to filter by.
    ///   - limit: Maximum number of videos to return.
    /// - Returns: Array of video assets.
    func listVideos(albumId: String?, limit: Int) async throws -> [PhotoAsset]

    /// Retrieves recently added photos.
    /// - Parameter limit: Maximum number of photos to return.
    /// - Returns: Array of recent photo assets.
    func getRecentPhotos(limit: Int) async throws -> [PhotoAsset]

    /// Retrieves recently added videos.
    /// - Parameter limit: Maximum number of videos to return.
    /// - Returns: Array of recent video assets.
    func getRecentVideos(limit: Int) async throws -> [PhotoAsset]

    /// Searches photos by date range.
    /// - Parameters:
    ///   - from: Start date.
    ///   - to: End date.
    ///   - limit: Maximum number of photos to return.
    /// - Returns: Array of photos within the date range.
    func searchByDate(from: Date, to: Date, limit: Int) async throws -> [PhotoAsset]

    /// Exports a photo to a file.
    /// - Parameters:
    ///   - assetId: The photo asset identifier.
    ///   - outputPath: Destination file path.
    func exportPhoto(assetId: String, outputPath: String) async throws

    /// Exports a video to a file.
    /// - Parameters:
    ///   - assetId: The video asset identifier.
    ///   - outputPath: Destination file path.
    func exportVideo(assetId: String, outputPath: String) async throws

    /// Gets metadata for an asset (EXIF, location, camera info).
    /// - Parameter assetId: The asset identifier.
    /// - Returns: Metadata for the asset.
    func getMetadata(assetId: String) async throws -> AssetMetadata

    // MARK: - People & Faces

    /// Lists all people/faces detected in the Photos library.
    /// - Returns: Array of people with their names and photo counts.
    func listPeople() async throws -> [PhotoPerson]

    /// Searches photos by person name.
    /// - Parameter personName: Name of the person to search for.
    /// - Returns: Array of photos containing the person.
    func searchByPerson(personName: String) async throws -> [PhotoAsset]

    // MARK: - Metadata & Keywords

    /// Sets the title for a photo.
    /// - Parameters:
    ///   - assetId: Asset identifier.
    ///   - title: New title.
    /// - Returns: True if successful.
    func setTitle(assetId: String, title: String) async throws -> Bool

    /// Sets the description for a photo.
    /// - Parameters:
    ///   - assetId: Asset identifier.
    ///   - description: New description.
    /// - Returns: True if successful.
    func setDescription(assetId: String, description: String) async throws -> Bool

    /// Marks a photo as favorite.
    /// - Parameter assetId: Asset identifier.
    /// - Returns: True if successful.
    func setFavorite(assetId: String, isFavorite: Bool) async throws -> Bool

    /// Marks a photo as hidden.
    /// - Parameter assetId: Asset identifier.
    /// - Returns: True if successful.
    func setHidden(assetId: String, isHidden: Bool) async throws -> Bool
}
