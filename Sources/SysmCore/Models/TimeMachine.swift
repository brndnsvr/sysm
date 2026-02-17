import Foundation

public struct TimeMachineStatus: Codable, Sendable {
    public let running: Bool
    public let phase: String?
    public let progress: Double?
    public let destination: String?

    public init(running: Bool, phase: String?, progress: Double?, destination: String?) {
        self.running = running
        self.phase = phase
        self.progress = progress
        self.destination = destination
    }
}

public struct TimeMachineBackup: Codable, Sendable {
    public let date: String
    public let path: String

    public init(date: String, path: String) {
        self.date = date
        self.path = path
    }
}
