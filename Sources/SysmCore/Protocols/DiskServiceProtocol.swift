import Foundation

public protocol DiskServiceProtocol: Sendable {
    func listVolumes() throws -> [VolumeInfo]
    func getVolume(path: String) throws -> VolumeInfo
    func getDirectorySize(path: String) throws -> DirectorySize
    func ejectVolume(name: String) throws
}
