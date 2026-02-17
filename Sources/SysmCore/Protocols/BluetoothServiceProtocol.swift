import Foundation

public protocol BluetoothServiceProtocol: Sendable {
    func getStatus() throws -> BluetoothStatus
    func listDevices() throws -> [BluetoothDevice]
}
