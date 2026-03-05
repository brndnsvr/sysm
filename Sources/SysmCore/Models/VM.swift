import ArgumentParser
import Foundation

public enum VMType: String, Codable, Sendable, ExpressibleByArgument {
    case linux
    case macos
}

public enum VMState: String, Codable, Sendable {
    case running
    case stopped
    case saved
}

public enum VMStateFilter: String, Sendable, ExpressibleByArgument {
    case up
    case down
}

public struct SharedDirectoryConfig: Codable, Sendable {
    public let hostPath: String
    public let tag: String
    public let readOnly: Bool

    public init(hostPath: String, tag: String, readOnly: Bool) {
        self.hostPath = hostPath
        self.tag = tag
        self.readOnly = readOnly
    }
}

public struct VMConfig: Codable, Sendable {
    public let name: String
    public let os: VMType
    public let cpus: Int
    public let memoryMB: UInt64
    public var diskSizeGB: Int
    public let createdAt: Date
    public var sharedDirectories: [SharedDirectoryConfig]?
    public var rosettaEnabled: Bool?

    public init(name: String, os: VMType, cpus: Int, memoryMB: UInt64, diskSizeGB: Int, createdAt: Date,
                sharedDirectories: [SharedDirectoryConfig]? = nil, rosettaEnabled: Bool? = nil) {
        self.name = name
        self.os = os
        self.cpus = cpus
        self.memoryMB = memoryMB
        self.diskSizeGB = diskSizeGB
        self.createdAt = createdAt
        self.sharedDirectories = sharedDirectories
        self.rosettaEnabled = rosettaEnabled
    }
}

public struct VMInfo: Codable, Sendable {
    public let name: String
    public let os: VMType
    public let cpus: Int
    public let memoryMB: UInt64
    public let diskSizeGB: Int
    public let createdAt: Date
    public let state: VMState
    public let diskPath: String
    public let sharedDirectories: [SharedDirectoryConfig]?
    public let rosettaEnabled: Bool?

    public init(config: VMConfig, state: VMState, diskPath: String) {
        self.name = config.name
        self.os = config.os
        self.cpus = config.cpus
        self.memoryMB = config.memoryMB
        self.diskSizeGB = config.diskSizeGB
        self.createdAt = config.createdAt
        self.state = state
        self.diskPath = diskPath
        self.sharedDirectories = config.sharedDirectories
        self.rosettaEnabled = config.rosettaEnabled
    }
}
