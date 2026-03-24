import Dispatch
import Foundation
@preconcurrency import Virtualization

public struct VirtualizationService: VirtualizationServiceProtocol {
    private let baseDir: URL?

    public init() { self.baseDir = nil }

    public init(baseDirectory: URL) { self.baseDir = baseDirectory }

    public func vmDirectory() -> URL {
        if let baseDir { return baseDir }
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".sysm/vms")
    }

    // MARK: - List

    public func listVMs(filter: VMStateFilter?) throws -> [VMInfo] {
        let baseDir = vmDirectory()
        let fm = FileManager.default

        guard fm.fileExists(atPath: baseDir.path) else { return [] }

        let contents = try fm.contentsOfDirectory(atPath: baseDir.path)
        var results: [VMInfo] = []

        for name in contents.sorted() {
            let vmDir = baseDir.appendingPathComponent(name)
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: vmDir.path, isDirectory: &isDir), isDir.boolValue else { continue }

            let configPath = vmDir.appendingPathComponent("config.json")
            guard fm.fileExists(atPath: configPath.path) else { continue }

            let data = try Data(contentsOf: configPath)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let config = try decoder.decode(VMConfig.self, from: data)
            let state = vmState(vmDir: vmDir)
            let diskPath = vmDir.appendingPathComponent("disk.img").path
            let info = VMInfo(config: config, state: state, diskPath: diskPath)

            switch filter {
            case .up where state == .running:
                results.append(info)
            case .down where state == .stopped:
                results.append(info)
            case nil:
                results.append(info)
            default:
                break
            }
        }

        return results
    }

    // MARK: - Create Linux VM

    public func createLinuxVM(name: String, cpus: Int, memoryMB: UInt64, diskSizeGB: Int) throws -> VMInfo {
        let baseDir = vmDirectory()
        let vmDir = baseDir.appendingPathComponent(name)
        let fm = FileManager.default

        guard !fm.fileExists(atPath: vmDir.path) else {
            throw VirtualizationError.vmAlreadyExists(name)
        }

        try fm.createDirectory(at: vmDir, withIntermediateDirectories: true)

        // Create sparse disk image
        let diskPath = vmDir.appendingPathComponent("disk.img")
        let sizeBytes = Int64(diskSizeGB) * 1024 * 1024 * 1024
        fm.createFile(atPath: diskPath.path, contents: nil)
        let handle = try FileHandle(forWritingTo: diskPath)
        try handle.truncate(atOffset: UInt64(sizeBytes))
        try handle.close()

        // Create EFI variable store
        let efiPath = vmDir.appendingPathComponent("efi_vars.bin")
        _ = try VZEFIVariableStore(creatingVariableStoreAt: efiPath)

        // Write config
        let config = VMConfig(
            name: name, os: .linux, cpus: cpus,
            memoryMB: memoryMB, diskSizeGB: diskSizeGB,
            createdAt: Date()
        )
        try writeConfig(config, to: vmDir)

        return VMInfo(config: config, state: .stopped, diskPath: diskPath.path)
    }

    // MARK: - Create macOS VM

    public func createMacVM(name: String, cpus: Int, memoryMB: UInt64, diskSizeGB: Int, ipswPath: String?) async throws -> VMInfo {
        #if arch(arm64)
        let baseDir = vmDirectory()
        let vmDir = baseDir.appendingPathComponent(name)
        let fm = FileManager.default

        guard !fm.fileExists(atPath: vmDir.path) else {
            throw VirtualizationError.vmAlreadyExists(name)
        }

        try fm.createDirectory(at: vmDir, withIntermediateDirectories: true)

        // Load restore image
        let restoreImage: VZMacOSRestoreImage
        if let ipswPath = ipswPath {
            let ipswURL = URL(fileURLWithPath: (ipswPath as NSString).expandingTildeInPath)
            guard fm.fileExists(atPath: ipswURL.path) else {
                throw VirtualizationError.ipswLoadFailed("File not found: \(ipswPath)")
            }
            restoreImage = try await VZMacOSRestoreImage.image(from: ipswURL)
        } else {
            restoreImage = try await withCheckedThrowingContinuation { continuation in
                VZMacOSRestoreImage.fetchLatestSupported { result in
                    continuation.resume(with: result)
                }
            }
        }

        guard let requirements = restoreImage.mostFeaturefulSupportedConfiguration else {
            throw VirtualizationError.invalidConfiguration("No supported configuration found in restore image")
        }

        // Create machine identifier
        let machineId = VZMacMachineIdentifier()
        let machineIdPath = vmDir.appendingPathComponent("machine_id.bin")
        try machineId.dataRepresentation.write(to: machineIdPath)

        // Store hardware model
        let hardwareModelPath = vmDir.appendingPathComponent("hardware_model.bin")
        try requirements.hardwareModel.dataRepresentation.write(to: hardwareModelPath)

        // Create auxiliary storage
        let auxPath = vmDir.appendingPathComponent("auxiliary.img")
        _ = try VZMacAuxiliaryStorage(
            creatingStorageAt: auxPath,
            hardwareModel: requirements.hardwareModel,
            options: [.allowOverwrite]
        )

        // Create disk image
        let diskPath = vmDir.appendingPathComponent("disk.img")
        let sizeBytes = Int64(diskSizeGB) * 1024 * 1024 * 1024
        fm.createFile(atPath: diskPath.path, contents: nil)
        let handle = try FileHandle(forWritingTo: diskPath)
        try handle.truncate(atOffset: UInt64(sizeBytes))
        try handle.close()

        // Build configuration for install
        let vmConfig = VZVirtualMachineConfiguration()
        vmConfig.cpuCount = max(cpus, Int(requirements.minimumSupportedCPUCount))
        vmConfig.memorySize = max(memoryMB * 1024 * 1024, requirements.minimumSupportedMemorySize)

        let platform = VZMacPlatformConfiguration()
        platform.machineIdentifier = machineId
        platform.auxiliaryStorage = VZMacAuxiliaryStorage(contentsOf: auxPath)
        platform.hardwareModel = requirements.hardwareModel
        vmConfig.platform = platform

        vmConfig.bootLoader = VZMacOSBootLoader()

        let diskAttachment = try VZDiskImageStorageDeviceAttachment(url: diskPath, readOnly: false)
        vmConfig.storageDevices = [VZVirtioBlockDeviceConfiguration(attachment: diskAttachment)]
        vmConfig.networkDevices = [VZVirtioNetworkDeviceConfiguration()]
        vmConfig.networkDevices[0].attachment = VZNATNetworkDeviceAttachment()
        vmConfig.entropyDevices = [VZVirtioEntropyDeviceConfiguration()]
        vmConfig.memoryBalloonDevices = [VZVirtioTraditionalMemoryBalloonDeviceConfiguration()]

        let graphics = VZMacGraphicsDeviceConfiguration()
        graphics.displays = [VZMacGraphicsDisplayConfiguration(widthInPixels: 1920, heightInPixels: 1200, pixelsPerInch: 80)]
        vmConfig.graphicsDevices = [graphics]

        try vmConfig.validate()

        // Run installer
        let queue = DispatchQueue(label: "com.brndnsvr.sysm.vm.install")
        let vm = VZVirtualMachine(configuration: vmConfig, queue: queue)

        let installer = VZMacOSInstaller(virtualMachine: vm, restoringFromImageAt: restoreImage.url)

        print("Installing macOS (this may take a while)...")

        let progressObserver = installer.progress.observe(\.fractionCompleted, options: [.new]) { progress, _ in
            let pct = Int(progress.fractionCompleted * 100)
            print("\rInstall progress: \(pct)%", terminator: "")
            fflush(stdout)
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            installer.install { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: VirtualizationError.installFailed(error.localizedDescription))
                }
            }
        }

        progressObserver.invalidate()
        print("\nInstallation complete.")

        // Write config
        let config = VMConfig(
            name: name, os: .macos, cpus: vmConfig.cpuCount,
            memoryMB: vmConfig.memorySize / (1024 * 1024), diskSizeGB: diskSizeGB,
            createdAt: Date()
        )
        try writeConfig(config, to: vmDir)

        return VMInfo(config: config, state: .stopped, diskPath: diskPath.path)
        #else
        throw VirtualizationError.macOSNotSupported
        #endif
    }

    // MARK: - Start

    public func startVM(name: String, isoPath: String?) async throws {
        let vmDir = vmDirectory().appendingPathComponent(name)
        let fm = FileManager.default

        guard fm.fileExists(atPath: vmDir.path) else {
            throw VirtualizationError.vmNotFound(name)
        }

        guard !isVMRunning(vmDir: vmDir) else {
            throw VirtualizationError.vmAlreadyRunning(name)
        }

        let config = try loadConfig(from: vmDir)
        let vmConfig = try buildVMConfiguration(config: config, vmDir: vmDir, isoPath: isoPath)
        try vmConfig.validate()

        let queue = DispatchQueue(label: "com.brndnsvr.sysm.vm.\(name)")
        let vm = VZVirtualMachine(configuration: vmConfig, queue: queue)

        // Write PID file
        let pidPath = vmDir.appendingPathComponent("vm.pid")
        try "\(ProcessInfo.processInfo.processIdentifier)".write(to: pidPath, atomically: true, encoding: .utf8)

        // Set up delegate for completion tracking
        let delegate = VMDelegate()
        vm.delegate = delegate

        // Start the VM
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async {
                vm.start { result in
                    continuation.resume(with: result)
                }
            }
        }

        // Restore saved state if present
        if #available(macOS 14.0, *) {
            let statePath = vmDir.appendingPathComponent("saved_state.vzvmsave")
            if FileManager.default.fileExists(atPath: statePath.path) {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    queue.async {
                        vm.restoreMachineStateFrom(url: statePath) { error in
                            if let error {
                                continuation.resume(throwing: error)
                            } else {
                                continuation.resume()
                            }
                        }
                    }
                }
                try? FileManager.default.removeItem(at: statePath)
                print("VM '\(name)' restored from saved state.")
            }
        }

        if config.os == .linux {
            print("VM '\(name)' started (serial console attached). Press Ctrl+C to stop.")
        } else {
            print("VM '\(name)' started (headless). Press Ctrl+C to stop.")
        }

        // Set up SIGINT handler for graceful shutdown
        let semaphore = DispatchSemaphore(value: 0)
        let signalSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        signal(SIGINT, SIG_IGN)
        signalSource.setEventHandler {
            semaphore.signal()
        }
        signalSource.resume()

        // Set up SIGUSR1 handler for save-and-stop (macOS 14+)
        if #available(macOS 14.0, *) {
            let saveSource = DispatchSource.makeSignalSource(signal: SIGUSR1, queue: queue)
            signal(SIGUSR1, SIG_IGN)
            saveSource.setEventHandler { [vmDir] in
                let statePath = vmDir.appendingPathComponent("saved_state.vzvmsave")
                vm.saveMachineStateTo(url: statePath) { error in
                    if let error {
                        print("\nFailed to save state: \(error.localizedDescription)")
                    } else {
                        print("\nVM state saved.")
                    }
                    semaphore.signal()
                }
            }
            saveSource.resume()
        }

        // Wait for either SIGINT or guest stop
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            // Monitor for delegate-reported stop
            delegate.onStop = {
                semaphore.signal()
            }
            delegate.onError = { error in
                semaphore.signal()
            }

            DispatchQueue.global().async {
                semaphore.wait()
                signalSource.cancel()

                // Request graceful stop if VM is still running
                queue.async {
                    if vm.canRequestStop {
                        do {
                            try vm.requestStop()
                            print("\nRequesting graceful shutdown...")
                        } catch {
                            // Force stop if graceful fails
                            vm.stop { _ in }
                        }
                    }
                }

                // Wait for delegate to confirm stop
                let stopSemaphore = DispatchSemaphore(value: 0)
                delegate.onStop = {
                    stopSemaphore.signal()
                }
                delegate.onError = { _ in
                    stopSemaphore.signal()
                }

                // If VM already stopped, don't wait
                if vm.state == .stopped || vm.state == .error {
                    continuation.resume()
                    return
                }

                // Give it 10 seconds to stop gracefully
                let result = stopSemaphore.wait(timeout: .now() + 10)
                if result == .timedOut {
                    queue.async {
                        vm.stop { _ in }
                    }
                    Thread.sleep(forTimeInterval: 1)
                }

                continuation.resume()
            }
        }

        // Clean up PID file
        try? fm.removeItem(at: pidPath)
        print("VM '\(name)' stopped.")
    }

    // MARK: - Stop

    public func stopVM(name: String) throws {
        let vmDir = vmDirectory().appendingPathComponent(name)
        let fm = FileManager.default

        guard fm.fileExists(atPath: vmDir.path) else {
            throw VirtualizationError.vmNotFound(name)
        }

        let pidPath = vmDir.appendingPathComponent("vm.pid")
        guard fm.fileExists(atPath: pidPath.path) else {
            throw VirtualizationError.vmNotRunning(name)
        }

        let pidStr = try String(contentsOf: pidPath, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        guard let pid = pid_t(pidStr) else {
            throw VirtualizationError.pidFileError("Invalid PID in \(pidPath.path)")
        }

        // Check if process is alive
        guard kill(pid, 0) == 0 else {
            // Stale PID file — clean up
            try? fm.removeItem(at: pidPath)
            throw VirtualizationError.vmNotRunning(name)
        }

        // Send SIGINT to the running start process
        kill(pid, SIGINT)
    }

    // MARK: - Info

    public func getVMInfo(name: String) throws -> VMInfo {
        let vmDir = vmDirectory().appendingPathComponent(name)
        let fm = FileManager.default

        guard fm.fileExists(atPath: vmDir.path) else {
            throw VirtualizationError.vmNotFound(name)
        }

        let config = try loadConfig(from: vmDir)
        let state = vmState(vmDir: vmDir)
        let diskPath = vmDir.appendingPathComponent("disk.img").path

        return VMInfo(config: config, state: state, diskPath: diskPath)
    }

    // MARK: - Delete

    public func deleteVM(name: String) throws {
        let vmDir = vmDirectory().appendingPathComponent(name)
        let fm = FileManager.default

        guard fm.fileExists(atPath: vmDir.path) else {
            throw VirtualizationError.vmNotFound(name)
        }

        guard !isVMRunning(vmDir: vmDir) else {
            throw VirtualizationError.vmAlreadyRunning(name)
        }

        try fm.removeItem(at: vmDir)
    }

    // MARK: - Disk Resize

    public func resizeDisk(name: String, newSizeGB: Int) throws {
        let vmDir = vmDirectory().appendingPathComponent(name)
        let fm = FileManager.default

        guard fm.fileExists(atPath: vmDir.path) else {
            throw VirtualizationError.vmNotFound(name)
        }
        guard !isVMRunning(vmDir: vmDir) else {
            throw VirtualizationError.vmAlreadyRunning(name)
        }

        var config = try loadConfig(from: vmDir)
        guard newSizeGB > config.diskSizeGB else {
            throw VirtualizationError.invalidConfiguration(
                "New size (\(newSizeGB)GB) must be larger than current size (\(config.diskSizeGB)GB)")
        }

        let diskPath = vmDir.appendingPathComponent("disk.img")
        let handle = try FileHandle(forWritingTo: diskPath)
        let newSizeBytes = UInt64(newSizeGB) * 1024 * 1024 * 1024
        try handle.truncate(atOffset: newSizeBytes)
        try handle.close()

        config.diskSizeGB = newSizeGB
        try writeConfig(config, to: vmDir)
    }

    // MARK: - Shared Directories

    public func addSharedDirectory(name: String, hostPath: String, tag: String, readOnly: Bool) throws {
        let vmDir = vmDirectory().appendingPathComponent(name)
        let fm = FileManager.default

        guard fm.fileExists(atPath: vmDir.path) else {
            throw VirtualizationError.vmNotFound(name)
        }
        guard !isVMRunning(vmDir: vmDir) else {
            throw VirtualizationError.vmAlreadyRunning(name)
        }
        guard fm.fileExists(atPath: hostPath) else {
            throw VirtualizationError.invalidConfiguration("Host path does not exist: \(hostPath)")
        }

        var config = try loadConfig(from: vmDir)
        var dirs = config.sharedDirectories ?? []
        guard !dirs.contains(where: { $0.tag == tag }) else {
            throw VirtualizationError.invalidConfiguration("Shared directory with tag '\(tag)' already exists")
        }
        dirs.append(SharedDirectoryConfig(hostPath: hostPath, tag: tag, readOnly: readOnly))
        config.sharedDirectories = dirs
        try writeConfig(config, to: vmDir)
    }

    public func removeSharedDirectory(name: String, tag: String) throws {
        let vmDir = vmDirectory().appendingPathComponent(name)
        let fm = FileManager.default

        guard fm.fileExists(atPath: vmDir.path) else {
            throw VirtualizationError.vmNotFound(name)
        }
        guard !isVMRunning(vmDir: vmDir) else {
            throw VirtualizationError.vmAlreadyRunning(name)
        }

        var config = try loadConfig(from: vmDir)
        var dirs = config.sharedDirectories ?? []
        guard dirs.contains(where: { $0.tag == tag }) else {
            throw VirtualizationError.invalidConfiguration("No shared directory with tag '\(tag)'")
        }
        dirs.removeAll(where: { $0.tag == tag })
        config.sharedDirectories = dirs.isEmpty ? nil : dirs
        try writeConfig(config, to: vmDir)
    }

    // MARK: - Rosetta

    public func enableRosetta(name: String) throws {
        #if arch(arm64)
        let vmDir = vmDirectory().appendingPathComponent(name)
        let fm = FileManager.default

        guard fm.fileExists(atPath: vmDir.path) else {
            throw VirtualizationError.vmNotFound(name)
        }
        guard !isVMRunning(vmDir: vmDir) else {
            throw VirtualizationError.vmAlreadyRunning(name)
        }

        var config = try loadConfig(from: vmDir)
        guard config.os == .linux else {
            throw VirtualizationError.invalidConfiguration("Rosetta is only available for Linux VMs")
        }

        config.rosettaEnabled = true
        try writeConfig(config, to: vmDir)
        #else
        throw VirtualizationError.invalidConfiguration("Rosetta requires Apple Silicon")
        #endif
    }

    // MARK: - Save / Restore

    public func saveVM(name: String) throws {
        let vmDir = vmDirectory().appendingPathComponent(name)
        let fm = FileManager.default

        guard fm.fileExists(atPath: vmDir.path) else {
            throw VirtualizationError.vmNotFound(name)
        }

        let pidPath = vmDir.appendingPathComponent("vm.pid")
        guard fm.fileExists(atPath: pidPath.path) else {
            throw VirtualizationError.vmNotRunning(name)
        }

        let pidStr = try String(contentsOf: pidPath, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let pid = pid_t(pidStr), kill(pid, 0) == 0 else {
            try? fm.removeItem(at: pidPath)
            throw VirtualizationError.vmNotRunning(name)
        }

        if #available(macOS 14.0, *) {
            kill(pid, SIGUSR1)
        } else {
            throw VirtualizationError.invalidConfiguration("Save/restore requires macOS 14+")
        }
    }

    public func restoreVM(name: String) async throws {
        let vmDir = vmDirectory().appendingPathComponent(name)

        guard FileManager.default.fileExists(atPath: vmDir.path) else {
            throw VirtualizationError.vmNotFound(name)
        }

        if #available(macOS 14.0, *) {
            let statePath = vmDir.appendingPathComponent("saved_state.vzvmsave")
            guard FileManager.default.fileExists(atPath: statePath.path) else {
                throw VirtualizationError.invalidConfiguration("No saved state found for VM '\(name)'")
            }
            try await startVM(name: name, isoPath: nil)
        } else {
            throw VirtualizationError.invalidConfiguration("Save/restore requires macOS 14+")
        }
    }

    // MARK: - Private Helpers

    private func vmState(vmDir: URL) -> VMState {
        if isVMRunning(vmDir: vmDir) { return .running }
        let savedStatePath = vmDir.appendingPathComponent("saved_state.vzvmsave")
        if FileManager.default.fileExists(atPath: savedStatePath.path) { return .saved }
        return .stopped
    }

    private func isVMRunning(vmDir: URL) -> Bool {
        let pidPath = vmDir.appendingPathComponent("vm.pid")
        guard let pidStr = try? String(contentsOf: pidPath, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
              let pid = pid_t(pidStr) else {
            return false
        }

        if kill(pid, 0) == 0 {
            return true
        }

        // Stale PID file — clean up
        try? FileManager.default.removeItem(at: pidPath)
        return false
    }

    private func loadConfig(from vmDir: URL) throws -> VMConfig {
        let configPath = vmDir.appendingPathComponent("config.json")
        let data = try Data(contentsOf: configPath)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(VMConfig.self, from: data)
    }

    private func writeConfig(_ config: VMConfig, to vmDir: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        try data.write(to: vmDir.appendingPathComponent("config.json"), options: .atomic)
    }

    private func buildVMConfiguration(config: VMConfig, vmDir: URL, isoPath: String?) throws -> VZVirtualMachineConfiguration {
        let vmConfig = VZVirtualMachineConfiguration()
        vmConfig.cpuCount = config.cpus
        vmConfig.memorySize = config.memoryMB * 1024 * 1024

        // Disk
        let diskPath = vmDir.appendingPathComponent("disk.img")
        let diskAttachment = try VZDiskImageStorageDeviceAttachment(url: diskPath, readOnly: false)
        vmConfig.storageDevices = [VZVirtioBlockDeviceConfiguration(attachment: diskAttachment)]

        // Network
        let networkConfig = VZVirtioNetworkDeviceConfiguration()
        networkConfig.attachment = VZNATNetworkDeviceAttachment()
        vmConfig.networkDevices = [networkConfig]

        // Entropy
        vmConfig.entropyDevices = [VZVirtioEntropyDeviceConfiguration()]

        // Memory balloon
        vmConfig.memoryBalloonDevices = [VZVirtioTraditionalMemoryBalloonDeviceConfiguration()]

        switch config.os {
        case .linux:
            try configureLinux(vmConfig: vmConfig, vmDir: vmDir, config: config, isoPath: isoPath)
        case .macos:
            #if arch(arm64)
            try configureMacOS(vmConfig: vmConfig, vmDir: vmDir)
            #else
            throw VirtualizationError.macOSNotSupported
            #endif
        }

        return vmConfig
    }

    private func configureLinux(vmConfig: VZVirtualMachineConfiguration, vmDir: URL, config: VMConfig, isoPath: String?) throws {
        // EFI boot loader
        let efiPath = vmDir.appendingPathComponent("efi_vars.bin")
        let bootLoader = VZEFIBootLoader()
        bootLoader.variableStore = VZEFIVariableStore(url: efiPath)
        vmConfig.bootLoader = bootLoader

        // Generic platform
        vmConfig.platform = VZGenericPlatformConfiguration()

        // Serial console (stdin/stdout)
        let serialPort = VZVirtioConsoleDeviceSerialPortConfiguration()
        let inputAttachment = VZFileHandleSerialPortAttachment(
            fileHandleForReading: FileHandle.standardInput,
            fileHandleForWriting: FileHandle.standardOutput
        )
        serialPort.attachment = inputAttachment
        vmConfig.serialPorts = [serialPort]

        // Shared directories (VirtioFS)
        if let sharedDirs = config.sharedDirectories, !sharedDirs.isEmpty {
            for dirConfig in sharedDirs {
                let sharedDir = VZSharedDirectory(url: URL(fileURLWithPath: dirConfig.hostPath), readOnly: dirConfig.readOnly)
                let share = VZSingleDirectoryShare(directory: sharedDir)
                let fsDevice = VZVirtioFileSystemDeviceConfiguration(tag: dirConfig.tag)
                fsDevice.share = share
                vmConfig.directorySharingDevices.append(fsDevice)
            }
        }

        // Rosetta (arm64 only)
        #if arch(arm64)
        if config.rosettaEnabled == true {
            let rosettaAvailability = VZLinuxRosettaDirectoryShare.availability
            if case .installed = rosettaAvailability {
                let rosettaShare = try VZLinuxRosettaDirectoryShare()
                let rosettaFS = VZVirtioFileSystemDeviceConfiguration(tag: "rosetta")
                rosettaFS.share = rosettaShare
                vmConfig.directorySharingDevices.append(rosettaFS)
            }
        }
        #endif

        // Optional ISO attachment
        if let isoPath = isoPath {
            let isoURL = URL(fileURLWithPath: (isoPath as NSString).expandingTildeInPath)
            guard FileManager.default.fileExists(atPath: isoURL.path) else {
                throw VirtualizationError.invalidConfiguration("ISO not found: \(isoPath)")
            }
            let isoAttachment = try VZDiskImageStorageDeviceAttachment(url: isoURL, readOnly: true)
            let usbConfig = VZUSBMassStorageDeviceConfiguration(attachment: isoAttachment)
            vmConfig.storageDevices.append(usbConfig)
        }
    }

    #if arch(arm64)
    private func configureMacOS(vmConfig: VZVirtualMachineConfiguration, vmDir: URL) throws {
        // Mac platform
        let machineIdPath = vmDir.appendingPathComponent("machine_id.bin")
        let hardwareModelPath = vmDir.appendingPathComponent("hardware_model.bin")
        let auxPath = vmDir.appendingPathComponent("auxiliary.img")

        let machineIdData = try Data(contentsOf: machineIdPath)
        guard let machineId = VZMacMachineIdentifier(dataRepresentation: machineIdData) else {
            throw VirtualizationError.invalidConfiguration("Invalid machine identifier")
        }

        let hardwareModelData = try Data(contentsOf: hardwareModelPath)
        guard let hardwareModel = VZMacHardwareModel(dataRepresentation: hardwareModelData) else {
            throw VirtualizationError.invalidConfiguration("Invalid hardware model")
        }

        let platform = VZMacPlatformConfiguration()
        platform.machineIdentifier = machineId
        platform.hardwareModel = hardwareModel
        platform.auxiliaryStorage = VZMacAuxiliaryStorage(contentsOf: auxPath)
        vmConfig.platform = platform

        vmConfig.bootLoader = VZMacOSBootLoader()

        // Graphics (headless)
        let graphics = VZMacGraphicsDeviceConfiguration()
        graphics.displays = [VZMacGraphicsDisplayConfiguration(widthInPixels: 1920, heightInPixels: 1200, pixelsPerInch: 80)]
        vmConfig.graphicsDevices = [graphics]
    }
    #endif
}

// MARK: - VM Delegate

private final class VMDelegate: NSObject, VZVirtualMachineDelegate, @unchecked Sendable {
    var onStop: (() -> Void)?
    var onError: ((Error) -> Void)?

    func guestDidStop(_ virtualMachine: VZVirtualMachine) {
        onStop?()
    }

    func virtualMachine(_ virtualMachine: VZVirtualMachine, didStopWithError error: Error) {
        onError?(error)
    }
}

// MARK: - Errors

public enum VirtualizationError: LocalizedError {
    case vmNotFound(String)
    case vmAlreadyExists(String)
    case vmAlreadyRunning(String)
    case vmNotRunning(String)
    case invalidConfiguration(String)
    case diskCreationFailed(String)
    case installFailed(String)
    case macOSNotSupported
    case ipswLoadFailed(String)
    case configurationValidationFailed(String)
    case pidFileError(String)
    case saveRestoreUnavailable

    public var errorDescription: String? {
        switch self {
        case .vmNotFound(let name):
            return "VM not found: \(name)"
        case .vmAlreadyExists(let name):
            return "VM already exists: \(name)"
        case .vmAlreadyRunning(let name):
            return "VM is already running: \(name)"
        case .vmNotRunning(let name):
            return "VM is not running: \(name)"
        case .invalidConfiguration(let msg):
            return "Invalid VM configuration: \(msg)"
        case .diskCreationFailed(let msg):
            return "Disk creation failed: \(msg)"
        case .installFailed(let msg):
            return "Installation failed: \(msg)"
        case .macOSNotSupported:
            return "macOS VMs require Apple Silicon (ARM)"
        case .ipswLoadFailed(let msg):
            return "IPSW load failed: \(msg)"
        case .configurationValidationFailed(let msg):
            return "Configuration validation failed: \(msg)"
        case .pidFileError(let msg):
            return "PID file error: \(msg)"
        case .saveRestoreUnavailable:
            return "Save/restore requires macOS 14+"
        }
    }
}
