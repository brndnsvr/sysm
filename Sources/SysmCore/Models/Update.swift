import Foundation

public struct UpdateCheck: Codable, Sendable {
    public let currentVersion: String
    public let latestVersion: String
    public let updateAvailable: Bool
    public let downloadUrl: String?
    public let releaseNotes: String?

    public init(currentVersion: String, latestVersion: String, updateAvailable: Bool,
                downloadUrl: String?, releaseNotes: String?) {
        self.currentVersion = currentVersion
        self.latestVersion = latestVersion
        self.updateAvailable = updateAvailable
        self.downloadUrl = downloadUrl
        self.releaseNotes = releaseNotes
    }
}

public struct UpdateResult: Codable, Sendable {
    public let previousVersion: String
    public let newVersion: String
    public let binaryPath: String

    public init(previousVersion: String, newVersion: String, binaryPath: String) {
        self.previousVersion = previousVersion
        self.newVersion = newVersion
        self.binaryPath = binaryPath
    }
}

public enum UpdateError: LocalizedError {
    case networkFailed(String)
    case noCompatibleAsset
    case downloadFailed(String)
    case extractionFailed(String)
    case verificationFailed(String)
    case permissionDenied(String)
    case homebrewManaged(String)

    public var errorDescription: String? {
        switch self {
        case .networkFailed(let msg):
            return "Network request failed: \(msg)"
        case .noCompatibleAsset:
            return "No compatible binary found for this platform"
        case .downloadFailed(let msg):
            return "Download failed: \(msg)"
        case .extractionFailed(let msg):
            return "Extraction failed: \(msg)"
        case .verificationFailed(let msg):
            return "Verification failed: \(msg)"
        case .permissionDenied(let path):
            return "Permission denied: \(path) — try running with sudo"
        case .homebrewManaged(let path):
            return "This install is managed by Homebrew (\(path)). Use `brew upgrade sysm` instead."
        }
    }
}
