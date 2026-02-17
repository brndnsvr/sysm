import Foundation

public struct NetworkStatus: Codable, Sendable {
    public let connected: Bool
    public let interfaces: [String]
    public let primaryInterface: String?
    public let externalIP: String?

    public init(connected: Bool, interfaces: [String], primaryInterface: String?, externalIP: String?) {
        self.connected = connected
        self.interfaces = interfaces
        self.primaryInterface = primaryInterface
        self.externalIP = externalIP
    }
}

public struct WiFiInfo: Codable, Sendable {
    public let ssid: String
    public let bssid: String?
    public let channel: Int?
    public let rssi: Int?
    public let noise: Int?
    public let security: String?

    public init(ssid: String, bssid: String?, channel: Int?, rssi: Int?, noise: Int?, security: String?) {
        self.ssid = ssid
        self.bssid = bssid
        self.channel = channel
        self.rssi = rssi
        self.noise = noise
        self.security = security
    }
}

public struct WiFiNetwork: Codable, Sendable {
    public let ssid: String
    public let bssid: String?
    public let rssi: Int?
    public let channel: Int?
    public let security: String?

    public init(ssid: String, bssid: String?, rssi: Int?, channel: Int?, security: String?) {
        self.ssid = ssid
        self.bssid = bssid
        self.rssi = rssi
        self.channel = channel
        self.security = security
    }
}

public struct NetworkInterface: Codable, Sendable {
    public let name: String
    public let ipAddress: String?
    public let macAddress: String?
    public let status: String

    public init(name: String, ipAddress: String?, macAddress: String?, status: String) {
        self.name = name
        self.ipAddress = ipAddress
        self.macAddress = macAddress
        self.status = status
    }
}

public struct PingResult: Codable, Sendable {
    public let host: String
    public let packetsTransmitted: Int
    public let packetsReceived: Int
    public let packetLoss: Double
    public let roundTripMin: Double?
    public let roundTripAvg: Double?
    public let roundTripMax: Double?

    public init(host: String, packetsTransmitted: Int, packetsReceived: Int, packetLoss: Double,
                roundTripMin: Double?, roundTripAvg: Double?, roundTripMax: Double?) {
        self.host = host
        self.packetsTransmitted = packetsTransmitted
        self.packetsReceived = packetsReceived
        self.packetLoss = packetLoss
        self.roundTripMin = roundTripMin
        self.roundTripAvg = roundTripAvg
        self.roundTripMax = roundTripMax
    }
}
