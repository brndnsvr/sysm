import XCTest

final class SystemServicesIntegrationTests: IntegrationTestCase {

    // MARK: - System

    func testSystemInfo() throws {
        let output = try runCommand(["system", "info", "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        let obj = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any],
            "Expected JSON object"
        )

        XCTAssertNotNil(obj["hostname"] ?? obj["name"], "Should have hostname or name")
    }

    func testSystemBattery() throws {
        do {
            let output = try runCommand(["system", "battery", "--json"])
            let data = try XCTUnwrap(output.data(using: .utf8))
            _ = try JSONSerialization.jsonObject(with: data)
        } catch IntegrationTestError.commandFailed(_, _, let stderr) {
            if stderr.localizedCaseInsensitiveContains("battery") ||
               stderr.localizedCaseInsensitiveContains("not available") {
                throw XCTSkip("No battery available (likely a desktop Mac)")
            }
            throw IntegrationTestError.commandFailed(command: "system battery", exitCode: 1, stderr: stderr)
        }
    }

    func testSystemUptime() throws {
        let output = try runCommand(["system", "uptime", "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data)

        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertFalse(trimmed.isEmpty, "Uptime should return data")
    }

    func testSystemMemory() throws {
        let output = try runCommand(["system", "memory", "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        let obj = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any],
            "Expected JSON object"
        )

        XCTAssertFalse(obj.isEmpty, "Memory info should have fields")
    }

    // MARK: - Clipboard

    func testClipboardCopyPaste() throws {
        let testString = "sysm-clipboard-test-\(UUID().uuidString.prefix(8))"

        _ = try runCommand(["clipboard", "copy", testString])
        let output = try runCommand(["clipboard", "paste"])

        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(trimmed, testString, "Pasted text should match copied text")
    }

    // MARK: - Network

    func testNetworkStatus() throws {
        let output = try runCommand(["network", "status", "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data)
    }

    func testNetworkInterfaces() throws {
        let output = try runCommand(["network", "interfaces", "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        let arr = try JSONSerialization.jsonObject(with: data)

        XCTAssertTrue(arr is [Any], "Expected JSON array of interfaces")
        if let interfaces = arr as? [Any] {
            XCTAssertFalse(interfaces.isEmpty, "Should have at least one network interface")
        }
    }

    func testNetworkWifi() throws {
        do {
            let output = try runCommand(["network", "wifi", "--json"])
            let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)

            // Command may succeed but output plain text when not connected
            if trimmed.localizedCaseInsensitiveContains("not connected") {
                throw XCTSkip("WiFi not connected")
            }

            let data = try XCTUnwrap(trimmed.data(using: .utf8))
            _ = try JSONSerialization.jsonObject(with: data)
        } catch IntegrationTestError.commandFailed(_, _, let stderr) {
            if stderr.localizedCaseInsensitiveContains("wifi") ||
               stderr.localizedCaseInsensitiveContains("not available") ||
               stderr.localizedCaseInsensitiveContains("not connected") {
                throw XCTSkip("WiFi not available or not connected")
            }
            throw IntegrationTestError.commandFailed(command: "network wifi", exitCode: 1, stderr: stderr)
        }
    }

    // MARK: - Disk

    func testDiskList() throws {
        let output = try runCommand(["disk", "list", "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        let arr = try JSONSerialization.jsonObject(with: data)

        XCTAssertTrue(arr is [Any], "Expected JSON array of disks")
        if let disks = arr as? [Any] {
            XCTAssertFalse(disks.isEmpty, "Should have at least one mounted volume")
        }
    }

    func testDiskUsage() throws {
        let output = try runCommand(["disk", "usage", "/tmp", "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data)
    }

    // MARK: - Bluetooth

    func testBluetoothStatus() throws {
        let output = try runCommand(["bluetooth", "status", "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data)
    }

    func testBluetoothDevices() throws {
        let output = try runCommand(["bluetooth", "devices", "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        let arr = try JSONSerialization.jsonObject(with: data)

        XCTAssertTrue(arr is [Any], "Expected JSON array of devices")
    }

    // MARK: - Spotlight

    func testSpotlightSearch() throws {
        let output = try runCommand([
            "spotlight", "search", "Package.swift",
            "--scope", Self.projectRoot,
            "--json",
        ])
        let data = try XCTUnwrap(output.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data)

        XCTAssertTrue(output.contains("Package.swift"), "Should find Package.swift in project")
    }

    // MARK: - Focus

    func testFocusStatus() throws {
        let output = try runCommand(["focus", "status", "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data)
    }

    func testFocusList() throws {
        let output = try runCommand(["focus", "list", "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        let arr = try JSONSerialization.jsonObject(with: data)

        XCTAssertTrue(arr is [Any], "Expected JSON array of focus modes")
    }

    // MARK: - Shortcuts

    func testShortcutsList() throws {
        let output = try runCommand(["shortcuts", "list", "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        let arr = try JSONSerialization.jsonObject(with: data)

        XCTAssertTrue(arr is [Any], "Expected JSON array of shortcuts")
    }
}
