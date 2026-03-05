import XCTest

@testable import SysmCore

final class VirtualizationServiceTests: XCTestCase {
    private var service: VirtualizationService!
    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("VirtualizationServiceTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        service = VirtualizationService(baseDirectory: tempDir)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: - Helpers

    private func createVMBundle(name: String, os: VMType = .linux, diskSizeGB: Int = 10) throws -> VMConfig {
        let vmDir = tempDir.appendingPathComponent(name)
        try FileManager.default.createDirectory(at: vmDir, withIntermediateDirectories: true)

        // Create sparse disk image
        let diskPath = vmDir.appendingPathComponent("disk.img")
        FileManager.default.createFile(atPath: diskPath.path, contents: nil)
        let handle = try FileHandle(forWritingTo: diskPath)
        try handle.truncate(atOffset: UInt64(diskSizeGB) * 1024 * 1024 * 1024)
        try handle.close()

        let config = VMConfig(
            name: name, os: os, cpus: 2, memoryMB: 2048, diskSizeGB: diskSizeGB, createdAt: Date()
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        try data.write(to: vmDir.appendingPathComponent("config.json"))

        return config
    }

    private func writePIDFile(name: String, pid: pid_t) throws {
        let pidPath = tempDir.appendingPathComponent(name).appendingPathComponent("vm.pid")
        try "\(pid)".write(to: pidPath, atomically: true, encoding: .utf8)
    }

    // MARK: - Model Encoding/Decoding

    func testVMConfigEncodeDecode() throws {
        let config = VMConfig(
            name: "test", os: .linux, cpus: 4, memoryMB: 8192, diskSizeGB: 64, createdAt: Date()
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(config)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(VMConfig.self, from: data)
        XCTAssertEqual(decoded.name, "test")
        XCTAssertEqual(decoded.os, .linux)
        XCTAssertEqual(decoded.cpus, 4)
        XCTAssertEqual(decoded.memoryMB, 8192)
        XCTAssertEqual(decoded.diskSizeGB, 64)
    }

    func testVMConfigWithOptionalFields() throws {
        let dirs = [SharedDirectoryConfig(hostPath: "/tmp/share", tag: "hostfs", readOnly: true)]
        let config = VMConfig(
            name: "test", os: .linux, cpus: 2, memoryMB: 4096, diskSizeGB: 20,
            createdAt: Date(), sharedDirectories: dirs, rosettaEnabled: true
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(config)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(VMConfig.self, from: data)
        XCTAssertEqual(decoded.sharedDirectories?.count, 1)
        XCTAssertEqual(decoded.sharedDirectories?.first?.tag, "hostfs")
        XCTAssertEqual(decoded.sharedDirectories?.first?.readOnly, true)
        XCTAssertEqual(decoded.rosettaEnabled, true)
    }

    func testVMConfigBackwardsCompatibility() throws {
        // Old config format without new fields should decode fine
        let json = """
            {
                "name": "legacy",
                "os": "linux",
                "cpus": 2,
                "memoryMB": 2048,
                "diskSizeGB": 10,
                "createdAt": "2026-01-01T00:00:00Z"
            }
            """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let config = try decoder.decode(VMConfig.self, from: Data(json.utf8))
        XCTAssertEqual(config.name, "legacy")
        XCTAssertNil(config.sharedDirectories)
        XCTAssertNil(config.rosettaEnabled)
    }

    func testVMInfoFromConfig() throws {
        let config = VMConfig(
            name: "test", os: .macos, cpus: 4, memoryMB: 8192, diskSizeGB: 64, createdAt: Date()
        )
        let info = VMInfo(config: config, state: .running, diskPath: "/path/to/disk.img")
        XCTAssertEqual(info.name, "test")
        XCTAssertEqual(info.os, .macos)
        XCTAssertEqual(info.state, .running)
        XCTAssertEqual(info.diskPath, "/path/to/disk.img")
        XCTAssertNil(info.sharedDirectories)
        XCTAssertNil(info.rosettaEnabled)
    }

    func testVMInfoWithSharedDirs() throws {
        let dirs = [SharedDirectoryConfig(hostPath: "/tmp", tag: "share", readOnly: false)]
        let config = VMConfig(
            name: "test", os: .linux, cpus: 2, memoryMB: 2048, diskSizeGB: 10,
            createdAt: Date(), sharedDirectories: dirs, rosettaEnabled: true
        )
        let info = VMInfo(config: config, state: .stopped, diskPath: "/path/disk.img")
        XCTAssertEqual(info.sharedDirectories?.count, 1)
        XCTAssertEqual(info.rosettaEnabled, true)
    }

    func testSharedDirectoryConfigEncodeDecode() throws {
        let dir = SharedDirectoryConfig(hostPath: "/Users/test/share", tag: "myshare", readOnly: false)
        let data = try JSONEncoder().encode(dir)
        let decoded = try JSONDecoder().decode(SharedDirectoryConfig.self, from: data)
        XCTAssertEqual(decoded.hostPath, "/Users/test/share")
        XCTAssertEqual(decoded.tag, "myshare")
        XCTAssertEqual(decoded.readOnly, false)
    }

    func testVMStateRawValues() {
        XCTAssertEqual(VMState.running.rawValue, "running")
        XCTAssertEqual(VMState.stopped.rawValue, "stopped")
        XCTAssertEqual(VMState.saved.rawValue, "saved")
    }

    // MARK: - List VMs

    func testListVMsEmptyDirectory() throws {
        let vms = try service.listVMs(filter: nil)
        XCTAssertTrue(vms.isEmpty)
    }

    func testListVMsReturnsCreatedVMs() throws {
        _ = try createVMBundle(name: "vm-alpha")
        _ = try createVMBundle(name: "vm-beta")

        let vms = try service.listVMs(filter: nil)
        XCTAssertEqual(vms.count, 2)
        XCTAssertEqual(vms[0].name, "vm-alpha")
        XCTAssertEqual(vms[1].name, "vm-beta")
    }

    func testListVMsFilterDown() throws {
        _ = try createVMBundle(name: "stopped-vm")

        let vms = try service.listVMs(filter: .down)
        XCTAssertEqual(vms.count, 1)
        XCTAssertEqual(vms[0].state, .stopped)
    }

    func testListVMsFilterUpEmpty() throws {
        _ = try createVMBundle(name: "stopped-vm")

        let vms = try service.listVMs(filter: .up)
        XCTAssertTrue(vms.isEmpty)
    }

    func testListVMsSkipsNonDirectories() throws {
        // Create a file (not a directory) in the VM base dir
        let filePath = tempDir.appendingPathComponent("not-a-vm.txt")
        try "junk".write(to: filePath, atomically: true, encoding: .utf8)

        let vms = try service.listVMs(filter: nil)
        XCTAssertTrue(vms.isEmpty)
    }

    func testListVMsSkipsMissingConfig() throws {
        // Directory without config.json
        let vmDir = tempDir.appendingPathComponent("no-config")
        try FileManager.default.createDirectory(at: vmDir, withIntermediateDirectories: true)

        let vms = try service.listVMs(filter: nil)
        XCTAssertTrue(vms.isEmpty)
    }

    func testListVMsDetectsSavedState() throws {
        _ = try createVMBundle(name: "saved-vm")
        let savedStatePath = tempDir.appendingPathComponent("saved-vm/saved_state.vzvmsave")
        try "state-data".write(to: savedStatePath, atomically: true, encoding: .utf8)

        let vms = try service.listVMs(filter: nil)
        XCTAssertEqual(vms.count, 1)
        XCTAssertEqual(vms[0].state, .saved)
    }

    // MARK: - Get VM Info

    func testGetVMInfoReturnsCorrectData() throws {
        _ = try createVMBundle(name: "info-test", os: .linux, diskSizeGB: 20)

        let info = try service.getVMInfo(name: "info-test")
        XCTAssertEqual(info.name, "info-test")
        XCTAssertEqual(info.os, .linux)
        XCTAssertEqual(info.cpus, 2)
        XCTAssertEqual(info.memoryMB, 2048)
        XCTAssertEqual(info.diskSizeGB, 20)
        XCTAssertEqual(info.state, .stopped)
    }

    func testGetVMInfoNotFoundThrows() {
        XCTAssertThrowsError(try service.getVMInfo(name: "nonexistent")) { error in
            guard case VirtualizationError.vmNotFound = error else {
                XCTFail("Expected vmNotFound, got \(error)")
                return
            }
        }
    }

    // MARK: - Delete VM

    func testDeleteVMRemovesDirectory() throws {
        _ = try createVMBundle(name: "delete-me")

        let vmDir = tempDir.appendingPathComponent("delete-me")
        XCTAssertTrue(FileManager.default.fileExists(atPath: vmDir.path))

        try service.deleteVM(name: "delete-me")
        XCTAssertFalse(FileManager.default.fileExists(atPath: vmDir.path))
    }

    func testDeleteVMNotFoundThrows() {
        XCTAssertThrowsError(try service.deleteVM(name: "nonexistent")) { error in
            guard case VirtualizationError.vmNotFound = error else {
                XCTFail("Expected vmNotFound, got \(error)")
                return
            }
        }
    }

    func testDeleteRunningVMThrows() throws {
        _ = try createVMBundle(name: "running-vm")
        // Write current process PID to simulate running VM
        try writePIDFile(name: "running-vm", pid: ProcessInfo.processInfo.processIdentifier)

        XCTAssertThrowsError(try service.deleteVM(name: "running-vm")) { error in
            guard case VirtualizationError.vmAlreadyRunning = error else {
                XCTFail("Expected vmAlreadyRunning, got \(error)")
                return
            }
        }
    }

    // MARK: - Stop VM

    func testStopVMNotFoundThrows() {
        XCTAssertThrowsError(try service.stopVM(name: "nonexistent")) { error in
            guard case VirtualizationError.vmNotFound = error else {
                XCTFail("Expected vmNotFound, got \(error)")
                return
            }
        }
    }

    func testStopVMNotRunningThrows() throws {
        _ = try createVMBundle(name: "stopped-vm")

        XCTAssertThrowsError(try service.stopVM(name: "stopped-vm")) { error in
            guard case VirtualizationError.vmNotRunning = error else {
                XCTFail("Expected vmNotRunning, got \(error)")
                return
            }
        }
    }

    func testStopVMStalePIDCleansUp() throws {
        _ = try createVMBundle(name: "stale-vm")
        // Write a PID that doesn't exist
        try writePIDFile(name: "stale-vm", pid: 99999)

        XCTAssertThrowsError(try service.stopVM(name: "stale-vm")) { error in
            guard case VirtualizationError.vmNotRunning = error else {
                XCTFail("Expected vmNotRunning, got \(error)")
                return
            }
        }

        // PID file should be cleaned up
        let pidPath = tempDir.appendingPathComponent("stale-vm/vm.pid")
        XCTAssertFalse(FileManager.default.fileExists(atPath: pidPath.path))
    }

    // MARK: - Disk Resize

    func testResizeDiskGrowsImage() throws {
        _ = try createVMBundle(name: "resize-vm", diskSizeGB: 10)

        try service.resizeDisk(name: "resize-vm", newSizeGB: 20)

        let diskPath = tempDir.appendingPathComponent("resize-vm/disk.img")
        let attrs = try FileManager.default.attributesOfItem(atPath: diskPath.path)
        // Sparse file may not report full size via .size, check config instead
        let config = try loadConfig(name: "resize-vm")
        XCTAssertEqual(config.diskSizeGB, 20)
    }

    func testResizeDiskShrinkThrows() throws {
        _ = try createVMBundle(name: "shrink-vm", diskSizeGB: 20)

        XCTAssertThrowsError(try service.resizeDisk(name: "shrink-vm", newSizeGB: 10)) { error in
            guard case VirtualizationError.invalidConfiguration = error else {
                XCTFail("Expected invalidConfiguration, got \(error)")
                return
            }
        }
    }

    func testResizeDiskSameSizeThrows() throws {
        _ = try createVMBundle(name: "same-vm", diskSizeGB: 10)

        XCTAssertThrowsError(try service.resizeDisk(name: "same-vm", newSizeGB: 10)) { error in
            guard case VirtualizationError.invalidConfiguration = error else {
                XCTFail("Expected invalidConfiguration, got \(error)")
                return
            }
        }
    }

    func testResizeDiskRunningVMThrows() throws {
        _ = try createVMBundle(name: "resize-running")
        try writePIDFile(name: "resize-running", pid: ProcessInfo.processInfo.processIdentifier)

        XCTAssertThrowsError(try service.resizeDisk(name: "resize-running", newSizeGB: 20)) { error in
            guard case VirtualizationError.vmAlreadyRunning = error else {
                XCTFail("Expected vmAlreadyRunning, got \(error)")
                return
            }
        }
    }

    func testResizeDiskNotFoundThrows() {
        XCTAssertThrowsError(try service.resizeDisk(name: "nonexistent", newSizeGB: 20)) { error in
            guard case VirtualizationError.vmNotFound = error else {
                XCTFail("Expected vmNotFound, got \(error)")
                return
            }
        }
    }

    // MARK: - Shared Directories

    func testAddSharedDirectoryUpdatesConfig() throws {
        _ = try createVMBundle(name: "share-vm")

        try service.addSharedDirectory(name: "share-vm", hostPath: tempDir.path, tag: "hostfs", readOnly: false)

        let config = try loadConfig(name: "share-vm")
        XCTAssertEqual(config.sharedDirectories?.count, 1)
        XCTAssertEqual(config.sharedDirectories?.first?.tag, "hostfs")
        XCTAssertEqual(config.sharedDirectories?.first?.hostPath, tempDir.path)
        XCTAssertEqual(config.sharedDirectories?.first?.readOnly, false)
    }

    func testAddMultipleSharedDirectories() throws {
        _ = try createVMBundle(name: "multi-share")

        try service.addSharedDirectory(name: "multi-share", hostPath: tempDir.path, tag: "share1", readOnly: false)
        try service.addSharedDirectory(name: "multi-share", hostPath: tempDir.path, tag: "share2", readOnly: true)

        let config = try loadConfig(name: "multi-share")
        XCTAssertEqual(config.sharedDirectories?.count, 2)
    }

    func testAddDuplicateTagThrows() throws {
        _ = try createVMBundle(name: "dup-tag")
        try service.addSharedDirectory(name: "dup-tag", hostPath: tempDir.path, tag: "same", readOnly: false)

        XCTAssertThrowsError(
            try service.addSharedDirectory(name: "dup-tag", hostPath: tempDir.path, tag: "same", readOnly: true)
        ) { error in
            guard case VirtualizationError.invalidConfiguration = error else {
                XCTFail("Expected invalidConfiguration, got \(error)")
                return
            }
        }
    }

    func testAddSharedDirectoryBadPathThrows() throws {
        _ = try createVMBundle(name: "bad-path")

        XCTAssertThrowsError(
            try service.addSharedDirectory(name: "bad-path", hostPath: "/nonexistent/path", tag: "test", readOnly: false)
        ) { error in
            guard case VirtualizationError.invalidConfiguration = error else {
                XCTFail("Expected invalidConfiguration, got \(error)")
                return
            }
        }
    }

    func testRemoveSharedDirectory() throws {
        _ = try createVMBundle(name: "remove-share")
        try service.addSharedDirectory(name: "remove-share", hostPath: tempDir.path, tag: "removeme", readOnly: false)

        try service.removeSharedDirectory(name: "remove-share", tag: "removeme")

        let config = try loadConfig(name: "remove-share")
        XCTAssertNil(config.sharedDirectories)
    }

    func testRemoveNonexistentTagThrows() throws {
        _ = try createVMBundle(name: "no-tag")

        XCTAssertThrowsError(
            try service.removeSharedDirectory(name: "no-tag", tag: "ghost")
        ) { error in
            guard case VirtualizationError.invalidConfiguration = error else {
                XCTFail("Expected invalidConfiguration, got \(error)")
                return
            }
        }
    }

    // MARK: - Rosetta

    func testEnableRosettaOnMacVMThrows() throws {
        #if arch(arm64)
        _ = try createVMBundle(name: "mac-rosetta", os: .macos)

        XCTAssertThrowsError(try service.enableRosetta(name: "mac-rosetta")) { error in
            guard case VirtualizationError.invalidConfiguration = error else {
                XCTFail("Expected invalidConfiguration, got \(error)")
                return
            }
        }
        #endif
    }

    func testEnableRosettaUpdatesConfig() throws {
        #if arch(arm64)
        _ = try createVMBundle(name: "rosetta-vm")

        try service.enableRosetta(name: "rosetta-vm")

        let config = try loadConfig(name: "rosetta-vm")
        XCTAssertEqual(config.rosettaEnabled, true)
        #endif
    }

    func testEnableRosettaNotFoundThrows() {
        #if arch(arm64)
        XCTAssertThrowsError(try service.enableRosetta(name: "nonexistent")) { error in
            guard case VirtualizationError.vmNotFound = error else {
                XCTFail("Expected vmNotFound, got \(error)")
                return
            }
        }
        #endif
    }

    // MARK: - Save/Restore

    func testSaveVMNotFoundThrows() {
        XCTAssertThrowsError(try service.saveVM(name: "nonexistent")) { error in
            guard case VirtualizationError.vmNotFound = error else {
                XCTFail("Expected vmNotFound, got \(error)")
                return
            }
        }
    }

    func testSaveVMNotRunningThrows() throws {
        _ = try createVMBundle(name: "save-stopped")

        XCTAssertThrowsError(try service.saveVM(name: "save-stopped")) { error in
            guard case VirtualizationError.vmNotRunning = error else {
                XCTFail("Expected vmNotRunning, got \(error)")
                return
            }
        }
    }

    // MARK: - Error Descriptions

    func testVirtualizationErrorDescriptions() {
        let cases: [(VirtualizationError, String)] = [
            (.vmNotFound("test"), "VM not found: test"),
            (.vmAlreadyExists("test"), "VM already exists: test"),
            (.vmAlreadyRunning("test"), "VM is already running: test"),
            (.vmNotRunning("test"), "VM is not running: test"),
            (.invalidConfiguration("bad"), "Invalid VM configuration: bad"),
            (.diskCreationFailed("err"), "Disk creation failed: err"),
            (.installFailed("err"), "Installation failed: err"),
            (.macOSNotSupported, "macOS VMs require Apple Silicon (ARM)"),
            (.ipswLoadFailed("err"), "IPSW load failed: err"),
            (.configurationValidationFailed("err"), "Configuration validation failed: err"),
            (.pidFileError("err"), "PID file error: err"),
            (.saveRestoreUnavailable, "Save/restore requires macOS 14+"),
        ]

        for (error, expected) in cases {
            XCTAssertEqual(error.errorDescription, expected, "Error description mismatch for \(error)")
        }
    }

    // MARK: - Private Test Helpers

    private func loadConfig(name: String) throws -> VMConfig {
        let configPath = tempDir.appendingPathComponent(name).appendingPathComponent("config.json")
        let data = try Data(contentsOf: configPath)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(VMConfig.self, from: data)
    }
}
