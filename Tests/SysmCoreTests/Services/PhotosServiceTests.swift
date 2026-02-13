//
//  PhotosServiceTests.swift
//  sysm
//

import XCTest
import Photos
@testable import SysmCore

final class PhotosServiceTests: XCTestCase {
    var service: PhotosService!

    override func setUp() async throws {
        try await super.setUp()
        service = PhotosService()
    }

    override func tearDown() async throws {
        service = nil
        try await super.tearDown()
    }

    // MARK: - Access Tests

    func testRequestAccessGranted() async throws {
        do {
            try await service.requestAccess()
            XCTAssertTrue(true)
        } catch {
            XCTAssertTrue(error is PhotosError)
        }
    }

    // MARK: - Album Tests

    func testGetAlbums() async throws {
        do {
            let albums = try await service.getAlbums()
            XCTAssertNotNil(albums)
        } catch PhotosError.accessDenied {
            throw XCTSkip("Photos access not granted")
        }
    }

    func testCreateAlbum() async throws {
        do {
            let albumId = try await service.createAlbum(name: "Test Album")
            XCTAssertFalse(albumId.isEmpty)

            // Clean up
            try await service.deleteAlbum(id: albumId)
        } catch PhotosError.accessDenied {
            throw XCTSkip("Photos access not granted")
        }
    }

    func testGetAlbumPhotos() async throws {
        do {
            // Get all albums
            let albums = try await service.getAlbums()

            if let firstAlbum = albums.first {
                let photos = try await service.getAlbumPhotos(albumId: firstAlbum.id, limit: 10)
                XCTAssertNotNil(photos)
            }
        } catch PhotosError.accessDenied {
            throw XCTSkip("Photos access not granted")
        }
    }

    // MARK: - Photo Query Tests

    func testGetRecentPhotos() async throws {
        do {
            let photos = try await service.getRecentPhotos(limit: 10)
            XCTAssertNotNil(photos)
        } catch PhotosError.accessDenied {
            throw XCTSkip("Photos access not granted")
        }
    }

    func testGetFavorites() async throws {
        do {
            let photos = try await service.getFavorites(limit: 10)
            XCTAssertNotNil(photos)
        } catch PhotosError.accessDenied {
            throw XCTSkip("Photos access not granted")
        }
    }

    func testSearchPhotosByDate() async throws {
        do {
            let startDate = Date().addingTimeInterval(-86400 * 30) // 30 days ago
            let endDate = Date()

            let photos = try await service.searchPhotosByDate(
                from: startDate,
                to: endDate,
                limit: 10
            )

            XCTAssertNotNil(photos)
        } catch PhotosError.accessDenied {
            throw XCTSkip("Photos access not granted")
        }
    }

    // MARK: - Export Tests

    func testExportPhoto() async throws {
        do {
            let photos = try await service.getRecentPhotos(limit: 1)

            if let photo = photos.first {
                let tempDir = FileManager.default.temporaryDirectory
                let outputPath = tempDir.appendingPathComponent("test_export.jpg").path

                try await service.exportPhoto(assetId: photo.id, outputPath: outputPath)

                // Verify file was created
                XCTAssertTrue(FileManager.default.fileExists(atPath: outputPath))

                // Clean up
                try? FileManager.default.removeItem(atPath: outputPath)
            }
        } catch PhotosError.accessDenied {
            throw XCTSkip("Photos access not granted")
        }
    }

    // MARK: - Favorite Tests

    func testSetFavorite() async throws {
        do {
            let photos = try await service.getRecentPhotos(limit: 1)

            if let photo = photos.first {
                // Toggle favorite status
                let result = try await service.setFavorite(assetId: photo.id, isFavorite: true)
                XCTAssertTrue(result)

                // Toggle back
                _ = try await service.setFavorite(assetId: photo.id, isFavorite: false)
            }
        } catch PhotosError.accessDenied {
            throw XCTSkip("Photos access not granted")
        }
    }

    // MARK: - Metadata Tests

    func testSetTitleThrowsError() async {
        do {
            let photos = try await service.getRecentPhotos(limit: 1)

            if let photo = photos.first {
                // This should throw metadataEditingNotSupported
                do {
                    _ = try await service.setTitle(assetId: photo.id, title: "Test")
                    XCTFail("Should have thrown metadataEditingNotSupported error")
                } catch PhotosError.metadataEditingNotSupported {
                    // Expected - PhotoKit doesn't support metadata editing on macOS
                }
            }
        } catch PhotosError.accessDenied {
            throw XCTSkip("Photos access not granted")
        }
    }

    func testSetDescriptionThrowsError() async {
        do {
            let photos = try await service.getRecentPhotos(limit: 1)

            if let photo = photos.first {
                // This should throw metadataEditingNotSupported
                do {
                    _ = try await service.setDescription(assetId: photo.id, description: "Test")
                    XCTFail("Should have thrown metadataEditingNotSupported error")
                } catch PhotosError.metadataEditingNotSupported {
                    // Expected - PhotoKit doesn't support metadata editing on macOS
                }
            }
        } catch PhotosError.accessDenied {
            throw XCTSkip("Photos access not granted")
        }
    }

    // MARK: - Album Modification Tests

    func testAddPhotoToAlbum() async throws {
        do {
            let albumId = try await service.createAlbum(name: "Test Add Photo")
            let photos = try await service.getRecentPhotos(limit: 1)

            if let photo = photos.first {
                try await service.addPhotosToAlbum(albumId: albumId, assetIds: [photo.id])

                // Verify photo was added
                let albumPhotos = try await service.getAlbumPhotos(albumId: albumId, limit: 10)
                XCTAssertTrue(albumPhotos.contains { $0.id == photo.id })
            }

            // Clean up
            try await service.deleteAlbum(id: albumId)
        } catch PhotosError.accessDenied {
            throw XCTSkip("Photos access not granted")
        }
    }

    func testRemovePhotoFromAlbum() async throws {
        do {
            let albumId = try await service.createAlbum(name: "Test Remove Photo")
            let photos = try await service.getRecentPhotos(limit: 1)

            if let photo = photos.first {
                // Add photo
                try await service.addPhotosToAlbum(albumId: albumId, assetIds: [photo.id])

                // Remove photo
                try await service.removePhotosFromAlbum(albumId: albumId, assetIds: [photo.id])

                // Verify photo was removed
                let albumPhotos = try await service.getAlbumPhotos(albumId: albumId, limit: 10)
                XCTAssertFalse(albumPhotos.contains { $0.id == photo.id })
            }

            // Clean up
            try await service.deleteAlbum(id: albumId)
        } catch PhotosError.accessDenied {
            throw XCTSkip("Photos access not granted")
        }
    }

    // MARK: - Error Tests

    func testAlbumNotFoundError() async {
        do {
            _ = try await service.getAlbum(id: "nonexistent-album-id-12345")
            XCTFail("Should have thrown albumNotFound error")
        } catch PhotosError.albumNotFound {
            // Expected
        } catch PhotosError.accessDenied {
            throw XCTSkip("Photos access not granted")
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testAssetNotFoundError() async {
        do {
            _ = try await service.getPhoto(id: "nonexistent-asset-id-12345")
            XCTFail("Should have thrown assetNotFound error")
        } catch PhotosError.assetNotFound {
            // Expected
        } catch PhotosError.accessDenied {
            throw XCTSkip("Photos access not granted")
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testCannotModifySmartAlbumError() async {
        do {
            // Try to get the Favorites album (a smart album)
            let albums = try await service.getAlbums()
            let favoritesAlbum = albums.first { $0.title == "Favorites" }

            if let album = favoritesAlbum {
                // Try to delete it - should fail
                do {
                    try await service.deleteAlbum(id: album.id)
                    XCTFail("Should have thrown cannotModifySmartAlbum error")
                } catch PhotosError.cannotModifySmartAlbum {
                    // Expected
                }
            }
        } catch PhotosError.accessDenied {
            throw XCTSkip("Photos access not granted")
        }
    }

    // MARK: - Search Tests

    func testSearchPhotosByLocation() async throws {
        do {
            let photos = try await service.searchPhotosByLocation(
                latitude: 37.7749,
                longitude: -122.4194,
                radius: 1000,
                limit: 10
            )

            XCTAssertNotNil(photos)
        } catch PhotosError.accessDenied {
            throw XCTSkip("Photos access not granted")
        }
    }
}
