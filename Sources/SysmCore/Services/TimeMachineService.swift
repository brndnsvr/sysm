import Foundation

public struct TimeMachineService: TimeMachineServiceProtocol {
    public init() {}

    public func getStatus() throws -> TimeMachineStatus {
        let output = try Shell.run("/usr/bin/tmutil", args: ["status"])

        var running = false
        var phase: String?
        var progress: Double?
        var destination: String?

        for line in output.split(separator: "\n") {
            let trimmed = String(line).trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ";", with: "")
            if trimmed.contains("Running") {
                running = trimmed.contains("= 1")
            } else if trimmed.contains("BackupPhase") {
                phase = extractValue(trimmed)
            } else if trimmed.contains("Percent") || trimmed.contains("Progress") {
                if let val = Double(extractValue(trimmed) ?? "") {
                    progress = val
                }
            } else if trimmed.contains("DestinationID") || trimmed.contains("DestinationMountPoint") {
                destination = extractValue(trimmed)
            }
        }

        return TimeMachineStatus(
            running: running,
            phase: phase,
            progress: progress,
            destination: destination
        )
    }

    public func listBackups() throws -> [TimeMachineBackup] {
        let output = try Shell.run("/usr/bin/tmutil", args: ["listbackups"])
        guard !output.isEmpty else { return [] }

        return output.split(separator: "\n").compactMap { line in
            let path = String(line).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !path.isEmpty else { return nil }
            // Extract date from backup path (e.g., /Volumes/Backup/Backups.backupdb/Mac/2024-01-15-120000)
            let components = path.split(separator: "/")
            let date = components.last.map(String.init) ?? path
            return TimeMachineBackup(date: date, path: path)
        }
    }

    public func startBackup() throws {
        _ = try Shell.run("/usr/bin/tmutil", args: ["startbackup"])
    }

    // MARK: - Private

    private func extractValue(_ line: String) -> String? {
        let parts = line.split(separator: "=", maxSplits: 1)
        guard parts.count >= 2 else { return nil }
        return String(parts[1]).trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    }
}
