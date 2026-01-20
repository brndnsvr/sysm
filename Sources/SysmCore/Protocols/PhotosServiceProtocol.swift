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
    func listAlbums() async throws -> [PhotosService.PhotoAlbum]

    /// Lists photos, optionally filtered by album.
    /// - Parameters:
    ///   - albumId: Optional album identifier to filter by.
    ///   - limit: Maximum number of photos to return.
    /// - Returns: Array of photo assets.
    func listPhotos(albumId: String?, limit: Int) async throws -> [PhotosService.PhotoAsset]

    /// Lists videos, optionally filtered by album.
    /// - Parameters:
    ///   - albumId: Optional album identifier to filter by.
    ///   - limit: Maximum number of videos to return.
    /// - Returns: Array of video assets.
    func listVideos(albumId: String?, limit: Int) async throws -> [PhotosService.PhotoAsset]

    /// Retrieves recently added photos.
    /// - Parameter limit: Maximum number of photos to return.
    /// - Returns: Array of recent photo assets.
    func getRecentPhotos(limit: Int) async throws -> [PhotosService.PhotoAsset]

    /// Retrieves recently added videos.
    /// - Parameter limit: Maximum number of videos to return.
    /// - Returns: Array of recent video assets.
    func getRecentVideos(limit: Int) async throws -> [PhotosService.PhotoAsset]

    /// Searches photos by date range.
    /// - Parameters:
    ///   - from: Start date.
    ///   - to: End date.
    ///   - limit: Maximum number of photos to return.
    /// - Returns: Array of photos within the date range.
    func searchByDate(from: Date, to: Date, limit: Int) async throws -> [PhotosService.PhotoAsset]

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
    func getMetadata(assetId: String) async throws -> PhotosService.AssetMetadata
}
