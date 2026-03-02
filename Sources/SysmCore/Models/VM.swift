import ArgumentParser
import Foundation

public enum VMType: String, Codable, Sendable, ExpressibleByArgument {
    case linux
    case macos
}

public enum VMState: String, Codable, Sendable {
    case running
    case stopped
}

public enum VMStateFilter: String, Sendable, ExpressibleByArgument {
    case up
    case down
}

public struct VMConfig: Codable, Sendable {
    public let name: String
    public let os: VMType
    public let cpus: Int
    public let memoryMB: UInt64
    public let diskSizeGB: Int
    public let createdAt: Date

    public init(name: String, os: VMType, cpus: Int, memoryMB: UInt64, diskSizeGB: Int, createdAt: Date) {
        self.name = name
        self.os = os
        self.cpus = cpus
        self.memoryMB = memoryMB
        self.diskSizeGB = diskSizeGB
        self.createdAt = createdAt
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

    public init(config: VMConfig, state: VMState, diskPath: String) {
        self.name = config.name
        self.os = config.os
        self.cpus = config.cpus
        self.memoryMB = config.memoryMB
        self.diskSizeGB = config.diskSizeGB
        self.createdAt = config.createdAt
        self.state = state
        self.diskPath = diskPath
    }
}
