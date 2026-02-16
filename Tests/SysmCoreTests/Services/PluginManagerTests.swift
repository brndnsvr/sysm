import XCTest
@testable import SysmCore

final class PluginManagerTests: XCTestCase {
    var tempDir: URL!
    var pluginManager: PluginManager!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("sysm_plugin_test_\(UUID().uuidString)")
        let pluginsDir = tempDir.appendingPathComponent(".sysm/plugins").path
        try? FileManager.default.createDirectory(
            atPath: pluginsDir,
            withIntermediateDirectories: true,
            attributes: nil
        )
        pluginManager = PluginManager(home: tempDir.path)
    }

    override func tearDown() {
        if let tempDir = tempDir {
            try? FileManager.default.removeItem(at: tempDir)
        }
        super.tearDown()
    }

    // MARK: - Plugin Discovery

    func testListPluginsEmptyDir() throws {
        let plugins = try pluginManager.listPlugins()
        XCTAssertTrue(plugins.isEmpty)
    }

    func testListPluginsFindsValid() throws {
        try createTestPlugin(name: "hello")
        let plugins = try pluginManager.listPlugins()
        XCTAssertEqual(plugins.count, 1)
        XCTAssertEqual(plugins[0].name, "hello")
    }

    func testGetPluginByName() throws {
        try createTestPlugin(name: "test-plugin")
        let plugin = try pluginManager.getPlugin(name: "test-plugin")
        XCTAssertEqual(plugin.name, "test-plugin")
        XCTAssertEqual(plugin.version, "1.0.0")
    }

    func testGetPluginNotFound() {
        XCTAssertThrowsError(try pluginManager.getPlugin(name: "nonexistent")) { error in
            guard case PluginManager.PluginError.pluginNotFound = error else {
                XCTFail("Expected pluginNotFound, got \(error)")
                return
            }
        }
    }

    // MARK: - Path Traversal Prevention

    func testGetPluginRejectsPathTraversal() {
        XCTAssertThrowsError(try pluginManager.getPlugin(name: "../etc"))
        XCTAssertThrowsError(try pluginManager.getPlugin(name: "foo/bar"))
        XCTAssertThrowsError(try pluginManager.getPlugin(name: ".."))
        XCTAssertThrowsError(try pluginManager.getPlugin(name: "."))
        XCTAssertThrowsError(try pluginManager.getPlugin(name: ""))
        XCTAssertThrowsError(try pluginManager.getPlugin(name: "foo\\bar"))
    }

    func testCreatePluginRejectsPathTraversal() {
        XCTAssertThrowsError(try pluginManager.createPlugin(name: "../evil", description: nil))
        XCTAssertThrowsError(try pluginManager.createPlugin(name: "a/b", description: nil))
        XCTAssertThrowsError(try pluginManager.createPlugin(name: "", description: nil))
    }

    func testRemovePluginRejectsPathTraversal() {
        XCTAssertThrowsError(try pluginManager.removePlugin(name: "../../"))
        XCTAssertThrowsError(try pluginManager.removePlugin(name: ".."))
    }

    // MARK: - Plugin Creation

    func testCreatePlugin() throws {
        let path = try pluginManager.createPlugin(name: "my-plugin", description: "A test plugin")
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))

        let plugin = try pluginManager.getPlugin(name: "my-plugin")
        XCTAssertEqual(plugin.name, "my-plugin")
        XCTAssertEqual(plugin.description, "A test plugin")
    }

    func testCreatePluginAlreadyExists() throws {
        _ = try pluginManager.createPlugin(name: "duplicate", description: nil)
        XCTAssertThrowsError(try pluginManager.createPlugin(name: "duplicate", description: nil)) { error in
            guard case PluginManager.PluginError.pluginAlreadyExists = error else {
                XCTFail("Expected pluginAlreadyExists, got \(error)")
                return
            }
        }
    }

    func testCreatePluginForceOverwrite() throws {
        _ = try pluginManager.createPlugin(name: "overwrite", description: "v1")
        _ = try pluginManager.createPlugin(name: "overwrite", description: "v2", force: true)
        let plugin = try pluginManager.getPlugin(name: "overwrite")
        XCTAssertEqual(plugin.description, "v2")
    }

    // MARK: - Plugin Removal

    func testRemovePlugin() throws {
        _ = try pluginManager.createPlugin(name: "to-remove", description: nil)
        try pluginManager.removePlugin(name: "to-remove")
        XCTAssertThrowsError(try pluginManager.getPlugin(name: "to-remove"))
    }

    func testRemovePluginNotFound() {
        XCTAssertThrowsError(try pluginManager.removePlugin(name: "ghost")) { error in
            guard case PluginManager.PluginError.pluginNotFound = error else {
                XCTFail("Expected pluginNotFound, got \(error)")
                return
            }
        }
    }

    // MARK: - Command Execution

    func testRunCommand() throws {
        try createTestPlugin(name: "runner", scriptContent: "#!/bin/bash\necho 'hello from plugin'")
        let result = try pluginManager.runCommand(plugin: "runner", command: "greet")
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.stdout.contains("hello from plugin"))
        XCTAssertEqual(result.exitCode, 0)
    }

    func testRunCommandNotFound() throws {
        try createTestPlugin(name: "runner")
        XCTAssertThrowsError(try pluginManager.runCommand(plugin: "runner", command: "nonexistent")) { error in
            guard case PluginManager.PluginError.commandNotFound = error else {
                XCTFail("Expected commandNotFound, got \(error)")
                return
            }
        }
    }

    func testRunCommandPassesArgs() throws {
        try createTestPlugin(name: "echo-args", scriptContent: "#!/bin/bash\necho \"Name: $SYSM_ARG_NAME\"")
        let result = try pluginManager.runCommand(plugin: "echo-args", command: "greet", args: ["name": "World"])
        XCTAssertTrue(result.stdout.contains("Name: World"))
    }

    func testRunCommandScriptPathTraversal() throws {
        // Create plugin with a script path that tries to escape the plugin directory
        try createTestPlugin(name: "evil-script", scriptName: "../../../etc/passwd")
        XCTAssertThrowsError(try pluginManager.runCommand(plugin: "evil-script", command: "greet")) { error in
            guard case PluginManager.PluginError.executionFailed = error else {
                XCTFail("Expected executionFailed, got \(error)")
                return
            }
        }
    }

    // MARK: - ExecutionResult Formatting

    func testExecutionResultFormattedSuccess() {
        let result = PluginManager.ExecutionResult(
            plugin: "test", command: "cmd", success: true, exitCode: 0,
            stdout: "output text", stderr: "", duration: 0.1
        )
        XCTAssertEqual(result.formatted(), "output text")
    }

    func testExecutionResultFormattedEmpty() {
        let result = PluginManager.ExecutionResult(
            plugin: "test", command: "cmd", success: true, exitCode: 0,
            stdout: "", stderr: "", duration: 0.1
        )
        XCTAssertEqual(result.formatted(), "(no output)")
    }

    func testExecutionResultFormattedFailure() {
        let result = PluginManager.ExecutionResult(
            plugin: "test", command: "cmd", success: false, exitCode: 1,
            stdout: "", stderr: "something broke", duration: 0.1
        )
        let formatted = result.formatted()
        XCTAssertTrue(formatted.contains("something broke"))
        XCTAssertTrue(formatted.contains("Exit code: 1"))
    }

    // MARK: - Helpers

    private func createTestPlugin(
        name: String,
        scriptContent: String = "#!/bin/bash\necho 'hello'",
        scriptName: String = "greet.sh"
    ) throws {
        let pluginDir = "\(tempDir.path)/.sysm/plugins/\(name)"
        try FileManager.default.createDirectory(
            atPath: pluginDir,
            withIntermediateDirectories: true,
            attributes: nil
        )

        let manifest = """
        name: \(name)
        version: "1.0.0"
        description: "Test plugin"
        commands:
          - name: greet
            description: "Say hello"
            script: \(scriptName)
        """
        try manifest.write(toFile: "\(pluginDir)/plugin.yaml", atomically: true, encoding: .utf8)

        // Only create script if it doesn't contain path traversal
        if !scriptName.contains("..") {
            try scriptContent.write(toFile: "\(pluginDir)/\(scriptName)", atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o755],
                ofItemAtPath: "\(pluginDir)/\(scriptName)"
            )
        }
    }
}
