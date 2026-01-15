import Foundation

/// Protocol for photos service operations
protocol PhotosServiceProtocol: Sendable {
    func ensureAccess() async throws
    func listAlbums() async throws -> [PhotosService.PhotoAlbum]
    func listPhotos(albumId: String?, limit: Int) async throws -> [PhotosService.PhotoAsset]
    func getRecentPhotos(limit: Int) async throws -> [PhotosService.PhotoAsset]
    func searchByDate(from: Date, to: Date, limit: Int) async throws -> [PhotosService.PhotoAsset]
    func exportPhoto(assetId: String, outputPath: String) async throws
}
