import Foundation
import Security

public struct KeychainService: KeychainServiceProtocol {
    public init() {}

    public func get(service: String, account: String) throws -> KeychainItemDetail {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let attrs = result as? [String: Any],
                  let data = attrs[kSecValueData as String] as? Data,
                  let value = String(data: data, encoding: .utf8) else {
                throw KeychainError.operationFailed(status)
            }
            let item = parseItem(from: attrs)
            return KeychainItemDetail(item: item, value: value)
        case errSecItemNotFound:
            throw KeychainError.itemNotFound
        case errSecAuthFailed, errSecInteractionNotAllowed:
            throw KeychainError.accessDenied
        default:
            throw KeychainError.operationFailed(status)
        }
    }

    public func set(service: String, account: String, value: String, label: String?) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.operationFailed(errSecParam)
        }

        // Remove existing item first (ignore errors)
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        var addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
        ]

        if let label = label {
            addQuery[kSecAttrLabel as String] = label
        }

        let status = SecItemAdd(addQuery as CFDictionary, nil)

        switch status {
        case errSecSuccess:
            return
        case errSecDuplicateItem:
            throw KeychainError.duplicateItem
        case errSecAuthFailed, errSecInteractionNotAllowed:
            throw KeychainError.accessDenied
        default:
            throw KeychainError.operationFailed(status)
        }
    }

    public func delete(service: String, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        let status = SecItemDelete(query as CFDictionary)

        switch status {
        case errSecSuccess:
            return
        case errSecItemNotFound:
            throw KeychainError.itemNotFound
        case errSecAuthFailed, errSecInteractionNotAllowed:
            throw KeychainError.accessDenied
        default:
            throw KeychainError.operationFailed(status)
        }
    }

    public func list(service: String?) throws -> [KeychainItem] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll,
        ]

        if let service = service {
            query[kSecAttrService as String] = service
        }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let items = result as? [[String: Any]] else {
                return []
            }
            return items.map { parseItem(from: $0) }
        case errSecItemNotFound:
            return []
        case errSecAuthFailed, errSecInteractionNotAllowed:
            throw KeychainError.accessDenied
        default:
            throw KeychainError.operationFailed(status)
        }
    }

    public func search(query: String) throws -> [KeychainItem] {
        let allItems = try list(service: nil)
        let lowercasedQuery = query.lowercased()
        return allItems.filter { item in
            item.service.lowercased().contains(lowercasedQuery)
                || item.account.lowercased().contains(lowercasedQuery)
                || (item.label?.lowercased().contains(lowercasedQuery) ?? false)
        }
    }

    // MARK: - Private

    private func parseItem(from attrs: [String: Any]) -> KeychainItem {
        KeychainItem(
            service: attrs[kSecAttrService as String] as? String ?? "",
            account: attrs[kSecAttrAccount as String] as? String ?? "",
            label: attrs[kSecAttrLabel as String] as? String,
            creationDate: attrs[kSecAttrCreationDate as String] as? Date,
            modificationDate: attrs[kSecAttrModificationDate as String] as? Date,
            itemDescription: attrs[kSecAttrDescription as String] as? String,
            comment: attrs[kSecAttrComment as String] as? String,
            itemClass: "genericPassword"
        )
    }
}

public enum KeychainError: LocalizedError {
    case itemNotFound
    case duplicateItem
    case accessDenied
    case operationFailed(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Keychain item not found"
        case .duplicateItem:
            return "Keychain item already exists"
        case .accessDenied:
            return "Access to keychain denied"
        case .operationFailed(let status):
            return "Keychain operation failed (OSStatus \(status))"
        }
    }
}
