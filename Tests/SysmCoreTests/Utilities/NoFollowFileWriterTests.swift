//
//  NoFollowFileWriterTests.swift
//  sysm
//

import Darwin
import Foundation
import XCTest
@testable import SysmCore

final class NoFollowFileWriterTests: XCTestCase {
    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("NoFollowFileWriterTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
        tempDir = nil
    }

    func testRejectsLeafSymlinkWithoutChangingTarget() throws {
        let target = tempDir.appendingPathComponent("capture.bin")
        let destination = tempDir.appendingPathComponent("export.jpg")
        try Data("ORIGINAL".utf8).write(to: target)
        try FileManager.default.createSymbolicLink(at: destination, withDestinationURL: target)

        XCTAssertThrowsError(
            try NoFollowFileWriter.write(Data("PRIVATE_PHOTO_BYTES".utf8), to: destination)
        )
        XCTAssertEqual(try Data(contentsOf: target), Data("ORIGINAL".utf8))
        XCTAssertEqual(
            try FileManager.default.destinationOfSymbolicLink(atPath: destination.path),
            target.path
        )
    }

    func testWritesNewFileWithPrivatePermissions() throws {
        let destination = tempDir.appendingPathComponent("export.jpg")
        let expected = Data("PHOTO_BYTES".utf8)

        try NoFollowFileWriter.write(expected, to: destination)

        XCTAssertEqual(try Data(contentsOf: destination), expected)
        let attributes = try FileManager.default.attributesOfItem(atPath: destination.path)
        let permissions = try XCTUnwrap(attributes[.posixPermissions] as? NSNumber)
        XCTAssertEqual(permissions.intValue & 0o777, 0o600)
    }

    func testOverwritesExistingRegularFile() throws {
        let destination = tempDir.appendingPathComponent("export.jpg")
        try Data("OLD_BYTES".utf8).write(to: destination)

        try NoFollowFileWriter.write(Data("NEW_BYTES".utf8), to: destination)

        XCTAssertEqual(try Data(contentsOf: destination), Data("NEW_BYTES".utf8))
    }

    func testRejectsDirectoryDestination() throws {
        let destination = tempDir.appendingPathComponent("export.jpg")
        try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: false)

        XCTAssertThrowsError(
            try NoFollowFileWriter.write(Data("PHOTO_BYTES".utf8), to: destination)
        )
        var isDirectory: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: destination.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
    }

    func testRejectsFIFODestinationWithoutBlocking() throws {
        let destination = tempDir.appendingPathComponent("export.jpg")
        XCTAssertEqual(mkfifo(destination.path, mode_t(0o600)), 0)

        XCTAssertThrowsError(
            try NoFollowFileWriter.write(Data("PHOTO_BYTES".utf8), to: destination)
        )
    }

    func testRejectsLeafSymlinkThroughSymlinkedParent() throws {
        let realParent = tempDir.appendingPathComponent("real-parent")
        let linkedParent = tempDir.appendingPathComponent("linked-parent")
        try FileManager.default.createDirectory(at: realParent, withIntermediateDirectories: false)
        try FileManager.default.createSymbolicLink(at: linkedParent, withDestinationURL: realParent)

        let target = realParent.appendingPathComponent("capture.bin")
        let realDestination = realParent.appendingPathComponent("export.jpg")
        let linkedDestination = linkedParent.appendingPathComponent("export.jpg")
        try Data("ORIGINAL".utf8).write(to: target)
        try FileManager.default.createSymbolicLink(at: realDestination, withDestinationURL: target)

        XCTAssertThrowsError(
            try NoFollowFileWriter.write(Data("PRIVATE_PHOTO_BYTES".utf8), to: linkedDestination)
        )
        XCTAssertEqual(try Data(contentsOf: target), Data("ORIGINAL".utf8))
    }
}
