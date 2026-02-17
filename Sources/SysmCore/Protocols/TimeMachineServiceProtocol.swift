import Foundation

public protocol TimeMachineServiceProtocol: Sendable {
    func getStatus() throws -> TimeMachineStatus
    func listBackups() throws -> [TimeMachineBackup]
    func startBackup() throws
}
