import Foundation

public struct FocusService: FocusServiceProtocol {

    private var appleScript: any AppleScriptRunnerProtocol { Services.appleScriptRunner() }

    public init() {}

    // MARK: - Status

    public func getStatus() throws -> FocusStatusInfo {
        // The focus that is on comes from Assertions.json and its name from
        // ModeConfigurations.json. Do Not Disturb is one of those modes, so its
        // state comes from the same record.
        let identifier = activeFocusIdentifier()
        let names = (try? modeNamesByIdentifier()) ?? [:]

        return FocusStatusInfo(
            isActive: identifier != nil,
            dndEnabled: identifier == Self.doNotDisturbIdentifier,
            activeFocus: identifier.map { names[$0] ?? $0 }
        )
    }

    // MARK: - DND Control

    public func enableDND() throws {
        try runDNDShortcut("Turn On Do Not Disturb")
    }

    public func disableDND() throws {
        try runDNDShortcut("Turn Off Do Not Disturb")
    }

    /// Runs one of the Do Not Disturb shortcuts. There is no fallback: the old
    /// one GUI-scripted the macOS 13 Control Center.
    private func runDNDShortcut(_ name: String) throws {
        let script = """
        tell application "Shortcuts Events"
            run shortcut "\(name)"
        end tell
        """
        do {
            _ = try runAppleScript(script)
        } catch {
            throw FocusError.toggleFailed(
                "Could not run the '\(name)' shortcut. Create a Shortcut with that name that sets Do Not Disturb."
            )
        }
    }

    // MARK: - Focus Modes List

    public func listFocusModes() throws -> [String] {
        Array(try modeNamesByIdentifier().values).sorted()
    }

    // MARK: - Focus Mode Activation

    public func activateFocus(_ name: String) throws {
        // Try using Shortcuts first (most reliable method)
        // Shortcuts should be named "Turn On [Focus Name]" (e.g., "Turn On Work").
        // The name is user input, so it is escaped before it enters the script.
        let shortcutName = "Turn On \(name)"
        let script = """
        tell application "Shortcuts Events"
            run shortcut "\(appleScript.escape(shortcutName))"
        end tell
        """

        do {
            _ = try runAppleScript(script)
        } catch {
            // Try alternative shortcut naming convention
            let altShortcutName = "Enable \(name)"
            let altScript = """
            tell application "Shortcuts Events"
                run shortcut "\(appleScript.escape(altShortcutName))"
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

    static let doNotDisturbIdentifier = "com.apple.donotdisturb.mode.default"

    private static var databaseURL: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/DoNotDisturb/DB")
    }

    /// Focus names keyed by mode identifier, from ModeConfigurations.json.
    private func modeNamesByIdentifier() throws -> [String: String] {
        let url = Self.databaseURL.appendingPathComponent("ModeConfigurations.json")
        do {
            return try Self.modeNamesByIdentifier(fromModeConfigurations: Data(contentsOf: url))
        } catch {
            throw FocusError.notSupported("Could not read Focus modes from \(url.path): \(error.localizedDescription)")
        }
    }

    /// Parses ModeConfigurations.json.
    ///
    /// Modes live under data[].modeConfigurations, a dictionary keyed by mode
    /// identifier whose values hold mode.name and mode.modeIdentifier. The old
    /// reader looked for data[].name, which the file does not have, so the
    /// list was only hardcoded names; the hardcoded identifiers for Sleep and
    /// Driving were wrong too.
    static func modeNamesByIdentifier(fromModeConfigurations data: Data) throws -> [String: String] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let stores = json["data"] as? [[String: Any]] else {
            throw FocusError.notSupported("ModeConfigurations.json has no data array")
        }

        var names: [String: String] = [:]
        for store in stores {
            guard let configurations = store["modeConfigurations"] as? [String: Any] else { continue }
            for (key, value) in configurations {
                guard let mode = (value as? [String: Any])?["mode"] as? [String: Any],
                      let name = mode["name"] as? String else { continue }
                names[mode["modeIdentifier"] as? String ?? key] = name
            }
        }
        return names
    }

    /// The identifier of the focus that is on, from Assertions.json, or nil.
    private func activeFocusIdentifier() -> String? {
        let url = Self.databaseURL.appendingPathComponent("Assertions.json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return Self.activeFocusIdentifier(fromAssertions: data)
    }

    static func activeFocusIdentifier(fromAssertions data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let stores = json["data"] as? [[String: Any]] else {
            return nil
        }
        for store in stores {
            for record in store["storeAssertionRecords"] as? [[String: Any]] ?? [] {
                if let details = record["assertionDetails"] as? [String: Any],
                   let identifier = details["assertionDetailsModeIdentifier"] as? String {
                    return identifier
                }
            }
        }
        return nil
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

public struct FocusStatusInfo: Codable, Sendable {
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
