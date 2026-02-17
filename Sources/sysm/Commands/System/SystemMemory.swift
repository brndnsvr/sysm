import ArgumentParser
import Foundation
import SysmCore

struct SystemMemory: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "memory",
        abstract: "Show memory usage"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.system()
        let mem = try service.getMemoryUsage()

        if json {
            try OutputFormatter.printJSON(mem)
        } else {
            let totalGB = String(format: "%.1f", Double(mem.totalMB) / 1024.0)
            let usedGB = String(format: "%.1f", Double(mem.usedMB) / 1024.0)
            let freeGB = String(format: "%.1f", Double(mem.freeMB) / 1024.0)

            print("Total:    \(totalGB) GB")
            print("Used:     \(usedGB) GB (active + wired)")
            print("Free:     \(freeGB) GB")
            print("")
            print("Active:   \(String(format: "%.1f", mem.activeGB)) GB")
            print("Inactive: \(String(format: "%.1f", mem.inactiveGB)) GB")
            print("Wired:    \(String(format: "%.1f", mem.wiredGB)) GB")
        }
    }
}
