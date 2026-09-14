import XCTest
@testable import SysmCore

final class TagsServiceTests: XCTestCase {

    private typealias Tag = TagsService.FinderTag

    // MARK: - Color names

    func testColorNamesFollowFinderOrder() {
        // The order NSWorkspace.fileLabels returns; sysm used to call 1 Red and 6 Purple.
        XCTAssertEqual(Tag.colorNames, ["None", "Gray", "Green", "Purple", "Blue", "Yellow", "Red", "Orange"])
        XCTAssertEqual(Tag(name: "Urgent", color: 6).colorName, "Red")
        XCTAssertEqual(Tag(name: "Archive", color: 1).colorName, "Gray")
    }

    func testFormattedShowsTheFinderColor() {
        XCTAssertEqual(Tag(name: "Work", color: 4).formatted(), "Work (Blue)")
        XCTAssertEqual(Tag(name: "Plain", color: 0).formatted(), "Plain")
    }

    func testUnknownColorNumbersReadAsNone() {
        XCTAssertEqual(Tag(name: "Odd", color: 9).colorName, "None")
    }

    // MARK: - colorCode(from:)

    func testColorCodeAcceptsNamesAndNumbers() {
        XCTAssertEqual(Tag.colorCode(from: "red"), 6)
        XCTAssertEqual(Tag.colorCode(from: " Orange "), 7)
        XCTAssertEqual(Tag.colorCode(from: "gray"), 1)
        XCTAssertEqual(Tag.colorCode(from: "grey"), 1)
        XCTAssertEqual(Tag.colorCode(from: "none"), 0)
        XCTAssertEqual(Tag.colorCode(from: "6"), 6)
        XCTAssertEqual(Tag.colorCode(from: "0"), 0)
    }

    func testColorCodeRejectsUnknownInput() {
        XCTAssertNil(Tag.colorCode(from: "pink"))
        XCTAssertNil(Tag.colorCode(from: "8"))
        XCTAssertNil(Tag.colorCode(from: "-1"))
        XCTAssertNil(Tag.colorCode(from: ""))
    }

    // MARK: - Round trip

    func testAddTagWritesTheColorNumberFinderReads() throws {
        let file = FileManager.default.temporaryDirectory
            .appendingPathComponent("sysm-tags-\(UUID().uuidString).txt")
        try Data().write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }

        let service = TagsService()
        try service.addTag(path: file.path, name: "Urgent", color: try XCTUnwrap(Tag.colorCode(from: "red")))

        XCTAssertEqual(try service.getTags(path: file.path), [Tag(name: "Urgent", color: 6)])
    }

    func testTaggingASymlinkLeavesItsTargetAlone() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("sysm-tags-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let target = dir.appendingPathComponent("target.txt")
        let link = dir.appendingPathComponent("link.txt")
        try Data().write(to: target)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)

        let service = TagsService()
        try service.addTag(path: link.path, name: "Linked", color: 4)

        XCTAssertEqual(try service.getTags(path: link.path), [Tag(name: "Linked", color: 4)])
        XCTAssertEqual(try service.getTags(path: target.path), [])
    }
}
