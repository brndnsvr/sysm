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


}
