import Foundation

public protocol SystemServiceProtocol: Sendable {
    /// Get battery information (charge, source, health).
    func getBattery() throws -> BatteryInfo

    /// Get system uptime in seconds.
    func getUptime() -> TimeInterval

    /// Get basic system info (hostname, OS version, model, CPU, memory).
    func getSystemInfo() throws -> SystemInfo

    /// Get memory usage breakdown.
    func getMemoryUsage() throws -> MemoryUsage

    /// Get disk usage for a given path (defaults to /).
    func getDiskUsage(path: String) throws -> DiskUsage
}
