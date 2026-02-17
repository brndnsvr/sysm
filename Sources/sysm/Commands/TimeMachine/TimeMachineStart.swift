import ArgumentParser
import Foundation
import SysmCore

struct TimeMachineStart: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "start",
        abstract: "Start a Time Machine backup"
    )

    func run() throws {
        let service = Services.timeMachine()
        try service.startBackup()
        print("Time Machine backup started")
    }
}
