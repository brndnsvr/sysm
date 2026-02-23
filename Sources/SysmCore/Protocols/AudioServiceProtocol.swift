import Foundation

public protocol AudioServiceProtocol: Sendable {
    func getVolume() throws -> AudioVolumeInfo
    func setVolume(_ percent: Int) throws
    func mute() throws
    func unmute() throws
    func listDevices() throws -> [AudioDeviceInfo]
    func getDefaultInput() throws -> AudioDefaultDevice
    func getDefaultOutput() throws -> AudioDefaultDevice
    func setDefaultInput(name: String) throws
    func setDefaultOutput(name: String) throws
}
