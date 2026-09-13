import XCTest
@testable import SysmCore

final class SystemServiceTests: XCTestCase {

    // MARK: - vmStatPageSize(_:)

    func testPageSizeComesFromTheVMStatHeader() {
        let appleSilicon = "Mach Virtual Memory Statistics: (page size of 16384 bytes)\nPages free:  1234."
        XCTAssertEqual(SystemService.vmStatPageSize(appleSilicon), 16384)

        // Intel Macs use 4 KiB pages; the hardcoded 16 KiB made their figures four times too large.
        let intel = "Mach Virtual Memory Statistics: (page size of 4096 bytes)\nPages free:  1234."
        XCTAssertEqual(SystemService.vmStatPageSize(intel), 4096)
    }

    func testMissingHeaderGivesNil() {
        XCTAssertNil(SystemService.vmStatPageSize("Pages free:  1234."))
    }
}
