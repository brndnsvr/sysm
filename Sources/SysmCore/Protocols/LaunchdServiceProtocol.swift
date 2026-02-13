import Foundation

/// Protocol defining launchd job management operations.
///
/// This protocol handles creating, managing, and monitoring launchd jobs for scheduling recurring
/// tasks on macOS. Provides access to launchd user agents with support for cron-style scheduling,
/// interval-based execution, and job lifecycle management.
///
/// ## Launchd Jobs
///
/// Jobs are configured as property list files in `~/Library/LaunchAgents/` with label prefix
/// `com.sysm.`. Supports:
/// - Cron-style scheduling (StartCalendarInterval)
/// - Fixed interval execution (StartInterval)
/// - Run-at-load execution
/// - Environment variables and working directories
///
/// ## Usage Example
///
/// ```swift
/// let service = LaunchdService()
///
/// // Create a job with interval
/// let job = try service.createJob(
///     name: "backup",
///     command: "/usr/local/bin/backup.sh",
///     cron: nil,
///     interval: 3600,  // Every hour
///     runAtLoad: false,
///     workingDirectory: "/tmp",
///     env: ["BACKUP_DIR": "/backups"],
///     force: false
/// )
///
/// // Create a job with cron schedule
/// let cronJob = try service.createJob(
///     name: "daily-report",
///     command: "/usr/local/bin/report.sh",
///     cron: "0 9 * * *",  // 9 AM daily
///     interval: nil,
///     runAtLoad: false,
///     workingDirectory: nil,
///     env: nil,
///     force: false
/// )
///
/// // List all jobs
/// let jobs = try service.listJobs()
/// for job in jobs {
///     print("\(job.name): \(job.loaded ? "running" : "stopped")")
/// }
/// ```
///
/// ## Thread Safety
///
/// Implementations are marked as `Sendable` and safe to use across actor boundaries.
/// Launchd operations are synchronous.
///
/// ## Error Handling
///
/// Methods can throw ``LaunchdError`` variants:
/// - ``LaunchdError/jobNotFound(_:)`` - Job doesn't exist
/// - ``LaunchdError/jobAlreadyExists(_:)`` - Job with name already exists
/// - ``LaunchdError/invalidCron(_:)`` - Cron expression format invalid
/// - ``LaunchdError/loadFailed(_:)`` - Failed to load job into launchd
/// - ``LaunchdError/unloadFailed(_:)`` - Failed to unload job from launchd
/// - ``LaunchdError/permissionDenied`` - Insufficient permissions
///
public protocol LaunchdServiceProtocol: Sendable {
    // MARK: - Job Management

    /// Creates a new launchd job.
    ///
    /// Creates a launchd user agent plist and optionally loads it. The job label is
    /// automatically prefixed with `com.sysm.`.
    ///
    /// - Parameters:
    ///   - name: Job name (will be prefixed with com.sysm., e.g., "backup" becomes "com.sysm.backup").
    ///   - command: Shell command to execute (full path recommended).
    ///   - cron: Optional cron expression (e.g., "0 9 * * *" for 9 AM daily). Mutually exclusive with interval.
    ///   - interval: Optional interval in seconds for recurring execution. Mutually exclusive with cron.
    ///   - runAtLoad: If true, runs the job immediately when loaded.
    ///   - workingDirectory: Optional working directory for command execution.
    ///   - env: Optional environment variables for the job.
    ///   - force: If true, overwrites existing job with the same name.
    /// - Returns: The created ``LaunchdService/Job`` object.
    /// - Throws:
    ///   - ``LaunchdError/jobAlreadyExists(_:)`` if job exists and force is false.
    ///   - ``LaunchdError/invalidCron(_:)`` if cron expression is invalid.
    ///   - ``LaunchdError/permissionDenied`` if cannot write to LaunchAgents directory.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Interval-based job (every 5 minutes)
    /// let job1 = try service.createJob(
    ///     name: "monitor",
    ///     command: "/usr/local/bin/monitor.sh",
    ///     cron: nil,
    ///     interval: 300,
    ///     runAtLoad: true,
    ///     workingDirectory: "/tmp",
    ///     env: ["LOG_LEVEL": "INFO"],
    ///     force: false
    /// )
    ///
    /// // Cron-based job (daily at 2 AM)
    /// let job2 = try service.createJob(
    ///     name: "cleanup",
    ///     command: "/usr/local/bin/cleanup.sh",
    ///     cron: "0 2 * * *",
    ///     interval: nil,
    ///     runAtLoad: false,
    ///     workingDirectory: nil,
    ///     env: nil,
    ///     force: false
    /// )
    /// ```
    func createJob(
        name: String,
        command: String,
        cron: String?,
        interval: Int?,
        runAtLoad: Bool,
        workingDirectory: String?,
        env: [String: String]?,
        force: Bool
    ) throws -> LaunchdService.Job

    /// Removes a launchd job.
    ///
    /// Unloads the job if currently loaded and deletes the plist file.
    ///
    /// - Parameter name: Job name (without com.sysm. prefix).
    /// - Throws:
    ///   - ``LaunchdError/jobNotFound(_:)`` if job doesn't exist.
    ///   - ``LaunchdError/unloadFailed(_:)`` if unloading failed.
    func removeJob(name: String) throws

    /// Enables (loads) a launchd job.
    ///
    /// Loads the job into launchd, making it active. The job will run according to
    /// its schedule or immediately if runAtLoad is true.
    ///
    /// - Parameter name: Job name (without com.sysm. prefix).
    /// - Throws:
    ///   - ``LaunchdError/jobNotFound(_:)`` if job doesn't exist.
    ///   - ``LaunchdError/loadFailed(_:)`` if loading failed.
    func enableJob(name: String) throws

    /// Disables (unloads) a launchd job.
    ///
    /// Unloads the job from launchd, stopping it from running. The plist file remains
    /// and the job can be re-enabled.
    ///
    /// - Parameter name: Job name (without com.sysm. prefix).
    /// - Throws:
    ///   - ``LaunchdError/jobNotFound(_:)`` if job doesn't exist.
    ///   - ``LaunchdError/unloadFailed(_:)`` if unloading failed.
    func disableJob(name: String) throws

    /// Runs a job immediately, bypassing its schedule.
    ///
    /// Triggers an immediate execution of the job using `launchctl kickstart`.
    ///
    /// - Parameter name: Job name (without com.sysm. prefix).
    /// - Throws:
    ///   - ``LaunchdError/jobNotFound(_:)`` if job doesn't exist.
    ///   - ``LaunchdError/loadFailed(_:)`` if job is not currently loaded.
    func runJobNow(name: String) throws

    // MARK: - Queries

    /// Lists all sysm-managed launchd jobs.
    ///
    /// Returns all jobs with the com.sysm. label prefix, including their loaded status.
    ///
    /// - Returns: Array of ``LaunchdService/Job`` objects.
    /// - Throws: File system errors if cannot read LaunchAgents directory.
    func listJobs() throws -> [LaunchdService.Job]

    /// Gets a specific job by name.
    ///
    /// Retrieves full details about a specific job.
    ///
    /// - Parameter name: Job name (without com.sysm. prefix).
    /// - Returns: The ``LaunchdService/Job`` object.
    /// - Throws: ``LaunchdError/jobNotFound(_:)`` if job doesn't exist.
    func getJob(name: String) throws -> LaunchdService.Job

    /// Gets job execution logs.
    ///
    /// Retrieves stdout and stderr logs for the job from its log files.
    ///
    /// - Parameters:
    ///   - name: Job name (without com.sysm. prefix).
    ///   - lines: Number of lines to return from end of each log file (default 50).
    /// - Returns: Tuple of (stdout, stderr) log content.
    /// - Throws: ``LaunchdError/jobNotFound(_:)`` if job doesn't exist.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let (stdout, stderr) = try service.getJobLogs(name: "backup", lines: 100)
    /// print("Recent output:")
    /// print(stdout)
    /// if !stderr.isEmpty {
    ///     print("\nErrors:")
    ///     print(stderr)
    /// }
    /// ```
    func getJobLogs(name: String, lines: Int) throws -> (stdout: String, stderr: String)
}
