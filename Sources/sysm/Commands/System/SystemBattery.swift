import ArgumentParser
import Foundation
import SysmCore

struct SystemBattery: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "battery",
        abstract: "Show battery status"
    )

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.system()
        let battery = try service.getBattery()

        if json {
            try OutputFormatter.printJSON(battery)
        } else {
            print("Charge:       \(battery.percentage)%")
            print("Power Source: \(battery.powerSource)")
            print("Charging:     \(battery.isCharging ? "Yes" : "No")")
            if let time = battery.timeRemaining {
                print("Remaining:    \(time)")
            }
            if let cycles = battery.cycleCount {
                print("Cycle Count:  \(cycles)")
            }
            if let condition = battery.condition {
                print("Condition:    \(condition)")
            }
        }
    }
}
