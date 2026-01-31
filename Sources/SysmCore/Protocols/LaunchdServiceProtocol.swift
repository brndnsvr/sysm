import Foundation

/// Protocol defining launchd job management operations.
///
/// Implementations handle creating, managing, and monitoring launchd jobs
/// for scheduling recurring tasks on macOS.
public protocol LaunchdServiceProtocol: Sendable {
    /// Creates a new launchd job.
    /// - Parameters:
    ///   - name: Job name (will be prefixed with com.sysm.)
    ///   - command: Shell command to execute.
    ///   - cron: Cron expression for scheduling (optional).
    ///   - interval: Interval in seconds for recurring execution (optional).
    ///   - runAtLoad: Whether to run immediately when loaded.
    ///   - workingDirectory: Working directory for the job.
    ///   - env: Environment variables.
    ///   - force: Whether to overwrite existing job.
    /// - Returns: The created job.
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
    /// - Parameter name: Job name.
    func removeJob(name: String) throws

    /// Enables (loads) a launchd job.
    /// - Parameter name: Job name.
    func enableJob(name: String) throws

    /// Disables (unloads) a launchd job.
    /// - Parameter name: Job name.
    func disableJob(name: String) throws

    /// Runs a job immediately.
    /// - Parameter name: Job name.
    func runJobNow(name: String) throws

    /// Lists all sysm-managed launchd jobs.
    /// - Returns: Array of jobs.
    func listJobs() throws -> [LaunchdService.Job]

    /// Gets a specific job by name.
    /// - Parameter name: Job name.
    /// - Returns: The job.
    func getJob(name: String) throws -> LaunchdService.Job

    /// Gets job logs.
    /// - Parameters:
    ///   - name: Job name.
    ///   - lines: Number of lines to return (default 50).
    /// - Returns: Tuple of stdout and stderr logs.
    func getJobLogs(name: String, lines: Int) throws -> (stdout: String, stderr: String)
}
