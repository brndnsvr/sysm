import Foundation

public class TriggerService {
    private let triggerPath: URL

    /// Initialize TriggerService with configurable path.
    /// - Parameter relativePath: Path relative to home directory (default: "dayai/_dayai/TRIGGER.md")
    /// - Note: Set SYSM_TRIGGER_PATH environment variable to override with an absolute path
    public init(relativePath: String = "dayai/_dayai/TRIGGER.md") {
        if let envPath = ProcessInfo.processInfo.environment["SYSM_TRIGGER_PATH"] {
            self.triggerPath = URL(fileURLWithPath: envPath)
        } else {
            self.triggerPath = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(relativePath)
        }
    }

    public func syncTrackedReminders(_ tracked: [(key: String, reminder: TrackedReminder)]) throws {
        guard FileManager.default.fileExists(atPath: triggerPath.path) else {
            return
        }

        var content = try String(contentsOf: triggerPath, encoding: .utf8)

        let sectionHeader = "## 📌 Tracked Reminders"
        let tableHeader = """
        | Reminder | Added | Project | Status |
        |----------|-------|---------|--------|
        """

        let activeTracked = tracked.filter { $0.reminder.status != "done" }

        var tableRows = ""
        for (_, reminder) in activeTracked {
            let status = reminder.status.capitalized
            let project = reminder.project.isEmpty ? "-" : reminder.project
            tableRows += "| \(reminder.originalName) | \(reminder.firstSeen) | \(project) | \(status) |\n"
        }

        let newSection: String
        if activeTracked.isEmpty {
            newSection = "\(sectionHeader)\n\nNo active tracked reminders.\n"
        } else {
            newSection = "\(sectionHeader)\n\(tableHeader)\n\(tableRows)"
        }

        if let sectionRange = content.range(of: sectionHeader) {
            let afterSection = content[sectionRange.upperBound...]
            if let nextSectionRange = afterSection.range(of: "\n## ") {
                let beforeSection = String(content[..<sectionRange.lowerBound])
                let afterSectionContent = String(content[nextSectionRange.lowerBound...])
                content = beforeSection + newSection + afterSectionContent
            } else {
                let beforeSection = String(content[..<sectionRange.lowerBound])
                content = beforeSection + newSection
            }
        } else {
            if let deadlinesRange = content.range(of: "## 📅 Upcoming Deadlines") {
                let beforeDeadlines = String(content[..<deadlinesRange.lowerBound])
                let afterDeadlines = String(content[deadlinesRange.lowerBound...])
                content = beforeDeadlines + newSection + "\n" + afterDeadlines
            } else {
                content = content.trimmingCharacters(in: .whitespacesAndNewlines) + "\n\n" + newSection
            }
        }

        try content.write(to: triggerPath, atomically: true, encoding: .utf8)
    }
}
