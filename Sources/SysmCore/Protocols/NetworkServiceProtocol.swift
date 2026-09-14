import Foundation

public protocol NetworkServiceProtocol: Sendable {
    /// - Parameter includeExternalIP: Also look up the public IP address, which
    ///   sends a request to ifconfig.me.
    func getStatus(includeExternalIP: Bool) throws -> NetworkStatus
    func getWiFiInfo() throws -> WiFiInfo?
    func scanWiFi() throws -> [WiFiNetwork]
    func listInterfaces() throws -> [NetworkInterface]
    func getDNS() throws -> [String]
    func ping(host: String, count: Int) throws -> PingResult
}
