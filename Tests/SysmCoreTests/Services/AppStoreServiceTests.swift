import XCTest
@testable import SysmCore

final class AppStoreServiceTests: XCTestCase {
    func testResolveMasPathRejectsRelativeExecutable() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("sysm-mas-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let relativeCandidate = tempDir.appendingPathComponent("mas")
        try "#!/bin/sh\nexit 0\n".write(
            to: relativeCandidate,
            atomically: true,
            encoding: .utf8
        )
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: relativeCandidate.path
        )

        let originalDirectory = FileManager.default.currentDirectoryPath
        XCTAssertTrue(FileManager.default.changeCurrentDirectoryPath(tempDir.path))
        defer { _ = FileManager.default.changeCurrentDirectoryPath(originalDirectory) }

        XCTAssertNil(AppStoreService.resolveMasPath(candidates: ["mas"]))
    }

    func testResolveMasPathAcceptsExecutableAbsolutePath() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("sysm-mas-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let candidate = tempDir.appendingPathComponent("mas")
        try "#!/bin/sh\nexit 0\n".write(
            to: candidate,
            atomically: true,
            encoding: .utf8
        )
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: candidate.path
        )

        XCTAssertEqual(
            AppStoreService.resolveMasPath(candidates: [candidate.path]),
            candidate.path
        )
    }
}
