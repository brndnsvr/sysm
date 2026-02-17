import Foundation

public protocol AppStoreServiceProtocol: Sendable {
    /// Check if mas CLI is installed.
    func isAvailable() -> Bool

    /// List installed App Store apps.
    func listInstalled() throws -> [AppStoreApp]

    /// Check for outdated apps.
    func listOutdated() throws -> [AppStoreApp]

    /// Search the App Store.
    func search(query: String) throws -> [AppStoreApp]

    /// Update a specific app or all apps.
    func update(appId: String?) throws -> String
}
