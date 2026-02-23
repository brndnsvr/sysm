import Foundation

public protocol KeychainServiceProtocol: Sendable {
    func get(service: String, account: String) throws -> KeychainItemDetail
    func set(service: String, account: String, value: String, label: String?) throws
    func delete(service: String, account: String) throws
    func list(service: String?) throws -> [KeychainItem]
    func search(query: String) throws -> [KeychainItem]
}
