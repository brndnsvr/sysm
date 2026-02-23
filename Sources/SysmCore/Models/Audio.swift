import Foundation

public struct AudioDeviceInfo: Codable, Sendable {
    public let id: UInt32
    public let name: String
    public let manufacturer: String?
    public let uid: String?
    public let isInput: Bool
    public let isOutput: Bool
    public let sampleRate: Double
    public let channels: Int

    public init(id: UInt32, name: String, manufacturer: String?, uid: String?,
                isInput: Bool, isOutput: Bool, sampleRate: Double, channels: Int) {
        self.id = id
        self.name = name
        self.manufacturer = manufacturer
        self.uid = uid
        self.isInput = isInput
        self.isOutput = isOutput
        self.sampleRate = sampleRate
        self.channels = channels
    }
}

public struct AudioVolumeInfo: Codable, Sendable {
    public let volume: Int
    public let isMuted: Bool

    public init(volume: Int, isMuted: Bool) {
        self.volume = volume
        self.isMuted = isMuted
    }
}

public struct AudioDefaultDevice: Codable, Sendable {
    public let deviceId: UInt32
    public let name: String
    public let uid: String?
    public let isInput: Bool

    public init(deviceId: UInt32, name: String, uid: String?, isInput: Bool) {
        self.deviceId = deviceId
        self.name = name
        self.uid = uid
        self.isInput = isInput
    }
}
