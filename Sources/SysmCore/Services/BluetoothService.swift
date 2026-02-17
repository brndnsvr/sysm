import Foundation
import IOBluetooth

public struct BluetoothService: BluetoothServiceProtocol {
    public init() {}

    public func getStatus() throws -> BluetoothStatus {
        // Use system_profiler for reliable Bluetooth status
        let output = try Shell.run("/usr/sbin/system_profiler", args: ["SPBluetoothDataType", "-json"])
        guard let data = output.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let btData = (json["SPBluetoothDataType"] as? [[String: Any]])?.first else {
            throw BluetoothError.unavailable
        }

        let controllerInfo = btData["controller_properties"] as? [String: Any] ?? [:]
        let state = controllerInfo["controller_state"] as? String ?? ""
        let powered = state.lowercased().contains("on") || state.lowercased().contains("attrib_on")
        let discoverable = controllerInfo["controller_discoverable"] as? String == "attrib_on"
        let address = controllerInfo["controller_address"] as? String

        return BluetoothStatus(
            powered: powered,
            discoverable: discoverable,
            address: address
        )
    }

    public func listDevices() throws -> [BluetoothDevice] {
        guard let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
            return []
        }

        return devices.map { device in
            BluetoothDevice(
                name: device.name ?? "(unknown)",
                address: device.addressString ?? "",
                connected: device.isConnected(),
                paired: device.isPaired(),
                deviceType: classOfDeviceName(device.classOfDevice)
            )
        }
    }

    // MARK: - Private

    private func classOfDeviceName(_ cod: BluetoothClassOfDevice) -> String? {
        let major = (cod >> 8) & 0x1F
        switch major {
        case 1: return "Computer"
        case 2: return "Phone"
        case 3: return "Network"
        case 4: return "Audio/Video"
        case 5: return "Peripheral"
        case 6: return "Imaging"
        case 7: return "Wearable"
        case 8: return "Toy"
        default: return nil
        }
    }
}

public enum BluetoothError: LocalizedError {
    case unavailable

    public var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Bluetooth is not available"
        }
    }
}
