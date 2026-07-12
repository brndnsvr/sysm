import CryptoKit
import Darwin
import Foundation

public struct UpdateService: UpdateServiceProtocol {
    public init() {}

    // MARK: - GitHub API Models

    private struct GitHubRelease: Decodable {
        let tagName: String
        let body: String?
        let assets: [GitHubAsset]

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case body
            case assets
        }
    }

    private struct GitHubAsset: Decodable {
        let name: String
        let browserDownloadUrl: String
        let size: Int
        let digest: String?

        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadUrl = "browser_download_url"
            case size, digest
        }
    }

    // MARK: - UpdateServiceProtocol

    public func checkForUpdate(currentVersion: String) throws -> UpdateCheck {
        let release = try fetchLatestRelease()
        let latestVersion = release.tagName.hasPrefix("v")
            ? String(release.tagName.dropFirst())
            : release.tagName

        let arch = try detectArchitecture()
        let assetName = "sysm-\(latestVersion)-macos-\(arch).tar.gz"
        let asset = release.assets.first { $0.name == assetName }

        let updateAvailable = compareVersions(currentVersion, latestVersion) == .orderedAscending

        return UpdateCheck(
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            updateAvailable: updateAvailable,
            downloadUrl: asset?.browserDownloadUrl,
            downloadDigest: asset?.digest,
            releaseNotes: release.body
        )
    }

    public func performUpdate(currentVersion: String) throws -> UpdateResult {
        let check = try checkForUpdate(currentVersion: currentVersion)

        guard check.updateAvailable else {
            throw UpdateError.verificationFailed("Already up to date (\(currentVersion))")
        }

        guard let downloadUrl = check.downloadUrl else {
            throw UpdateError.noCompatibleAsset
        }
        guard let expectedDigest = check.downloadDigest else {
            throw UpdateError.verificationFailed("Release asset has no authenticated SHA-256 digest")
        }

        let binaryPath = try getCurrentBinaryPath()

        // Check for Homebrew-managed install
        if binaryPath.contains("/Cellar/") || binaryPath.contains("/homebrew/") {
            throw UpdateError.homebrewManaged(binaryPath)
        }

        // Check write permissions on parent directory
        let parentDir = (binaryPath as NSString).deletingLastPathComponent
        guard FileManager.default.isWritableFile(atPath: parentDir) else {
            throw UpdateError.permissionDenied(parentDir)
        }

        // Create temp directory
        let tmpDir = "/tmp/sysm-update-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: tmpDir) }

        let tarPath = "\(tmpDir)/sysm.tar.gz"
        let arch = try detectArchitecture()
        let assetName = "sysm-\(check.latestVersion)-macos-\(arch).tar.gz"
        guard isTrustedDownloadURL(
            downloadUrl,
            version: check.latestVersion,
            assetName: assetName
        ) else {
            throw UpdateError.verificationFailed("Release asset URL is outside the trusted repository")
        }

        // Download
        do {
            _ = try Shell.run("/usr/bin/curl", args: ["-fSL", "-o", tarPath, downloadUrl], timeout: 120)
        } catch {
            throw UpdateError.downloadFailed(error.localizedDescription)
        }

        try verifyArchiveDigest(at: tarPath, expectedDigest: expectedDigest)

        // Extract
        do {
            _ = try Shell.run("/usr/bin/tar", args: ["-xzf", tarPath, "-C", tmpDir])
        } catch {
            throw UpdateError.extractionFailed(error.localizedDescription)
        }

        let extractedBinary = "\(tmpDir)/sysm"
        guard FileManager.default.fileExists(atPath: extractedBinary) else {
            throw UpdateError.extractionFailed("Binary not found in archive")
        }

        let stagedBinary = "\(parentDir)/.sysm-update-\(UUID().uuidString)"
        try FileManager.default.copyItem(
            atPath: extractedBinary,
            toPath: stagedBinary
        )
        defer { try? FileManager.default.removeItem(atPath: stagedBinary) }
        _ = try Shell.run("/bin/chmod", args: ["+x", stagedBinary])

        try replaceBinary(
            at: binaryPath,
            with: stagedBinary,
            expectedVersion: check.latestVersion
        )

        return UpdateResult(
            previousVersion: currentVersion,
            newVersion: check.latestVersion,
            binaryPath: binaryPath
        )
    }

    // MARK: - Private Helpers

    private func fetchLatestRelease() throws -> GitHubRelease {
        let output: String
        do {
            output = try Shell.run("/usr/bin/curl", args: [
                "-sL",
                "-H", "Accept: application/vnd.github+json",
                "https://api.github.com/repos/brndnsvr/sysm/releases/latest",
            ], timeout: 30)
        } catch {
            throw UpdateError.networkFailed(error.localizedDescription)
        }

        guard let data = output.data(using: .utf8) else {
            throw UpdateError.networkFailed("Invalid response encoding")
        }

        do {
            return try JSONDecoder().decode(GitHubRelease.self, from: data)
        } catch {
            throw UpdateError.networkFailed("Failed to parse release info: \(error.localizedDescription)")
        }
    }

    private func detectArchitecture() throws -> String {
        let arch = try Shell.run("/usr/bin/uname", args: ["-m"])
        switch arch {
        case "arm64": return "arm64"
        case "x86_64": return "x86_64"
        default: return arch
        }
    }

    func isTrustedDownloadURL(
        _ rawURL: String,
        version: String,
        assetName: String
    ) -> Bool {
        guard let url = URL(string: rawURL),
              url.scheme == "https",
              url.host == "github.com",
              url.query == nil,
              url.fragment == nil else {
            return false
        }

        return url.path == "/brndnsvr/sysm/releases/download/v\(version)/\(assetName)"
    }

    func verifyArchiveDigest(at path: String, expectedDigest: String) throws {
        let prefix = "sha256:"
        guard expectedDigest.hasPrefix(prefix) else {
            throw UpdateError.verificationFailed("Unsupported release digest format")
        }

        let expected = String(expectedDigest.dropFirst(prefix.count)).lowercased()
        guard expected.count == 64,
              expected.allSatisfy({ $0.isHexDigit }) else {
            throw UpdateError.verificationFailed("Malformed release SHA-256 digest")
        }

        let data: Data
        do {
            data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        } catch {
            throw UpdateError.verificationFailed(
                "Could not read downloaded archive: \(error.localizedDescription)"
            )
        }

        let actual = SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
        guard actual == expected else {
            throw UpdateError.verificationFailed(
                "Release SHA-256 mismatch: expected \(expected), got \(actual)"
            )
        }
    }

    /// Replaces the binary only after its archive has been authenticated.
    /// A same-directory rollback copy is retained until the new binary passes
    /// its version probe, and restoration uses an atomic rename.
    func replaceBinary(
        at binaryPath: String,
        with stagedBinary: String,
        expectedVersion: String
    ) throws {
        let fileManager = FileManager.default
        let backupPath = "\(binaryPath).backup-\(UUID().uuidString)"
        try fileManager.copyItem(atPath: binaryPath, toPath: backupPath)
        var preserveBackup = false
        defer {
            if !preserveBackup {
                try? fileManager.removeItem(atPath: backupPath)
            }
        }

        guard rename(stagedBinary, binaryPath) == 0 else {
            throw UpdateError.verificationFailed(
                "Atomic replacement failed: \(String(cString: strerror(errno)))"
            )
        }

        do {
            let versionOutput = try Shell.run(binaryPath, args: ["--version"])
            guard versionOutput.contains(expectedVersion) else {
                throw UpdateError.verificationFailed(
                    "Expected \(expectedVersion), got: \(versionOutput)"
                )
            }
        } catch {
            guard rename(backupPath, binaryPath) == 0 else {
                preserveBackup = true
                throw UpdateError.verificationFailed(
                    "Update failed and rollback failed; backup retained at \(backupPath): "
                        + String(cString: strerror(errno))
                )
            }
            throw UpdateError.verificationFailed(
                "Updated binary failed verification and was rolled back: \(error.localizedDescription)"
            )
        }
    }

    func getCurrentBinaryPath() throws -> String {
        guard let execPath = ProcessInfo.processInfo.arguments.first else {
            throw UpdateError.verificationFailed("Cannot determine binary path")
        }
        let url = URL(fileURLWithPath: execPath).resolvingSymlinksInPath()
        return url.path
    }

    func compareVersions(_ a: String, _ b: String) -> ComparisonResult {
        let cleanA = a.hasPrefix("v") ? String(a.dropFirst()) : a
        let cleanB = b.hasPrefix("v") ? String(b.dropFirst()) : b

        let partsA = cleanA.split(separator: ".").compactMap { Int($0) }
        let partsB = cleanB.split(separator: ".").compactMap { Int($0) }

        let count = max(partsA.count, partsB.count)
        for i in 0..<count {
            let valA = i < partsA.count ? partsA[i] : 0
            let valB = i < partsB.count ? partsB[i] : 0
            if valA < valB { return .orderedAscending }
            if valA > valB { return .orderedDescending }
        }
        return .orderedSame
    }

    func isHomebrewManaged(_ path: String) -> Bool {
        return path.contains("/Cellar/") || path.contains("/homebrew/")
    }
}
