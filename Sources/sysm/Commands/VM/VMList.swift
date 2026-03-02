import ArgumentParser
import Foundation
import SysmCore

struct VMList: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ls",
        abstract: "List virtual machines"
    )

    @Argument(help: "Filter: up (running), down (stopped)")
    var filter: VMStateFilter?

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.virtualization()
        let vms = try service.listVMs(filter: filter)

        if json {
            try OutputFormatter.printJSON(vms)
        } else {
            if vms.isEmpty {
                let label: String
                switch filter {
                case .up: label = "running "
                case .down: label = "stopped "
                case nil: label = ""
                }
                print("No \(label)VMs found")
            } else {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .short

                print("VMs (\(vms.count)):\n")
                for vm in vms {
                    let state = vm.state == .running ? "[running]" : "[stopped]"
                    print("  \(vm.name) \(state)")
                    print("    OS: \(vm.os.rawValue), CPUs: \(vm.cpus), Memory: \(vm.memoryMB)MB, Disk: \(vm.diskSizeGB)GB")
                    print("    Created: \(formatter.string(from: vm.createdAt))")
                    print()
                }
            }
        }
    }
}
