import Foundation

/// Protocol defining Focus/Do Not Disturb service operations for macOS.
///
/// This protocol provides access to macOS Focus modes and Do Not Disturb settings through
/// system APIs and Shortcuts integration. Supports querying focus status, toggling DND,
/// and activating specific focus modes.
///
/// ## Permission Requirements
///
/// Focus control requires:
/// - Shortcuts app with specific focus control shortcuts created
/// - Named shortcuts: "Turn On [Focus Name]", "Turn Off Focus"
/// - Automation permissions for Shortcuts.app
///
/// ## Usage Example
///
/// ```swift
/// let service = FocusService()
///
/// // Check current status
/// let status = try service.getStatus()
/// if status.isActive {
///     print("Focus mode active: \(status.focusModeName ?? "Unknown")")
/// }
///
/// // Enable Do Not Disturb
/// try service.enableDND()
///
/// // Activate a specific focus mode
/// try service.activateFocus("Work")
///
/// // List available focus modes
/// let modes = try service.listFocusModes()
/// print("Available: \(modes.joined(separator: ", "))")
/// ```
///
/// ## Thread Safety
///
/// Implementations are marked as `Sendable` and safe to use across actor boundaries.
/// Operations may interact with Shortcuts.app asynchronously.
///
/// ## Error Handling
///
/// Methods can throw ``FocusError`` variants:
/// - ``FocusError/shortcutNotFound(_:)`` - Required Shortcut not configured
/// - ``FocusError/shortcutsNotRunning`` - Shortcuts.app not available
/// - ``FocusError/activationFailed(_:)`` - Focus mode activation failed
/// - ``FocusError/unsupported`` - Focus API not available on this macOS version
///
public protocol FocusServiceProtocol: Sendable {
    // MARK: - Status

    /// Gets the current focus/DND status.
    ///
    /// Returns information about whether a focus mode is currently active and which mode.
    ///
    /// - Returns: ``FocusStatusInfo`` containing active state and focus mode name.
    /// - Throws: ``FocusError/unsupported`` if Focus API is not available.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let status = try service.getStatus()
    /// if status.isActive {
    ///     print("Active: \(status.focusModeName ?? "DND")")
    /// } else {
    ///     print("No focus mode active")
    /// }
    /// ```
    func getStatus() throws -> FocusStatusInfo

    /// Lists available focus modes.
    ///
    /// Returns names of all configured focus modes (Work, Personal, Sleep, etc.).
    ///
    /// - Returns: Array of focus mode names.
    /// - Throws: ``FocusError/unsupported`` if Focus API is not available.
    func listFocusModes() throws -> [String]

    // MARK: - Do Not Disturb Control

    /// Enables Do Not Disturb mode.
    ///
    /// Activates the system DND mode. Requires a Shortcut named "Turn On DND" or similar.
    ///
    /// - Throws:
    ///   - ``FocusError/shortcutNotFound(_:)`` if required Shortcut not found.
    ///   - ``FocusError/activationFailed(_:)`` if activation failed.
    ///
    /// ## Note
    ///
    /// Requires a Shortcuts automation to be set up for DND control.
    func enableDND() throws

    /// Disables Do Not Disturb mode.
    ///
    /// Deactivates the system DND mode. Requires a Shortcut named "Turn Off DND" or similar.
    ///
    /// - Throws:
    ///   - ``FocusError/shortcutNotFound(_:)`` if required Shortcut not found.
    ///   - ``FocusError/activationFailed(_:)`` if deactivation failed.
    ///
    /// ## Note
    ///
    /// Requires a Shortcuts automation to be set up for DND control.
    func disableDND() throws

    // MARK: - Focus Mode Control

    /// Activates a specific focus mode.
    ///
    /// Enables the named focus mode (e.g., "Work", "Personal", "Sleep"). Requires a corresponding
    /// Shortcut named "Turn On [Focus Name]".
    ///
    /// - Parameter name: The name of the focus mode to activate.
    /// - Throws:
    ///   - ``FocusError/shortcutNotFound(_:)`` if required Shortcut not found.
    ///   - ``FocusError/activationFailed(_:)`` if activation failed.
    ///
    /// ## Example
    ///
    /// ```swift
    /// try service.activateFocus("Work")  // Requires "Turn On Work" shortcut
    /// try service.activateFocus("Sleep") // Requires "Turn On Sleep" shortcut
    /// ```
    ///
    /// ## Shortcut Setup
    ///
    /// Create shortcuts in Shortcuts.app for each focus mode:
    /// - Name: "Turn On Work"
    /// - Action: Set Focus > Work
    func activateFocus(_ name: String) throws

    /// Deactivates the current focus mode.
    ///
    /// Turns off any active focus mode. Requires a Shortcut named "Turn Off Focus".
    ///
    /// - Throws:
    ///   - ``FocusError/shortcutNotFound(_:)`` if required Shortcut not found.
    ///   - ``FocusError/activationFailed(_:)`` if deactivation failed.
    ///
    /// ## Shortcut Setup
    ///
    /// Create a shortcut in Shortcuts.app:
    /// - Name: "Turn Off Focus"
    /// - Action: Set Focus > Turn Off
    func deactivateFocus() throws
}
