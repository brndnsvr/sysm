import Foundation

struct FocusService: FocusServiceProtocol {

    // MARK: - Status

    func getStatus() throws -> FocusStatusInfo {
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

    func enableDND() throws {
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

    func disableDND() throws {
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

    func listFocusModes() throws -> [String] {
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

    // MARK: - Private Helpers

    private func isDNDEnabled() -> Bool {
        // Check DND status via defaults
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
        task.arguments = ["-currentHost", "read", "com.apple.notificationcenterui", "doNotDisturb"]

        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            return output == "1"
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
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("sysm-focus-\(UUID().uuidString).scpt")
        try script.write(to: tempFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempFile) }

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = [tempFile.path]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe

        try task.run()
        task.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        if task.terminationStatus != 0 {
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw FocusError.appleScriptError(errorMessage)
        }

        return String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

// MARK: - Models

struct FocusStatusInfo: Codable {
    let isActive: Bool
    let dndEnabled: Bool
    let activeFocus: String?
}

// MARK: - Errors

enum FocusError: LocalizedError {
    case appleScriptError(String)
    case toggleFailed(String)
    case notSupported(String)

    var errorDescription: String? {
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
