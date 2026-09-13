import XCTest
@testable import SysmCore

final class NetworkServiceTests: XCTestCase {

    // MARK: - dnsServers(fromScutil:)

    func testDNSServersKeepIPv6AddressesWhole() {
        let output = """
        DNS configuration

        resolver #1
          nameserver[0] : 192.168.1.1
          nameserver[1] : fe80::1%en0
          nameserver[2] : 2001:4860:4860::8888
          if_index : 12 (en0)

        resolver #2
          nameserver[0] : 192.168.1.1
        """

        XCTAssertEqual(NetworkService.dnsServers(fromScutil: output),
                       ["192.168.1.1", "fe80::1%en0", "2001:4860:4860::8888"])
    }

    func testDNSServersIgnoreOtherLines() {
        XCTAssertEqual(NetworkService.dnsServers(fromScutil: "resolver #1\n  domain : local\n"), [])
    }

    // MARK: - pingArguments(host:count:)

    func testPingTimeLimitGrowsWithTheCount() {
        // -t limits the whole run; a fixed 5 ended --count 10 after about five packets.
        XCTAssertEqual(NetworkService.pingArguments(host: "example.com", count: 10),
                       ["-c", "10", "-t", "15", "example.com"])
        XCTAssertEqual(NetworkService.pingArguments(host: "example.com", count: 1),
                       ["-c", "1", "-t", "6", "example.com"])
    }
}
