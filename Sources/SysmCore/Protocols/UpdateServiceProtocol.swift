import Foundation

public protocol UpdateServiceProtocol: Sendable {
    func checkForUpdate(currentVersion: String) throws -> UpdateCheck
    func performUpdate(currentVersion: String) throws -> UpdateResult
}
