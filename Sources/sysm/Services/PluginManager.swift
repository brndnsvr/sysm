import Foundation
import Yams

struct PluginManager {

    // MARK: - Types

    struct Plugin: Codable {
        let name: String
        let version: String
        let description: String?
        let author: String?
        let commands: [Command]
        let path: String

        struct Command: Codable {
            let name: String
            let description: String?
            let script: String
            let args: [Argument]?

            struct Argument: Codable {
                let name: String
                let description: String?
                let required: Bool?
                let type: String?  // flag, string, number
                let defaultValue: String?

                enum CodingKeys: String, CodingKey {
                    case name, description, required, type
                    case defaultValue = "default"
                }
            }
        }
    }

    struct PluginManifest: Codable {
        let name: String
        let version: String
        let description: String?
        let author: String?
        let commands: [Plugin.Command]
    }

    enum PluginError: LocalizedError {
        case pluginsDirectoryNotFound
        case pluginNotFound(String)
        case manifestNotFound(String)
        case invalidManifest(String)
        case commandNotFound(String, String)
        case executionFailed(String)
        case pluginAlreadyExists(String)

        var errorDescription: String? {
            switch self {
            case .pluginsDirectoryNotFound:
                return "Plugins directory not found"
            case .pluginNotFound(let name):
                return "Plugin not found: \(name)"
            case .manifestNotFound(let path):
                return "Plugin manifest not found: \(path)"
            case .invalidManifest(let reason):
                return "Invalid plugin manifest: \(reason)"
            case .commandNotFound(let plugin, let command):
                return "Command '\(command)' not found in plugin '\(plugin)'"
            case .executionFailed(let reason):
                return "Plugin execution failed: \(reason)"
            case .pluginAlreadyExists(let name):
                return "Plugin already exists: \(name)"
            }
        }
    }

    // MARK: - Paths

    private let pluginsDir: String

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        self.pluginsDir = "\(home)/.sysm/plugins"
    }

    // MARK: - Plugin Discovery

    func listPlugins() throws -> [Plugin] {
        guard FileManager.default.fileExists(atPath: pluginsDir) else {
            return []
        }

        let contents = try FileManager.default.contentsOfDirectory(atPath: pluginsDir)
        var plugins: [Plugin] = []

        for dir in contents {
            let pluginPath = "\(pluginsDir)/\(dir)"
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: pluginPath, isDirectory: &isDir),
                  isDir.boolValue else { continue }

            do {
                let plugin = try loadPlugin(path: pluginPath)
                plugins.append(plugin)
            } catch {
                fputs("Warning: Failed to load plugin '\(dir)': \(error.localizedDescription)\n", stderr)
            }
        }

        return plugins.sorted { $0.name < $1.name }
    }

    func getPlugin(name: String) throws -> Plugin {
        let pluginPath = "\(pluginsDir)/\(name)"

        guard FileManager.default.fileExists(atPath: pluginPath) else {
            throw PluginError.pluginNotFound(name)
        }

        return try loadPlugin(path: pluginPath)
    }

    // MARK: - Plugin Loading

    private func loadPlugin(path: String) throws -> Plugin {
        let manifestPath = "\(path)/plugin.yaml"

        guard FileManager.default.fileExists(atPath: manifestPath) else {
            throw PluginError.manifestNotFound(manifestPath)
        }

        let content = try String(contentsOfFile: manifestPath, encoding: .utf8)
        let decoder = YAMLDecoder()

        do {
            let manifest = try decoder.decode(PluginManifest.self, from: content)
            return Plugin(
                name: manifest.name,
                version: manifest.version,
                description: manifest.description,
                author: manifest.author,
                commands: manifest.commands,
                path: path
            )
        } catch {
            throw PluginError.invalidManifest(error.localizedDescription)
        }
    }

    // MARK: - Plugin Creation

    func createPlugin(name: String, description: String?, force: Bool = false) throws -> String {
        let pluginPath = "\(pluginsDir)/\(name)"

        if FileManager.default.fileExists(atPath: pluginPath) && !force {
            throw PluginError.pluginAlreadyExists(name)
        }

        // Create plugin directory
        try FileManager.default.createDirectory(
            atPath: pluginPath,
            withIntermediateDirectories: true,
            attributes: nil
        )

        // Create manifest
        let manifest = """
name: \(name)
version: "1.0.0"
description: \(description ?? "A sysm plugin")
author: ""

commands:
  - name: hello
    description: Say hello
    script: main.sh
    args:
      - name: name
        description: Name to greet
        required: false
        default: "world"
"""
        try manifest.write(toFile: "\(pluginPath)/plugin.yaml", atomically: true, encoding: .utf8)

        // Create main script
        let script = """
#!/bin/bash
# \(name) plugin main script
#
# Arguments are passed as environment variables:
#   SYSM_ARG_<NAME> - argument values
#   SYSM_PLUGIN - plugin name
#   SYSM_COMMAND - command name

NAME="${SYSM_ARG_NAME:-world}"
echo "Hello, $NAME!"
"""
        let scriptPath = "\(pluginPath)/main.sh"
        try script.write(toFile: scriptPath, atomically: true, encoding: .utf8)

        // Make script executable
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: scriptPath
        )

        return pluginPath
    }

    // MARK: - Plugin Installation

    func installPlugin(from source: String, force: Bool = false) throws -> Plugin {
        let sourceURL = URL(fileURLWithPath: (source as NSString).expandingTildeInPath)

        // Read manifest from source
        let manifestPath = sourceURL.appendingPathComponent("plugin.yaml").path
        guard FileManager.default.fileExists(atPath: manifestPath) else {
            throw PluginError.manifestNotFound(manifestPath)
        }

        let content = try String(contentsOfFile: manifestPath, encoding: .utf8)
        let decoder = YAMLDecoder()
        let manifest = try decoder.decode(PluginManifest.self, from: content)

        let destPath = "\(pluginsDir)/\(manifest.name)"

        if FileManager.default.fileExists(atPath: destPath) {
            if force {
                try FileManager.default.removeItem(atPath: destPath)
            } else {
                throw PluginError.pluginAlreadyExists(manifest.name)
            }
        }

        // Create plugins directory if needed
        try FileManager.default.createDirectory(
            atPath: pluginsDir,
            withIntermediateDirectories: true,
            attributes: nil
        )

        // Copy plugin
        try FileManager.default.copyItem(atPath: sourceURL.path, toPath: destPath)

        return try loadPlugin(path: destPath)
    }

    // MARK: - Plugin Removal

    func removePlugin(name: String) throws {
        let pluginPath = "\(pluginsDir)/\(name)"

        guard FileManager.default.fileExists(atPath: pluginPath) else {
            throw PluginError.pluginNotFound(name)
        }

        try FileManager.default.removeItem(atPath: pluginPath)
    }

    // MARK: - Command Execution

    struct ExecutionResult: Codable {
        let plugin: String
        let command: String
        let success: Bool
        let exitCode: Int32
        let stdout: String
        let stderr: String
        let duration: Double

        func formatted() -> String {
            if success {
                return stdout.isEmpty ? "(no output)" : stdout
            } else {
                var output = ""
                if !stdout.isEmpty {
                    output += stdout
                }
                if !stderr.isEmpty {
                    if !output.isEmpty { output += "\n" }
                    output += "Error: \(stderr)"
                }
                output += "\nExit code: \(exitCode)"
                return output
            }
        }
    }

    func runCommand(
        plugin: String,
        command: String,
        args: [String: String] = [:],
        timeout: TimeInterval = 300
    ) throws -> ExecutionResult {
        let startTime = Date()

        let pluginData = try getPlugin(name: plugin)

        guard let cmd = pluginData.commands.first(where: { $0.name == command }) else {
            throw PluginError.commandNotFound(plugin, command)
        }

        let scriptPath = "\(pluginData.path)/\(cmd.script)"

        guard FileManager.default.fileExists(atPath: scriptPath) else {
            throw PluginError.executionFailed("Script not found: \(scriptPath)")
        }

        // Build environment
        var env = ProcessInfo.processInfo.environment
        env["SYSM_PLUGIN"] = plugin
        env["SYSM_COMMAND"] = command
        env["SYSM_VERSION"] = "1.0.0"

        // Add arguments as environment variables
        for (key, value) in args {
            let envKey = "SYSM_ARG_\(key.uppercased().replacingOccurrences(of: "-", with: "_"))"
            env[envKey] = value
        }

        // Add defaults for missing arguments
        if let argDefs = cmd.args {
            for argDef in argDefs {
                let key = argDef.name.hasPrefix("--") ? String(argDef.name.dropFirst(2)) : argDef.name
                let envKey = "SYSM_ARG_\(key.uppercased().replacingOccurrences(of: "-", with: "_"))"
                if env[envKey] == nil, let defaultVal = argDef.defaultValue {
                    env[envKey] = defaultVal
                }
            }
        }

        // Execute script
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = [scriptPath]
        task.currentDirectoryURL = URL(fileURLWithPath: pluginData.path)
        task.environment = env

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe

        // Timeout handling
        var timedOut = false
        let timeoutWorkItem = DispatchWorkItem {
            timedOut = true
            task.terminate()
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: timeoutWorkItem)

        do {
            try task.run()
        } catch {
            timeoutWorkItem.cancel()
            throw PluginError.executionFailed(error.localizedDescription)
        }

        task.waitUntilExit()
        timeoutWorkItem.cancel()

        if timedOut {
            throw PluginError.executionFailed("Timeout after \(Int(timeout)) seconds")
        }

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

        let stdout = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let stderr = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return ExecutionResult(
            plugin: plugin,
            command: command,
            success: task.terminationStatus == 0,
            exitCode: task.terminationStatus,
            stdout: stdout,
            stderr: stderr,
            duration: Date().timeIntervalSince(startTime)
        )
    }

    // MARK: - Help Generation

    func generateHelp(for plugin: Plugin) -> String {
        var help = ""
        help += "Plugin: \(plugin.name) v\(plugin.version)\n"
        if let desc = plugin.description {
            help += "\(desc)\n"
        }
        if let author = plugin.author, !author.isEmpty {
            help += "Author: \(author)\n"
        }
        help += "\nCommands:\n"

        for cmd in plugin.commands {
            help += "  \(cmd.name)"
            if let desc = cmd.description {
                help += " - \(desc)"
            }
            help += "\n"

            if let args = cmd.args, !args.isEmpty {
                for arg in args {
                    let required = arg.required == true ? " (required)" : ""
                    help += "    \(arg.name)\(required)"
                    if let desc = arg.description {
                        help += ": \(desc)"
                    }
                    if let def = arg.defaultValue {
                        help += " [default: \(def)]"
                    }
                    help += "\n"
                }
            }
        }

        return help
    }
}
