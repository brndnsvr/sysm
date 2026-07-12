import Darwin
import Foundation
import Yams

public struct PluginManager: PluginManagerProtocol {

    // MARK: - Types

    public struct Plugin: Codable {
        public let name: String
        public let version: String
        public let description: String?
        public let author: String?
        public let commands: [Command]
        public let path: String

        public struct Command: Codable {
            public let name: String
            public let description: String?
            public let script: String
            public let args: [Argument]?

            public struct Argument: Codable {
                public let name: String
                public let description: String?
                public let required: Bool?
                public let type: String?  // flag, string, number
                public let defaultValue: String?

                enum CodingKeys: String, CodingKey {
                    case name, description, required, type
                    case defaultValue = "default"
                }
            }
        }
    }

    public struct PluginManifest: Codable {
        let name: String
        let version: String
        let description: String?
        let author: String?
        let commands: [Plugin.Command]
    }

    public enum PluginError: LocalizedError {
        case pluginsDirectoryNotFound
        case pluginNotFound(String)
        case manifestNotFound(String)
        case invalidManifest(String)
        case commandNotFound(String, String)
        case executionFailed(String)
        case pluginAlreadyExists(String)

        public var errorDescription: String? {
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

    public init() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        self.pluginsDir = "\(home)/.sysm/plugins"
    }

    /// Testable initializer with custom home directory.
    public init(home: String) {
        self.pluginsDir = "\(home)/.sysm/plugins"
    }

    /// Validates a plugin name contains no path traversal sequences.
    private func validatePluginName(_ name: String) throws {
        guard !name.isEmpty,
              !name.contains("/"),
              !name.contains("\\"),
              name != ".",
              name != ".." else {
            throw PluginError.pluginNotFound(name)
        }
    }

    /// Returns true when the candidate is physically below the supplied root.
    private func isDescendant(_ candidate: URL, of root: URL) -> Bool {
        let rootComponents = root.standardizedFileURL.pathComponents
        let candidateComponents = candidate.standardizedFileURL.pathComponents

        guard candidateComponents.count > rootComponents.count else {
            return false
        }

        return candidateComponents
            .prefix(rootComponents.count)
            .elementsEqual(rootComponents)
    }

    /// Opens a command script without following its final path component and
    /// captures the exact regular-file bytes that will be passed to Bash.
    private func readScriptForExecution(at url: URL) throws -> String {
        let descriptor = open(url.path, O_RDONLY | O_NOFOLLOW | O_CLOEXEC)
        guard descriptor >= 0 else {
            throw PluginError.executionFailed(
                "Script could not be opened safely: \(url.path)"
            )
        }

        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
        defer { try? handle.close() }

        var fileInfo = stat()
        guard fstat(descriptor, &fileInfo) == 0,
              (fileInfo.st_mode & S_IFMT) == S_IFREG else {
            throw PluginError.executionFailed("Script is not a regular file: \(url.path)")
        }

        let data: Data
        do {
            data = try handle.readToEnd() ?? Data()
        } catch {
            throw PluginError.executionFailed(
                "Failed to read script: \(error.localizedDescription)"
            )
        }

        guard let script = String(data: data, encoding: .utf8) else {
            throw PluginError.executionFailed("Script is not valid UTF-8: \(url.path)")
        }

        return script
    }

    /// Installation creates a private snapshot. Linked roots or descendants
    /// would preserve externally mutable content instead of copying reviewed bytes.
    private func validatePluginSnapshot(at root: URL) throws {
        let keys: Set<URLResourceKey> = [.isDirectoryKey, .isSymbolicLinkKey]
        let rootValues = try root.resourceValues(forKeys: keys)
        guard rootValues.isDirectory == true, rootValues.isSymbolicLink != true else {
            throw PluginError.invalidManifest("Plugin source must be a real directory")
        }

        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: Array(keys),
            options: []
        ) else {
            throw PluginError.invalidManifest("Plugin source could not be inspected")
        }

        for case let itemURL as URL in enumerator {
            let values = try itemURL.resourceValues(forKeys: keys)
            if values.isSymbolicLink == true {
                throw PluginError.invalidManifest(
                    "Plugin source contains a symbolic link: \(itemURL.lastPathComponent)"
                )
            }
        }
    }

    // MARK: - Plugin Discovery

    public func listPlugins() throws -> [Plugin] {
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

    public func getPlugin(name: String) throws -> Plugin {
        try validatePluginName(name)
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

    public func createPlugin(name: String, description: String?, force: Bool = false) throws -> String {
        try validatePluginName(name)
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

    public func installPlugin(from source: String, force: Bool = false) throws -> Plugin {
        let sourceURL = URL(fileURLWithPath: (source as NSString).expandingTildeInPath)
        try validatePluginSnapshot(at: sourceURL)

        // Read manifest from source
        let manifestPath = sourceURL.appendingPathComponent("plugin.yaml").path
        guard FileManager.default.fileExists(atPath: manifestPath) else {
            throw PluginError.manifestNotFound(manifestPath)
        }

        let content = try String(contentsOfFile: manifestPath, encoding: .utf8)
        let decoder = YAMLDecoder()
        let manifest = try decoder.decode(PluginManifest.self, from: content)

        try validatePluginName(manifest.name)

        let pluginsURL = URL(fileURLWithPath: pluginsDir, isDirectory: true)
            .standardizedFileURL
        let destURL = pluginsURL
            .appendingPathComponent(manifest.name, isDirectory: true)
            .standardizedFileURL
        guard destURL.deletingLastPathComponent().path == pluginsURL.path else {
            throw PluginError.pluginNotFound(manifest.name)
        }

        let destinationExists = FileManager.default.fileExists(atPath: destURL.path)
        if destinationExists && !force {
            throw PluginError.pluginAlreadyExists(manifest.name)
        }

        // Create plugins directory if needed
        try FileManager.default.createDirectory(
            at: pluginsURL,
            withIntermediateDirectories: true,
            attributes: nil
        )

        // Copy to a private staging directory and validate the installed snapshot
        // before replacing an existing plugin.
        let stagingURL = pluginsURL.appendingPathComponent(
            ".install-\(UUID().uuidString)",
            isDirectory: true
        )
        defer { try? FileManager.default.removeItem(at: stagingURL) }

        try FileManager.default.copyItem(at: sourceURL, to: stagingURL)
        try validatePluginSnapshot(at: stagingURL)

        if destinationExists {
            try FileManager.default.removeItem(at: destURL)
        }
        try FileManager.default.moveItem(at: stagingURL, to: destURL)
        do {
            try validatePluginSnapshot(at: destURL)
        } catch {
            try? FileManager.default.removeItem(at: destURL)
            throw error
        }

        return try loadPlugin(path: destURL.path)
    }

    // MARK: - Plugin Removal

    public func removePlugin(name: String) throws {
        try validatePluginName(name)
        let pluginPath = "\(pluginsDir)/\(name)"

        guard FileManager.default.fileExists(atPath: pluginPath) else {
            throw PluginError.pluginNotFound(name)
        }

        try FileManager.default.removeItem(atPath: pluginPath)
    }

    // MARK: - Command Execution

    public struct ExecutionResult: Codable {
        public let plugin: String
        public let command: String
        public let success: Bool
        public let exitCode: Int32
        public let stdout: String
        public let stderr: String
        public let duration: Double

        public func formatted() -> String {
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

    public func runCommand(
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

        let pluginURL = URL(fileURLWithPath: pluginData.path, isDirectory: true)
            .standardizedFileURL
            .resolvingSymlinksInPath()
        let scriptURL = URL(fileURLWithPath: pluginData.path, isDirectory: true)
            .appendingPathComponent(cmd.script, isDirectory: false)
            .standardizedFileURL
        let resolvedScriptURL = scriptURL.resolvingSymlinksInPath()

        guard isDescendant(resolvedScriptURL, of: pluginURL) else {
            throw PluginError.executionFailed(
                "Script resolves outside plugin directory: \(cmd.script)"
            )
        }

        let script = try readScriptForExecution(at: scriptURL)

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
        let result: Shell.Result
        do {
            result = try Shell.execute(
                "/bin/bash",
                args: ["-s", "--"],
                stdin: script,
                timeout: timeout,
                environment: env,
                workingDirectory: pluginData.path
            )
        } catch Shell.Error.timeout(let seconds) {
            throw PluginError.executionFailed("Timeout after \(Int(seconds)) seconds")
        } catch Shell.Error.launchFailed(let reason) {
            throw PluginError.executionFailed(reason)
        } catch {
            throw PluginError.executionFailed(error.localizedDescription)
        }

        return ExecutionResult(
            plugin: plugin,
            command: command,
            success: result.exitCode == 0,
            exitCode: result.exitCode,
            stdout: result.stdout,
            stderr: result.stderr,
            duration: Date().timeIntervalSince(startTime)
        )
    }

    // MARK: - Help Generation

    public func generateHelp(for plugin: Plugin) -> String {
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
