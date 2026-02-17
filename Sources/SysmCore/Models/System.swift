import Foundation

public struct BatteryInfo: Codable, Sendable {
    public let percentage: Int
    public let isCharging: Bool
    public let powerSource: String
    public let cycleCount: Int?
    public let condition: String?
    public let timeRemaining: String?

    public init(percentage: Int, isCharging: Bool, powerSource: String,
                cycleCount: Int? = nil, condition: String? = nil, timeRemaining: String? = nil) {
        self.percentage = percentage
        self.isCharging = isCharging
        self.powerSource = powerSource
        self.cycleCount = cycleCount
        self.condition = condition
        self.timeRemaining = timeRemaining
    }
}

public struct SystemInfo: Codable, Sendable {
    public let hostname: String
    public let osVersion: String
    public let osBuild: String
    public let model: String
    public let cpu: String
    public let cpuCores: Int
    public let memoryGB: Int
    public let serialNumber: String?

    public init(hostname: String, osVersion: String, osBuild: String,
                model: String, cpu: String, cpuCores: Int, memoryGB: Int,
                serialNumber: String? = nil) {
        self.hostname = hostname
        self.osVersion = osVersion
        self.osBuild = osBuild
        self.model = model
        self.cpu = cpu
        self.cpuCores = cpuCores
        self.memoryGB = memoryGB
        self.serialNumber = serialNumber
    }
}

public struct MemoryUsage: Codable, Sendable {
    public let totalMB: Int
    public let usedMB: Int
    public let freeMB: Int
    public let activeGB: Double
    public let inactiveGB: Double
    public let wiredGB: Double

    public init(totalMB: Int, usedMB: Int, freeMB: Int,
                activeGB: Double, inactiveGB: Double, wiredGB: Double) {
        self.totalMB = totalMB
        self.usedMB = usedMB
        self.freeMB = freeMB
        self.activeGB = activeGB
        self.inactiveGB = inactiveGB
        self.wiredGB = wiredGB
    }
}

public struct DiskUsage: Codable, Sendable {
    public let totalGB: Double
    public let usedGB: Double
    public let freeGB: Double
    public let percentUsed: Int
    public let mountPoint: String

    public init(totalGB: Double, usedGB: Double, freeGB: Double, percentUsed: Int, mountPoint: String) {
        self.totalGB = totalGB
        self.usedGB = usedGB
        self.freeGB = freeGB
        self.percentUsed = percentUsed
        self.mountPoint = mountPoint
    }
}
