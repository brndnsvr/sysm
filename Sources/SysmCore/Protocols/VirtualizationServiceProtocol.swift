import Foundation

public protocol VirtualizationServiceProtocol: Sendable {
    func listVMs(filter: VMStateFilter?) throws -> [VMInfo]
    func createLinuxVM(name: String, cpus: Int, memoryMB: UInt64, diskSizeGB: Int) throws -> VMInfo
    func createMacVM(name: String, cpus: Int, memoryMB: UInt64, diskSizeGB: Int, ipswPath: String?) async throws -> VMInfo
    func startVM(name: String, isoPath: String?) async throws
    func stopVM(name: String) throws
    func getVMInfo(name: String) throws -> VMInfo
    func deleteVM(name: String) throws
    func vmDirectory() -> URL
    func resizeDisk(name: String, newSizeGB: Int) throws
    func addSharedDirectory(name: String, hostPath: String, tag: String, readOnly: Bool) throws
    func removeSharedDirectory(name: String, tag: String) throws
    func enableRosetta(name: String) throws
    func saveVM(name: String) throws
    func restoreVM(name: String) async throws
}
