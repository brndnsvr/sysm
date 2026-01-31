import Foundation

public struct FocusService: FocusServiceProtocol {

    private var appleScript: any AppleScriptRunnerProtocol { Services.appleScriptRunner() }

    public init() {}

    // MARK: - Status

    public func getStatus() throws -> FocusStatusInfo {
        // Check if DND is enabled via defaults
        let dndEnabled = isDNDEnabled()

        // Try to get active focus mode name
        let activeFocus = getActiveFocusMode()

        return FocusStatusInfo(
            isActive: dndEnabled || activeFocus != nil,
            dndEnabled: dndEnabled,
            activeFocus: activeFocus
        )
    }

    // MARK: - DND Control

    public func enableDND() throws {
        // Use shortcuts to enable DND (most reliable method on modern macOS)
        let script = """
        tell application "Shortcuts Events"
            run shortcut "Turn On Do Not Disturb"
        end tell
        """

        // Try shortcuts first
        do {
            _ = try runAppleScript(script)
            return
        } catch {
            // Fall back to Control Center approach
            try toggleDNDViaControlCenter(enable: true)
        }
    }

    public func disableDND() throws {
        let script = """
        tell application "Shortcuts Events"
            run shortcut "Turn Off Do Not Disturb"
        end tell
        """

        do {
            _ = try runAppleScript(script)
            return
        } catch {
            try toggleDNDViaControlCenter(enable: false)
        }
    }

    // MARK: - Focus Modes List

    public func listFocusModes() throws -> [String] {
        // Focus modes are stored in user defaults
        // Also check ModeConfigurations.json for custom focus modes
        let modesPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/DoNotDisturb/DB/ModeConfigurations.json")

        var modes = ["Do Not Disturb"]  // Always available

        // Try to read custom focus modes
        if FileManager.default.fileExists(atPath: modesPath.path) {
            do {
                let data = try Data(contentsOf: modesPath)
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let modeList = json["data"] as? [[String: Any]] {
                    for mode in modeList {
                        if let name = mode["name"] as? String {
                            modes.append(name)
                        }
                    }
                }
            } catch {
                // Ignore parsing errors, just return default modes
            }
        }

        // Add common system focus modes that might be available
        let systemModes = ["Sleep", "Personal", "Work", "Driving", "Fitness", "Gaming", "Mindfulness", "Reading"]
        for mode in systemModes {
            if !modes.contains(mode) {
                modes.append(mode)
            }
        }

        return modes.sorted()
    }

    // MARK: - Focus Mode Activation

    public func activateFocus(_ name: String) throws {
        // Try using Shortcuts first (most reliable method)
        // Shortcuts should be named "Turn On [Focus Name]" (e.g., "Turn On Work")
        let shortcutName = "Turn On \(name)"
        let script = """
        tell application "Shortcuts Events"
            run shortcut "\(shortcutName)"
        end tell
        """

        do {
            _ = try runAppleScript(script)
        } catch {
            // Try alternative shortcut naming convention
            let altShortcutName = "Enable \(name)"
            let altScript = """
            tell application "Shortcuts Events"
                run shortcut "\(altShortcutName)"
            end tell
            """

            do {
                _ = try runAppleScript(altScript)
            } catch {
                throw FocusError.toggleFailed(
                    "Could not activate '\(name)' focus. " +
                    "Create a Shortcut named '\(shortcutName)' that enables this focus mode."
                )
            }
        }
    }

    public func deactivateFocus() throws {
        // Try to turn off any focus mode using Shortcuts
        let shortcutNames = ["Turn Off Focus", "Disable Focus", "Turn Off Do Not Disturb"]

        for shortcutName in shortcutNames {
            let script = """
            tell application "Shortcuts Events"
                run shortcut "\(shortcutName)"
            end tell
            """

            do {
                _ = try runAppleScript(script)
                return
            } catch {
                continue
            }
        }

        // Fall back to disabling DND
        try disableDND()
    }

    // MARK: - Private Helpers

    private func isDNDEnabled() -> Bool {
        do {
            let result = try Shell.execute(
                "/usr/bin/defaults",
                args: ["-currentHost", "read", "com.apple.notificationcenterui", "doNotDisturb"]
            )
            return result.stdout == "1"
        } catch {
            return false
        }
    }

    private func getActiveFocusMode() -> String? {
        // Try to read current focus mode from assertions
        let assertionsPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/DoNotDisturb/DB/Assertions.json")

        guard FileManager.default.fileExists(atPath: assertionsPath.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: assertionsPath)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let storeData = json["data"] as? [[String: Any]] {
                for assertion in storeData {
                    if let storeAssertionRecords = assertion["storeAssertionRecords"] as? [[String: Any]] {
                        for record in storeAssertionRecords {
                            if let assertionDetails = record["assertionDetails"] as? [String: Any],
                               let assertionDetailsModeIdentifier = assertionDetails["assertionDetailsModeIdentifier"] as? String {
                                // Convert identifier to friendly name
                                return friendlyFocusName(from: assertionDetailsModeIdentifier)
                            }
                        }
                    }
                }
            }
        } catch {
            // Ignore errors
        }

        return nil
    }

    private func friendlyFocusName(from identifier: String) -> String {
        // Map system identifiers to friendly names
        let mapping: [String: String] = [
            "com.apple.donotdisturb.mode.default": "Do Not Disturb",
            "com.apple.focus.sleep": "Sleep",
            "com.apple.focus.personal-time": "Personal",
            "com.apple.focus.work": "Work",
            "com.apple.focus.driving": "Driving",
            "com.apple.focus.fitness": "Fitness",
            "com.apple.focus.gaming": "Gaming",
            "com.apple.focus.mindfulness": "Mindfulness",
            "com.apple.focus.reading": "Reading",
        ]

        return mapping[identifier] ?? identifier
    }

    private func toggleDNDViaControlCenter(enable: Bool) throws {
        // Use System Events to click Control Center and toggle DND
        // This is fragile but works as a fallback
        let action = enable ? "turn on" : "turn off"
        let script = """
        tell application "System Events"
            tell application process "ControlCenter"
                -- Click the Focus menu item in Control Center
                click menu bar item "Focus" of menu bar 1
                delay 0.5
                -- Look for Do Not Disturb and click it
                try
                    click checkbox "Do Not Disturb" of group 1 of window "Control Center"
                end try
            end tell
        end tell
        """

        do {
            _ = try runAppleScript(script)
        } catch {
            throw FocusError.toggleFailed("Could not \(action) Do Not Disturb. Try using a Shortcut instead.")
        }
    }

    private func runAppleScript(_ script: String) throws -> String {
        do {
            return try appleScript.run(script, identifier: "focus")
        } catch AppleScriptError.executionFailed(let message) {
            throw FocusError.appleScriptError(message)
        }
    }
}

// MARK: - Models

public struct FocusStatusInfo: Codable {
    public let isActive: Bool
    public let dndEnabled: Bool
    public let activeFocus: String?
}

// MARK: - Errors

public enum FocusError: LocalizedError {
    case appleScriptError(String)
    case toggleFailed(String)
    case notSupported(String)

    public var errorDescription: String? {
        switch self {
        case .appleScriptError(let message):
            return "AppleScript error: \(message)"
        case .toggleFailed(let message):
            return message
        case .notSupported(let message):
            return message
        }
    }
}
