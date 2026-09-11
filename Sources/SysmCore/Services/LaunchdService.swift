import Foundation

public struct LaunchdService: LaunchdServiceProtocol {

    // MARK: - Types

    public struct Job: Codable, Sendable {
        public let name: String
        public let label: String
        public let command: String
        public let schedule: Schedule?
        public let runAtLoad: Bool
        public let keepAlive: Bool
        public let workingDirectory: String?
        public let standardOutPath: String?
        public let standardErrorPath: String?
        public let environmentVariables: [String: String]?
        public let enabled: Bool
        public let plistPath: String

        public struct Schedule: Codable, Sendable {
            public let minute: Int?
            public let hour: Int?
            public let day: Int?
            public let weekday: Int?
            public let month: Int?
            public let interval: Int?  // Run every N seconds

            public var cronExpression: String {
                let m = minute.map { String($0) } ?? "*"
                let h = hour.map { String($0) } ?? "*"
                let d = day.map { String($0) } ?? "*"
                let mo = month.map { String($0) } ?? "*"
                let w = weekday.map { String($0) } ?? "*"
                return "\(m) \(h) \(d) \(mo) \(w)"
            }
        }
    }

    public enum LaunchdError: LocalizedError {
        case jobNotFound(String)
        case invalidCron(String)
        case plistCreationFailed(String)
        case launchctlFailed(String)
        case jobAlreadyExists(String)
        case invalidName(String)

        public var errorDescription: String? {
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
            case .invalidName(let name):
                return "Invalid job name \(name.debugDescription). Use up to 128 letters, digits, "
                    + "dots, underscores, or hyphens, starting with a letter or digit"
            }
        }
    }

    // MARK: - Paths

    private let launchAgentsDir: String
    private let logsDir: String
    private let jobPrefix = "com.sysm."

    public init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        self.launchAgentsDir = "\(home)/Library/LaunchAgents"
        self.logsDir = "\(home)/.sysm/logs"
    }

    // MARK: - Job Management

    public func createJob(
        name: String,
        command: String,
        cron: String? = nil,
        interval: Int? = nil,
        runAtLoad: Bool = false,
        workingDirectory: String? = nil,
        env: [String: String]? = nil,
        force: Bool = false
    ) throws -> Job {
        try Self.validateJobName(name)
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
        let plist = try buildPlist(
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
        try plist.write(to: URL(fileURLWithPath: plistPath), options: .atomic)

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

    public func removeJob(name: String) throws {
        try Self.validateJobName(name)
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

    public func enableJob(name: String) throws {
        try Self.validateJobName(name)
        let label = "\(jobPrefix)\(name)"
        let plistPath = "\(launchAgentsDir)/\(label).plist"

        guard FileManager.default.fileExists(atPath: plistPath) else {
            throw LaunchdError.jobNotFound(name)
        }

        try loadJob(plistPath: plistPath)
    }

    public func disableJob(name: String) throws {
        try Self.validateJobName(name)
        let label = "\(jobPrefix)\(name)"
        let plistPath = "\(launchAgentsDir)/\(label).plist"

        guard FileManager.default.fileExists(atPath: plistPath) else {
            throw LaunchdError.jobNotFound(name)
        }

        try unloadJob(plistPath: plistPath)
    }

    public func runJobNow(name: String) throws {
        try Self.validateJobName(name)
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

    public func listJobs() throws -> [Job] {
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

    public func getJob(name: String) throws -> Job {
        try Self.validateJobName(name)
        let label = "\(jobPrefix)\(name)"
        let plistPath = "\(launchAgentsDir)/\(label).plist"

        guard FileManager.default.fileExists(atPath: plistPath) else {
            throw LaunchdError.jobNotFound(name)
        }

        return try parseJob(plistPath: plistPath)
    }

    public func getJobLogs(name: String, lines: Int = 50) throws -> (stdout: String, stderr: String) {
        try Self.validateJobName(name)
        let stdoutPath = "\(logsDir)/\(name).log"
        let stderrPath = "\(logsDir)/\(name).error.log"

        let stdout = (try? String(contentsOfFile: stdoutPath, encoding: .utf8)) ?? ""
        let stderr = (try? String(contentsOfFile: stderrPath, encoding: .utf8)) ?? ""

        // Return last N lines
        let stdoutLines = stdout.components(separatedBy: .newlines).suffix(lines).joined(separator: "\n")
        let stderrLines = stderr.components(separatedBy: .newlines).suffix(lines).joined(separator: "\n")

        return (stdoutLines, stderrLines)
    }

    // MARK: - Validation

    /// Job names become part of the launchd label, the plist filename, and the
    /// log filenames, so they are limited to a filename-safe ASCII set. Every
    /// public entry point calls this before touching the filesystem or launchctl.
    static func validateJobName(_ name: String) throws {
        func isAlphanumeric(_ scalar: Unicode.Scalar) -> Bool {
            switch scalar.value {
            case 0x30...0x39, 0x41...0x5A, 0x61...0x7A: return true
            default: return false
            }
        }
        let scalars = name.unicodeScalars
        guard let first = scalars.first,
              isAlphanumeric(first),
              scalars.count <= 128,
              scalars.allSatisfy({ isAlphanumeric($0) || $0 == "." || $0 == "_" || $0 == "-" }) else {
            throw LaunchdError.invalidName(name)
        }
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

    /// Serializes the job with PropertyListSerialization so every string value
    /// (command, working directory, environment keys and values) is escaped by
    /// Foundation instead of being spliced into XML by hand.
    func buildPlist(
        label: String,
        command: String,
        schedule: Job.Schedule?,
        runAtLoad: Bool,
        workingDirectory: String?,
        stdoutPath: String,
        stderrPath: String,
        env: [String: String]?
    ) throws -> Data {
        var plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": ["/bin/bash", "-c", command],
            "StandardOutPath": stdoutPath,
            "StandardErrorPath": stderrPath,
        ]

        if let schedule = schedule {
            if let interval = schedule.interval {
                plist["StartInterval"] = interval
            } else {
                var calendar: [String: Int] = [:]
                calendar["Minute"] = schedule.minute
                calendar["Hour"] = schedule.hour
                calendar["Day"] = schedule.day
                calendar["Weekday"] = schedule.weekday
                calendar["Month"] = schedule.month
                plist["StartCalendarInterval"] = calendar
            }
        }

        if runAtLoad {
            plist["RunAtLoad"] = true
        }
        if let workingDirectory = workingDirectory {
            plist["WorkingDirectory"] = workingDirectory
        }
        if let env = env, !env.isEmpty {
            plist["EnvironmentVariables"] = env
        }

        do {
            return try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        } catch {
            throw LaunchdError.plistCreationFailed(error.localizedDescription)
        }
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
