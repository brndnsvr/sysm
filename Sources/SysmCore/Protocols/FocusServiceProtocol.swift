import Foundation

/// Protocol defining Focus/Do Not Disturb service operations for macOS.
///
/// Implementations provide access to macOS Focus modes and Do Not Disturb settings,
/// supporting status queries and DND toggle through various system APIs.
public protocol FocusServiceProtocol: Sendable {
    /// Gets the current focus/DND status.
    /// - Returns: Status information including active state and focus mode name.
    func getStatus() throws -> FocusStatusInfo

    /// Enables Do Not Disturb mode.
    /// - Note: May require a Shortcuts automation to be set up.
    func enableDND() throws

    /// Disables Do Not Disturb mode.
    /// - Note: May require a Shortcuts automation to be set up.
    func disableDND() throws

    /// Lists available focus modes.
    /// - Returns: Array of focus mode names.
    func listFocusModes() throws -> [String]

    /// Activates a specific focus mode.
    /// - Parameter name: The name of the focus mode to activate.
    /// - Note: Requires a Shortcut named "Turn On [Focus Name]" to exist.
    func activateFocus(_ name: String) throws

    /// Deactivates the current focus mode.
    /// - Note: Requires a Shortcut named "Turn Off Focus" to exist.
    func deactivateFocus() throws
}
