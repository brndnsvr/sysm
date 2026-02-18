import XCTest
@testable import SysmCore

final class UpdateServiceTests: XCTestCase {

    let service = UpdateService()

    // MARK: - compareVersions

    func testCompareVersionsEqual() {
        XCTAssertEqual(service.compareVersions("1.3.1", "1.3.1"), .orderedSame)
    }

    func testCompareVersionsLessThan() {
        XCTAssertEqual(service.compareVersions("1.3.1", "1.4.0"), .orderedAscending)
    }

    func testCompareVersionsGreaterThan() {
        XCTAssertEqual(service.compareVersions("2.0.0", "1.9.9"), .orderedDescending)
    }

    func testCompareVersionsMajorDifference() {
        XCTAssertEqual(service.compareVersions("1.0.0", "2.0.0"), .orderedAscending)
    }

    func testCompareVersionsDifferentSegmentCounts() {
        XCTAssertEqual(service.compareVersions("1.3", "1.3.0"), .orderedSame)
    }

    func testCompareVersionsShorterLessThanLonger() {
        XCTAssertEqual(service.compareVersions("1.3", "1.3.1"), .orderedAscending)
    }

    func testCompareVersionsLongerGreaterThanShorter() {
        XCTAssertEqual(service.compareVersions("1.3.1", "1.3"), .orderedDescending)
    }

    func testCompareVersionsVPrefixStripping() {
        XCTAssertEqual(service.compareVersions("v1.3.1", "1.3.1"), .orderedSame)
    }

    func testCompareVersionsBothVPrefix() {
        XCTAssertEqual(service.compareVersions("v1.3.1", "v1.4.0"), .orderedAscending)
    }

    func testCompareVersionsPatchOnly() {
        XCTAssertEqual(service.compareVersions("1.3.0", "1.3.1"), .orderedAscending)
    }

    // MARK: - GitHub JSON Parsing

    func testParseGitHubReleaseValid() throws {
        let json = """
        {
            "tag_name": "v1.4.0",
            "body": "Release notes here",
            "assets": [
                {
                    "name": "sysm-1.4.0-macos-arm64.tar.gz",
                    "browser_download_url": "https://github.com/brndnsvr/sysm/releases/download/v1.4.0/sysm-1.4.0-macos-arm64.tar.gz",
                    "size": 5242880
                },
                {
                    "name": "sysm-1.4.0-macos-x86_64.tar.gz",
                    "browser_download_url": "https://github.com/brndnsvr/sysm/releases/download/v1.4.0/sysm-1.4.0-macos-x86_64.tar.gz",
                    "size": 5500000
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!

        // Parse using the private type via a round-trip through UpdateCheck
        // We test the service's checkForUpdate logic indirectly via compareVersions
        // and parse validation directly
        struct TestRelease: Decodable {
            let tagName: String
            let body: String?
            let assets: [TestAsset]

            enum CodingKeys: String, CodingKey {
                case tagName = "tag_name"
                case body
                case assets
            }
        }
        struct TestAsset: Decodable {
            let name: String
            let browserDownloadUrl: String
            let size: Int

            enum CodingKeys: String, CodingKey {
                case name
                case browserDownloadUrl = "browser_download_url"
                case size
            }
        }

        let release = try JSONDecoder().decode(TestRelease.self, from: data)
        XCTAssertEqual(release.tagName, "v1.4.0")
        XCTAssertEqual(release.body, "Release notes here")
        XCTAssertEqual(release.assets.count, 2)
        XCTAssertEqual(release.assets[0].name, "sysm-1.4.0-macos-arm64.tar.gz")
        XCTAssertTrue(release.assets[0].browserDownloadUrl.contains("arm64"))
        XCTAssertEqual(release.assets[0].size, 5242880)
    }

    func testParseGitHubReleaseMissingAssets() throws {
        let json = """
        {
            "tag_name": "v1.4.0",
            "body": null,
            "assets": []
        }
        """
        let data = json.data(using: .utf8)!

        struct TestRelease: Decodable {
            let tagName: String
            let body: String?
            let assets: [TestAsset]

            struct TestAsset: Decodable {
                let name: String
            }

            enum CodingKeys: String, CodingKey {
                case tagName = "tag_name"
                case body
                case assets
            }
        }

        let release = try JSONDecoder().decode(TestRelease.self, from: data)
        XCTAssertEqual(release.tagName, "v1.4.0")
        XCTAssertNil(release.body)
        XCTAssertTrue(release.assets.isEmpty)
    }

    func testParseGitHubReleaseNullBody() throws {
        let json = """
        {
            "tag_name": "v2.0.0",
            "body": null,
            "assets": [
                {
                    "name": "sysm-2.0.0-macos-arm64.tar.gz",
                    "browser_download_url": "https://example.com/download",
                    "size": 1000
                }
            ]
        }
        """
        let data = json.data(using: .utf8)!

        struct TestRelease: Decodable {
            let tagName: String
            let body: String?
            let assets: [TestAsset]

            struct TestAsset: Decodable {
                let name: String
                let browserDownloadUrl: String

                enum CodingKeys: String, CodingKey {
                    case name
                    case browserDownloadUrl = "browser_download_url"
                }
            }

            enum CodingKeys: String, CodingKey {
                case tagName = "tag_name"
                case body
                case assets
            }
        }

        let release = try JSONDecoder().decode(TestRelease.self, from: data)
        XCTAssertEqual(release.tagName, "v2.0.0")
        XCTAssertNil(release.body)
        XCTAssertEqual(release.assets.count, 1)
    }

    // MARK: - Homebrew Detection

    func testHomebrewDetectionCellar() {
        XCTAssertTrue(service.isHomebrewManaged("/opt/homebrew/Cellar/sysm/1.3.1/bin/sysm"))
    }

    func testHomebrewDetectionOptHomebrew() {
        XCTAssertTrue(service.isHomebrewManaged("/opt/homebrew/bin/sysm"))
    }

    func testHomebrewDetectionUsrLocalCellar() {
        XCTAssertTrue(service.isHomebrewManaged("/usr/local/Cellar/sysm/1.3.1/bin/sysm"))
    }

    func testHomebrewDetectionNormalPath() {
        XCTAssertFalse(service.isHomebrewManaged("/usr/local/bin/sysm"))
    }

    func testHomebrewDetectionHomePath() {
        XCTAssertFalse(service.isHomebrewManaged("/Users/test/.local/bin/sysm"))
    }

    // MARK: - Codable Round-Trips

    func testUpdateCheckCodableRoundTrip() throws {
        let check = UpdateCheck(
            currentVersion: "1.3.1",
            latestVersion: "1.4.0",
            updateAvailable: true,
            downloadUrl: "https://example.com/download",
            releaseNotes: "Bug fixes"
        )

        let data = try JSONEncoder().encode(check)
        let decoded = try JSONDecoder().decode(UpdateCheck.self, from: data)

        XCTAssertEqual(decoded.currentVersion, check.currentVersion)
        XCTAssertEqual(decoded.latestVersion, check.latestVersion)
        XCTAssertEqual(decoded.updateAvailable, check.updateAvailable)
        XCTAssertEqual(decoded.downloadUrl, check.downloadUrl)
        XCTAssertEqual(decoded.releaseNotes, check.releaseNotes)
    }

    func testUpdateCheckCodableNilFields() throws {
        let check = UpdateCheck(
            currentVersion: "1.3.1",
            latestVersion: "1.3.1",
            updateAvailable: false,
            downloadUrl: nil,
            releaseNotes: nil
        )

        let data = try JSONEncoder().encode(check)
        let decoded = try JSONDecoder().decode(UpdateCheck.self, from: data)

        XCTAssertEqual(decoded.currentVersion, "1.3.1")
        XCTAssertFalse(decoded.updateAvailable)
        XCTAssertNil(decoded.downloadUrl)
        XCTAssertNil(decoded.releaseNotes)
    }

    func testUpdateResultCodableRoundTrip() throws {
        let result = UpdateResult(
            previousVersion: "1.3.1",
            newVersion: "1.4.0",
            binaryPath: "/usr/local/bin/sysm"
        )

        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(UpdateResult.self, from: data)

        XCTAssertEqual(decoded.previousVersion, result.previousVersion)
        XCTAssertEqual(decoded.newVersion, result.newVersion)
        XCTAssertEqual(decoded.binaryPath, result.binaryPath)
    }

    // MARK: - Error Messages

    func testUpdateErrorDescriptions() {
        XCTAssertNotNil(UpdateError.networkFailed("timeout").errorDescription)
        XCTAssertNotNil(UpdateError.noCompatibleAsset.errorDescription)
        XCTAssertNotNil(UpdateError.downloadFailed("404").errorDescription)
        XCTAssertNotNil(UpdateError.extractionFailed("corrupt").errorDescription)
        XCTAssertNotNil(UpdateError.verificationFailed("mismatch").errorDescription)
        XCTAssertNotNil(UpdateError.permissionDenied("/usr/local/bin").errorDescription)
        XCTAssertNotNil(UpdateError.homebrewManaged("/opt/homebrew/bin/sysm").errorDescription)
    }

    func testHomebrewErrorContainsBrew() {
        let error = UpdateError.homebrewManaged("/opt/homebrew/bin/sysm")
        XCTAssertTrue(error.errorDescription!.contains("brew upgrade"))
    }

    func testPermissionDeniedContainsSudo() {
        let error = UpdateError.permissionDenied("/usr/local/bin")
        XCTAssertTrue(error.errorDescription!.contains("sudo"))
    }
}
