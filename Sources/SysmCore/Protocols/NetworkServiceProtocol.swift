import Foundation

public protocol NetworkServiceProtocol: Sendable {
    func getStatus() throws -> NetworkStatus
    func getWiFiInfo() throws -> WiFiInfo?
    func scanWiFi() throws -> [WiFiNetwork]
    func listInterfaces() throws -> [NetworkInterface]
    func getDNS() throws -> [String]
    func ping(host: String, count: Int) throws -> PingResult
}
