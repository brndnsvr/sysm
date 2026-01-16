import Foundation

struct LaunchdService {

    // MARK: - Types

    struct Job: Codable {
        let name: String
        let label: String
        let command: String
        let schedule: Schedule?
        let runAtLoad: Bool
        let keepAlive: Bool
        let workingDirectory: String?
        let standardOutPath: String?
        let standardErrorPath: String?
        let environmentVariables: [String: String]?
        let enabled: Bool
        let plistPath: String

        struct Schedule: Codable {
            let minute: Int?
            let hour: Int?
            let day: Int?
            let weekday: Int?
            let month: Int?
            let interval: Int?  // Run every N seconds

            var cronExpression: String {
                let m = minute.map { String($0) } ?? "*"
                let h = hour.map { String($0) } ?? "*"
                let d = day.map { String($0) } ?? "*"
                let mo = month.map { String($0) } ?? "*"
                let w = weekday.map { String($0) } ?? "*"
                return "\(m) \(h) \(d) \(mo) \(w)"
            }
        }
    }

    enum LaunchdError: LocalizedError {
        case jobNotFound(String)
        case invalidCron(String)
        case plistCreationFailed(String)
        case launchctlFailed(String)
        case jobAlreadyExists(String)

        var errorDescription: String? {
            switch self {
            case .jobNotFound(let name):
                return "Job not found: \(name)"
            case .invalidCron(let expr):
                return "Invalid cron expression: \(expr)"
            case .plistCreationFailed(let reason):
                return "Failed to create plist: \(reason)"
            case .launchctlFailed(let reason):
                return "launchctl failed: \(reason)"
            case .jobAlreadyExists(let name):
                return "Job already exists: \(name). Use --force to overwrite"
            }
        }
    }

    // MARK: - Paths

    private let launchAgentsDir: String
    private let logsDir: String
    private let jobPrefix = "com.sysm."

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        self.launchAgentsDir = "\(home)/Library/LaunchAgents"
        self.logsDir = "\(home)/.sysm/logs"
    }

    // MARK: - Job Management

    func createJob(
        name: String,
        command: String,
        cron: String? = nil,
        interval: Int? = nil,
        runAtLoad: Bool = false,
        workingDirectory: String? = nil,
        env: [String: String]? = nil,
        force: Bool = false
    ) throws -> Job {
        let label = "\(jobPrefix)\(name)"
        let plistPath = "\(launchAgentsDir)/\(label).plist"

        // Check if exists
        if FileManager.default.fileExists(atPath: plistPath) && !force {
            throw LaunchdError.jobAlreadyExists(name)
        }

        // Parse cron if provided
        var schedule: Job.Schedule?
        if let cronExpr = cron {
            schedule = try parseCron(cronExpr)
        } else if let intervalSecs = interval {
            schedule = Job.Schedule(
                minute: nil,
                hour: nil,
                day: nil,
                weekday: nil,
                month: nil,
                interval: intervalSecs
            )
        }

        // Ensure directories exist
        try FileManager.default.createDirectory(
            atPath: launchAgentsDir,
            withIntermediateDirectories: true,
            attributes: nil
        )
        try FileManager.default.createDirectory(
            atPath: logsDir,
            withIntermediateDirectories: true,
            attributes: nil
        )

        let stdoutPath = "\(logsDir)/\(name).log"
        let stderrPath = "\(logsDir)/\(name).error.log"

        // Build plist
        let plist = buildPlist(
            label: label,
            command: command,
            schedule: schedule,
            runAtLoad: runAtLoad,
            workingDirectory: workingDirectory,
            stdoutPath: stdoutPath,
            stderrPath: stderrPath,
            env: env
        )

        // Write plist
        try plist.write(toFile: plistPath, atomically: true, encoding: .utf8)

        // Load into launchd
        try loadJob(plistPath: plistPath)

        return Job(
            name: name,
            label: label,
            command: command,
            schedule: schedule,
            runAtLoad: runAtLoad,
            keepAlive: false,
            workingDirectory: workingDirectory,
            standardOutPath: stdoutPath,
            standardErrorPath: stderrPath,
            environmentVariables: env,
            enabled: true,
            plistPath: plistPath
        )
    }

    func removeJob(name: String) throws {
        let label = "\(jobPrefix)\(name)"
        let plistPath = "\(launchAgentsDir)/\(label).plist"

        guard FileManager.default.fileExists(atPath: plistPath) else {
            throw LaunchdError.jobNotFound(name)
        }

        // Unload from launchd
        try unloadJob(plistPath: plistPath)

        // Remove plist
        try FileManager.default.removeItem(atPath: plistPath)
    }

    func enableJob(name: String) throws {
        let label = "\(jobPrefix)\(name)"
        let plistPath = "\(launchAgentsDir)/\(label).plist"

        guard FileManager.default.fileExists(atPath: plistPath) else {
            throw LaunchdError.jobNotFound(name)
        }

        try loadJob(plistPath: plistPath)
    }

    func disableJob(name: String) throws {
        let label = "\(jobPrefix)\(name)"
        let plistPath = "\(launchAgentsDir)/\(label).plist"

        guard FileManager.default.fileExists(atPath: plistPath) else {
            throw LaunchdError.jobNotFound(name)
        }

        try unloadJob(plistPath: plistPath)
    }

    func runJobNow(name: String) throws {
        let label = "\(jobPrefix)\(name)"
        let plistPath = "\(launchAgentsDir)/\(label).plist"

        guard FileManager.default.fileExists(atPath: plistPath) else {
            throw LaunchdError.jobNotFound(name)
        }

        do {
            _ = try Shell.run("/bin/launchctl", args: ["kickstart", "-k", "gui/\(getuid())/\(label)"])
        } catch Shell.Error.executionFailed(_, let stderr) {
            throw LaunchdError.launchctlFailed(stderr)
        }
    }

    func listJobs() throws -> [Job] {
        guard FileManager.default.fileExists(atPath: launchAgentsDir) else {
            return []
        }

        let contents = try FileManager.default.contentsOfDirectory(atPath: launchAgentsDir)
        var jobs: [Job] = []

        for file in contents {
            guard file.hasPrefix(jobPrefix) && file.hasSuffix(".plist") else { continue }

            let plistPath = "\(launchAgentsDir)/\(file)"
            if let job = try? parseJob(plistPath: plistPath) {
                jobs.append(job)
            }
        }

        return jobs.sorted { $0.name < $1.name }
    }

    func getJob(name: String) throws -> Job {
        let label = "\(jobPrefix)\(name)"
        let plistPath = "\(launchAgentsDir)/\(label).plist"

        guard FileManager.default.fileExists(atPath: plistPath) else {
            throw LaunchdError.jobNotFound(name)
        }

        return try parseJob(plistPath: plistPath)
    }

    func getJobLogs(name: String, lines: Int = 50) throws -> (stdout: String, stderr: String) {
        let stdoutPath = "\(logsDir)/\(name).log"
        let stderrPath = "\(logsDir)/\(name).error.log"

        let stdout = (try? String(contentsOfFile: stdoutPath, encoding: .utf8)) ?? ""
        let stderr = (try? String(contentsOfFile: stderrPath, encoding: .utf8)) ?? ""

        // Return last N lines
        let stdoutLines = stdout.components(separatedBy: .newlines).suffix(lines).joined(separator: "\n")
        let stderrLines = stderr.components(separatedBy: .newlines).suffix(lines).joined(separator: "\n")

        return (stdoutLines, stderrLines)
    }

    // MARK: - Private

    private func parseCron(_ expr: String) throws -> Job.Schedule {
        let parts = expr.split(separator: " ").map(String.init)
        guard parts.count == 5 else {
            throw LaunchdError.invalidCron(expr)
        }

        func parseField(_ field: String) -> Int? {
            if field == "*" { return nil }
            return Int(field)
        }

        return Job.Schedule(
            minute: parseField(parts[0]),
            hour: parseField(parts[1]),
            day: parseField(parts[2]),
            weekday: parseField(parts[4]),
            month: parseField(parts[3]),
            interval: nil
        )
    }

    private func buildPlist(
        label: String,
        command: String,
        schedule: Job.Schedule?,
        runAtLoad: Bool,
        workingDirectory: String?,
        stdoutPath: String,
        stderrPath: String,
        env: [String: String]?
    ) -> String {
        var plist = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>\(label)</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>\(escapeXml(command))</string>
    </array>
"""

        if let schedule = schedule {
            if let interval = schedule.interval {
                plist += """
    <key>StartInterval</key>
    <integer>\(interval)</integer>
"""
            } else {
                plist += """
    <key>StartCalendarInterval</key>
    <dict>
"""
                if let minute = schedule.minute {
                    plist += """
        <key>Minute</key>
        <integer>\(minute)</integer>
"""
                }
                if let hour = schedule.hour {
                    plist += """
        <key>Hour</key>
        <integer>\(hour)</integer>
"""
                }
                if let day = schedule.day {
                    plist += """
        <key>Day</key>
        <integer>\(day)</integer>
"""
                }
                if let weekday = schedule.weekday {
                    plist += """
        <key>Weekday</key>
        <integer>\(weekday)</integer>
"""
                }
                if let month = schedule.month {
                    plist += """
        <key>Month</key>
        <integer>\(month)</integer>
"""
                }
                plist += """
    </dict>
"""
            }
        }

        if runAtLoad {
            plist += """
    <key>RunAtLoad</key>
    <true/>
"""
        }

        if let workDir = workingDirectory {
            plist += """
    <key>WorkingDirectory</key>
    <string>\(workDir)</string>
"""
        }

        plist += """
    <key>StandardOutPath</key>
    <string>\(stdoutPath)</string>
    <key>StandardErrorPath</key>
    <string>\(stderrPath)</string>
"""

        if let envVars = env, !envVars.isEmpty {
            plist += """
    <key>EnvironmentVariables</key>
    <dict>
"""
            for (key, value) in envVars {
                plist += """
        <key>\(key)</key>
        <string>\(escapeXml(value))</string>
"""
            }
            plist += """
    </dict>
"""
        }

        plist += """
</dict>
</plist>
"""
        return plist
    }

    private func escapeXml(_ str: String) -> String {
        var result = str
        result = result.replacingOccurrences(of: "&", with: "&amp;")
        result = result.replacingOccurrences(of: "<", with: "&lt;")
        result = result.replacingOccurrences(of: ">", with: "&gt;")
        result = result.replacingOccurrences(of: "\"", with: "&quot;")
        result = result.replacingOccurrences(of: "'", with: "&apos;")
        return result
    }

    private func loadJob(plistPath: String) throws {
        // launchctl load returns 0 even if already loaded, so we ignore exit code
        _ = try? Shell.execute("/bin/launchctl", args: ["load", plistPath])
    }

    private func unloadJob(plistPath: String) throws {
        // launchctl unload may fail if not loaded, that's ok
        _ = try? Shell.execute("/bin/launchctl", args: ["unload", plistPath])
    }

    private func parseJob(plistPath: String) throws -> Job {
        let url = URL(fileURLWithPath: plistPath)
        let data = try Data(contentsOf: url)

        guard let plist = try PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: nil
        ) as? [String: Any] else {
            throw LaunchdError.plistCreationFailed("Invalid plist format")
        }

        let label = plist["Label"] as? String ?? ""
        let name = label.hasPrefix(jobPrefix) ? String(label.dropFirst(jobPrefix.count)) : label

        // Extract command from ProgramArguments
        var command = ""
        if let args = plist["ProgramArguments"] as? [String] {
            if args.count >= 3 && args[0] == "/bin/bash" && args[1] == "-c" {
                command = args[2]
            } else {
                command = args.joined(separator: " ")
            }
        }

        // Parse schedule
        var schedule: Job.Schedule?
        if let interval = plist["StartInterval"] as? Int {
            schedule = Job.Schedule(
                minute: nil,
                hour: nil,
                day: nil,
                weekday: nil,
                month: nil,
                interval: interval
            )
        } else if let calInterval = plist["StartCalendarInterval"] as? [String: Int] {
            schedule = Job.Schedule(
                minute: calInterval["Minute"],
                hour: calInterval["Hour"],
                day: calInterval["Day"],
                weekday: calInterval["Weekday"],
                month: calInterval["Month"],
                interval: nil
            )
        }

        let runAtLoad = plist["RunAtLoad"] as? Bool ?? false
        let keepAlive = plist["KeepAlive"] as? Bool ?? false
        let workDir = plist["WorkingDirectory"] as? String
        let stdoutPath = plist["StandardOutPath"] as? String
        let stderrPath = plist["StandardErrorPath"] as? String
        let env = plist["EnvironmentVariables"] as? [String: String]

        // Check if loaded
        let enabled = isJobLoaded(label: label)

        return Job(
            name: name,
            label: label,
            command: command,
            schedule: schedule,
            runAtLoad: runAtLoad,
            keepAlive: keepAlive,
            workingDirectory: workDir,
            standardOutPath: stdoutPath,
            standardErrorPath: stderrPath,
            environmentVariables: env,
            enabled: enabled,
            plistPath: plistPath
        )
    }

    private func isJobLoaded(label: String) -> Bool {
        guard let result = try? Shell.execute("/bin/launchctl", args: ["list", label]) else {
            return false
        }
        return result.exitCode == 0
    }
}
