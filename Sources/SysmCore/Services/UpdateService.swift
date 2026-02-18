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

        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadUrl = "browser_download_url"
            case size
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

        // Download
        do {
            _ = try Shell.run("/usr/bin/curl", args: ["-fSL", "-o", tarPath, downloadUrl], timeout: 120)
        } catch {
            throw UpdateError.downloadFailed(error.localizedDescription)
        }

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

        // Make executable
        _ = try Shell.run("/bin/chmod", args: ["+x", extractedBinary])

        // Atomic replace
        _ = try Shell.run("/bin/mv", args: ["-f", extractedBinary, binaryPath])

        // Verify new version
        let versionOutput = try Shell.run(binaryPath, args: ["--version"])
        guard versionOutput.contains(check.latestVersion) else {
            throw UpdateError.verificationFailed(
                "Expected \(check.latestVersion), got: \(versionOutput)")
        }

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
