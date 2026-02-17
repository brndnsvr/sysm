import ArgumentParser
import Foundation
import SysmCore

struct SystemInfo_: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "info",
        abstract: "Show system information"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.system()
        let info = try service.getSystemInfo()

        if json {
            try OutputFormatter.printJSON(info)
        } else {
            print("Hostname:    \(info.hostname)")
            print("OS:          \(info.osVersion)")
            print("Build:       \(info.osBuild)")
            print("Model:       \(info.model)")
            print("CPU:         \(info.cpu)")
            print("Cores:       \(info.cpuCores)")
            print("Memory:      \(info.memoryGB) GB")
            if let serial = info.serialNumber {
                print("Serial:      \(serial)")
            }
        }
    }
}
