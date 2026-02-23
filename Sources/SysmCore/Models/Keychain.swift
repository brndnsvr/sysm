import Foundation

public struct KeychainItem: Codable, Sendable {
    public let service: String
    public let account: String
    public let label: String?
    public let creationDate: Date?
    public let modificationDate: Date?
    public let itemDescription: String?
    public let comment: String?
    public let itemClass: String

    public init(service: String, account: String, label: String?, creationDate: Date?,
                modificationDate: Date?, itemDescription: String?, comment: String?, itemClass: String) {
        self.service = service
        self.account = account
        self.label = label
        self.creationDate = creationDate
        self.modificationDate = modificationDate
        self.itemDescription = itemDescription
        self.comment = comment
        self.itemClass = itemClass
    }
}

public struct KeychainItemDetail: Codable, Sendable {
    public let item: KeychainItem
    public let value: String

    public init(item: KeychainItem, value: String) {
        self.item = item
        self.value = value
    }
}
