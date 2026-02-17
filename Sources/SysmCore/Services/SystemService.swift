import Foundation
import IOKit.ps

public struct SystemService: SystemServiceProtocol {
    public init() {}

    // MARK: - Battery

    public func getBattery() throws -> BatteryInfo {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [Any],
              let first = sources.first,
              let info = IOPSGetPowerSourceDescription(snapshot, first as CFTypeRef)?.takeUnretainedValue() as? [String: Any]
        else {
            throw SystemError.noBattery
        }

        let percentage = info[kIOPSCurrentCapacityKey] as? Int ?? 0
        let isCharging = (info[kIOPSIsChargingKey] as? Bool) ?? false
        let powerSource = (info[kIOPSPowerSourceStateKey] as? String) ?? "Unknown"

        var timeRemaining: String?
        let timeToEmpty = IOPSGetTimeRemainingEstimate()
        if timeToEmpty == kIOPSTimeRemainingUnlimited {
            timeRemaining = isCharging ? "Charging" : "Unlimited"
        } else if timeToEmpty > 0 {
            let minutes = Int(timeToEmpty / 60)
            timeRemaining = "\(minutes / 60)h \(minutes % 60)m"
        }

        // Cycle count and condition via pmset
        var cycleCount: Int?
        var condition: String?
        if let pmsetOutput = try? Shell.run("/usr/bin/pmset", args: ["-g", "batt"]) {
            if let range = pmsetOutput.range(of: #"condition: (\w+)"#, options: .regularExpression) {
                condition = String(pmsetOutput[range]).replacingOccurrences(of: "condition: ", with: "")
            }
        }
        if let spOutput = try? Shell.run("/usr/sbin/system_profiler", args: ["SPPowerDataType", "-detailLevel", "mini"]) {
            if let range = spOutput.range(of: #"Cycle Count: (\d+)"#, options: .regularExpression) {
                let match = String(spOutput[range])
                cycleCount = Int(match.replacingOccurrences(of: "Cycle Count: ", with: ""))
            }
        }

        return BatteryInfo(
            percentage: percentage,
            isCharging: isCharging,
            powerSource: powerSource == "AC Power" ? "AC Power" : "Battery",
            cycleCount: cycleCount,
            condition: condition,
            timeRemaining: timeRemaining
        )
    }

    // MARK: - Uptime

    public func getUptime() -> TimeInterval {
        ProcessInfo.processInfo.systemUptime
    }

    // MARK: - System Info

    public func getSystemInfo() throws -> SystemInfo {
        let processInfo = ProcessInfo.processInfo

        let hostname = processInfo.hostName
        let osVersion = processInfo.operatingSystemVersionString
        let cores = processInfo.processorCount
        let memoryBytes = processInfo.physicalMemory
        let memoryGB = Int(memoryBytes / (1024 * 1024 * 1024))

        // Get build number
        var osBuild = "Unknown"
        if let buildOutput = try? Shell.run("/usr/bin/sw_vers", args: ["-buildVersion"]) {
            osBuild = buildOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Get model and CPU via sysctl
        var model = "Unknown"
        var cpu = "Unknown"
        var serialNumber: String?

        if let modelOutput = try? sysctlString("hw.model") {
            model = modelOutput
        }
        if let brandOutput = try? sysctlString("machdep.cpu.brand_string") {
            cpu = brandOutput
        }
        if let spOutput = try? Shell.run("/usr/sbin/system_profiler", args: ["SPHardwareDataType", "-detailLevel", "mini"]) {
            if let range = spOutput.range(of: #"Serial Number \(system\): (.+)"#, options: .regularExpression) {
                serialNumber = String(spOutput[range])
                    .replacingOccurrences(of: "Serial Number (system): ", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        return SystemInfo(
            hostname: hostname,
            osVersion: osVersion,
            osBuild: osBuild,
            model: model,
            cpu: cpu,
            cpuCores: cores,
            memoryGB: memoryGB,
            serialNumber: serialNumber
        )
    }

    // MARK: - Memory

    public func getMemoryUsage() throws -> MemoryUsage {
        let totalBytes = ProcessInfo.processInfo.physicalMemory
        let totalMB = Int(totalBytes / (1024 * 1024))

        guard let vmOutput = try? Shell.run("/usr/bin/vm_stat") else {
            throw SystemError.commandFailed("vm_stat")
        }

        let pageSize = 16384 // Apple Silicon default
        var active: Int = 0
        var inactive: Int = 0
        var wired: Int = 0
        var free: Int = 0

        for line in vmOutput.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("Pages active:") {
                active = parseVMStatPages(trimmed)
            } else if trimmed.hasPrefix("Pages inactive:") {
                inactive = parseVMStatPages(trimmed)
            } else if trimmed.hasPrefix("Pages wired down:") {
                wired = parseVMStatPages(trimmed)
            } else if trimmed.hasPrefix("Pages free:") {
                free = parseVMStatPages(trimmed)
            }
        }

        let activeMB = active * pageSize / (1024 * 1024)
        let inactiveMB = inactive * pageSize / (1024 * 1024)
        let wiredMB = wired * pageSize / (1024 * 1024)
        let freeMB = free * pageSize / (1024 * 1024)
        let usedMB = activeMB + wiredMB

        return MemoryUsage(
            totalMB: totalMB,
            usedMB: usedMB,
            freeMB: freeMB,
            activeGB: Double(activeMB) / 1024.0,
            inactiveGB: Double(inactiveMB) / 1024.0,
            wiredGB: Double(wiredMB) / 1024.0
        )
    }

    // MARK: - Disk

    public func getDiskUsage(path: String = "/") throws -> DiskUsage {
        let url = URL(fileURLWithPath: path)
        let values = try url.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey])

        guard let total = values.volumeTotalCapacity,
              let available = values.volumeAvailableCapacityForImportantUsage else {
            throw SystemError.commandFailed("disk usage")
        }

        let totalGB = Double(total) / 1_000_000_000
        let freeGB = Double(available) / 1_000_000_000
        let usedGB = totalGB - freeGB
        let percentUsed = total > 0 ? Int((Double(total - Int(available)) / Double(total)) * 100) : 0

        return DiskUsage(
            totalGB: round(totalGB * 10) / 10,
            usedGB: round(usedGB * 10) / 10,
            freeGB: round(freeGB * 10) / 10,
            percentUsed: percentUsed,
            mountPoint: path
        )
    }

    // MARK: - Private Helpers

    private func sysctlString(_ name: String) throws -> String {
        var size = 0
        sysctlbyname(name, nil, &size, nil, 0)
        guard size > 0 else { throw SystemError.commandFailed("sysctl \(name)") }

        var buffer = [CChar](repeating: 0, count: size)
        sysctlbyname(name, &buffer, &size, nil, 0)
        return String(cString: buffer)
    }

    private func parseVMStatPages(_ line: String) -> Int {
        let parts = line.components(separatedBy: ":")
        guard parts.count == 2 else { return 0 }
        let numStr = parts[1].trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ".", with: "")
        return Int(numStr) ?? 0
    }
}

public enum SystemError: LocalizedError {
    case noBattery
    case commandFailed(String)

    public var errorDescription: String? {
        switch self {
        case .noBattery:
            return "No battery information available (desktop Mac?)"
        case .commandFailed(let cmd):
            return "Failed to execute: \(cmd)"
        }
    }
}
