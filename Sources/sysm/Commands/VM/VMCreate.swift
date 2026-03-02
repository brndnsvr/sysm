import ArgumentParser
import Foundation
import SysmCore

struct VMCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new virtual machine"
    )

    @Argument(help: "Name for the VM")
    var name: String

    @Option(name: .long, help: "OS type: linux, macos")
    var os: VMType

    @Option(name: .long, help: "Number of CPU cores")
    var cpus: Int = 2

    @Option(name: .long, help: "Memory in MB")
    var memory: UInt64 = 4096

    @Option(name: .long, help: "Disk size in GB")
    var disk: Int = 64

    @Option(name: .long, help: "Path to IPSW restore image (macOS only)")
    var ipsw: String?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() async throws {
        let service = Services.virtualization()
        let info: VMInfo

        switch os {
        case .linux:
            info = try service.createLinuxVM(name: name, cpus: cpus, memoryMB: memory, diskSizeGB: disk)
        case .macos:
            info = try await service.createMacVM(name: name, cpus: cpus, memoryMB: memory, diskSizeGB: disk, ipswPath: ipsw)
        }

        if json {
            try OutputFormatter.printJSON(info)
        } else {
            print("Created VM '\(info.name)'")
            print("  OS: \(info.os.rawValue)")
            print("  CPUs: \(info.cpus)")
            print("  Memory: \(info.memoryMB)MB")
            print("  Disk: \(info.diskSizeGB)GB")
            print("  Path: \(info.diskPath)")
        }
    }
}
