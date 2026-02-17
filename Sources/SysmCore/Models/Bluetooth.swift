import Foundation

public struct BluetoothStatus: Codable, Sendable {
    public let powered: Bool
    public let discoverable: Bool
    public let address: String?

    public init(powered: Bool, discoverable: Bool, address: String?) {
        self.powered = powered
        self.discoverable = discoverable
        self.address = address
    }
}

public struct BluetoothDevice: Codable, Sendable {
    public let name: String
    public let address: String
    public let connected: Bool
    public let paired: Bool
    public let deviceType: String?

    public init(name: String, address: String, connected: Bool, paired: Bool, deviceType: String?) {
        self.name = name
        self.address = address
        self.connected = connected
        self.paired = paired
        self.deviceType = deviceType
    }
}
