import CoreWLAN
import Foundation

public struct NetworkService: NetworkServiceProtocol {
    public init() {}

    public func getStatus() throws -> NetworkStatus {
        let ifList = try Shell.run("/sbin/ifconfig", args: ["-l"])
        let allInterfaces = ifList.split(separator: " ").map(String.init)

        var activeInterfaces: [String] = []
        var primaryInterface: String?

        for iface in allInterfaces {
            if let detail = try? Shell.run("/sbin/ifconfig", args: [iface]),
               detail.contains("status: active") {
                activeInterfaces.append(iface)
                if primaryInterface == nil && iface.hasPrefix("en") {
                    primaryInterface = iface
                }
            }
        }

        // Try to get the default route interface
        if let routeOut = try? Shell.run("/sbin/route", args: ["-n", "get", "default"]) {
            for line in routeOut.split(separator: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("interface:") {
                    primaryInterface = trimmed.replacingOccurrences(of: "interface:", with: "").trimmingCharacters(in: .whitespaces)
                }
            }
        }

        let connected = !activeInterfaces.isEmpty

        // Get external IP
        var externalIP: String?
        if let ip = try? Shell.run("/usr/bin/curl", args: ["-s", "--max-time", "3", "ifconfig.me"]) {
            let trimmed = ip.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                externalIP = trimmed
            }
        }

        return NetworkStatus(
            connected: connected,
            interfaces: activeInterfaces,
            primaryInterface: primaryInterface,
            externalIP: externalIP
        )
    }

    public func getWiFiInfo() throws -> WiFiInfo? {
        guard let client = CWWiFiClient.shared().interface() else {
            return nil
        }

        guard let ssid = client.ssid() else {
            return nil
        }

        return WiFiInfo(
            ssid: ssid,
            bssid: client.bssid(),
            channel: client.wlanChannel().map { Int($0.channelNumber) },
            rssi: client.rssiValue(),
            noise: client.noiseMeasurement(),
            security: securityString(client.security())
        )
    }

    public func scanWiFi() throws -> [WiFiNetwork] {
        guard let iface = CWWiFiClient.shared().interface() else {
            throw NetworkError.wifiUnavailable
        }

        let networks: Set<CWNetwork>
        do {
            networks = try iface.scanForNetworks(withSSID: nil)
        } catch {
            throw NetworkError.scanFailed(error.localizedDescription)
        }

        return networks
            .sorted { $0.rssiValue > $1.rssiValue }
            .map { network in
                WiFiNetwork(
                    ssid: network.ssid ?? "(hidden)",
                    bssid: network.bssid,
                    rssi: network.rssiValue,
                    channel: network.wlanChannel.map { Int($0.channelNumber) },
                    security: nil
                )
            }
    }

    public func listInterfaces() throws -> [NetworkInterface] {
        let output = try Shell.run("/usr/sbin/networksetup", args: ["-listallhardwareports"])
        var interfaces: [NetworkInterface] = []
        var currentName: String?
        var currentDevice: String?
        var currentMAC: String?

        for line in output.split(separator: "\n") {
            let trimmed = String(line).trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("Hardware Port:") {
                // Save previous entry if we have both name and device
                if let name = currentName, let device = currentDevice {
                    interfaces.append(buildInterface(name: name, device: device, mac: currentMAC))
                }
                currentName = trimmed.replacingOccurrences(of: "Hardware Port: ", with: "")
                currentDevice = nil
                currentMAC = nil
            } else if trimmed.hasPrefix("Device:") {
                currentDevice = trimmed.replacingOccurrences(of: "Device: ", with: "")
            } else if trimmed.hasPrefix("Ethernet Address:") {
                currentMAC = trimmed.replacingOccurrences(of: "Ethernet Address: ", with: "")
            }
        }

        // Don't forget the last entry
        if let name = currentName, let device = currentDevice {
            interfaces.append(buildInterface(name: name, device: device, mac: currentMAC))
        }

        return interfaces
    }

    public func getDNS() throws -> [String] {
        let output = try Shell.run("/usr/sbin/scutil", args: ["--dns"])
        var servers: [String] = []

        for line in output.split(separator: "\n") {
            let trimmed = String(line).trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("nameserver[") {
                let parts = trimmed.split(separator: ":")
                if parts.count >= 2 {
                    let server = String(parts[1]).trimmingCharacters(in: .whitespaces)
                    if !servers.contains(server) {
                        servers.append(server)
                    }
                }
            }
        }

        return servers
    }

    public func ping(host: String, count: Int) throws -> PingResult {
        let result = try Shell.execute(
            "/sbin/ping",
            args: ["-c", String(count), "-t", "5", host],
            timeout: TimeInterval(count * 6 + 5)
        )

        let output = result.stdout + "\n" + result.stderr

        var transmitted = 0
        var received = 0
        var loss: Double = 100.0
        var minRtt: Double?
        var avgRtt: Double?
        var maxRtt: Double?

        for line in output.split(separator: "\n") {
            let str = String(line)
            if str.contains("packets transmitted") {
                let parts = str.split(separator: ",")
                if let first = parts.first {
                    transmitted = Int(first.split(separator: " ").first ?? "0") ?? 0
                }
                if parts.count > 1 {
                    received = Int(String(parts[1]).trimmingCharacters(in: .whitespaces).split(separator: " ").first ?? "0") ?? 0
                }
                if parts.count > 2 {
                    let lossStr = String(parts[2]).trimmingCharacters(in: .whitespaces)
                    loss = Double(lossStr.replacingOccurrences(of: "% packet loss", with: "")) ?? 100.0
                }
            } else if str.contains("min/avg/max") {
                let parts = str.split(separator: "=")
                if parts.count >= 2 {
                    let values = String(parts[1]).trimmingCharacters(in: .whitespaces).split(separator: "/")
                    if values.count >= 3 {
                        minRtt = Double(values[0])
                        avgRtt = Double(values[1])
                        maxRtt = Double(values[2])
                    }
                }
            }
        }

        return PingResult(
            host: host,
            packetsTransmitted: transmitted,
            packetsReceived: received,
            packetLoss: loss,
            roundTripMin: minRtt,
            roundTripAvg: avgRtt,
            roundTripMax: maxRtt
        )
    }

    // MARK: - Private

    private func buildInterface(name: String, device: String, mac: String?) -> NetworkInterface {
        var ip: String?
        if let output = try? Shell.run("/sbin/ifconfig", args: [device]) {
            for line in output.split(separator: "\n") {
                let trimmed = String(line).trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix("inet ") && !trimmed.contains("127.0.0.1") {
                    ip = trimmed.split(separator: " ").dropFirst().first.map(String.init)
                    break
                }
            }
        }

        let active = (try? Shell.run("/sbin/ifconfig", args: [device]))?.contains("status: active") == true
        let status = active ? "active" : "inactive"

        return NetworkInterface(
            name: "\(name) (\(device))",
            ipAddress: ip,
            macAddress: mac,
            status: status
        )
    }

    private func securityString(_ security: CWSecurity) -> String {
        switch security {
        case .none: return "None"
        case .WEP: return "WEP"
        case .wpaPersonal: return "WPA Personal"
        case .wpaEnterprise: return "WPA Enterprise"
        case .wpa2Personal: return "WPA2 Personal"
        case .wpa2Enterprise: return "WPA2 Enterprise"
        case .wpa3Personal: return "WPA3 Personal"
        case .wpa3Enterprise: return "WPA3 Enterprise"
        case .dynamicWEP: return "Dynamic WEP"
        case .wpaPersonalMixed: return "WPA/WPA2 Personal"
        case .wpa3Transition: return "WPA3 Transition"
        case .personal: return "Personal"
        case .enterprise: return "Enterprise"
        case .wpaEnterpriseMixed: return "WPA Enterprise Mixed"
        case .OWE: return "OWE"
        case .oweTransition: return "OWE Transition"
        case .unknown: return "Unknown"
        @unknown default: return "Unknown"
        }
    }
}

public enum NetworkError: LocalizedError {
    case wifiUnavailable
    case scanFailed(String)
    case pingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .wifiUnavailable:
            return "WiFi interface not available"
        case .scanFailed(let msg):
            return "WiFi scan failed: \(msg)"
        case .pingFailed(let msg):
            return "Ping failed: \(msg)"
        }
    }
}
