//
//  NotesImportSecurityTests.swift
//  sysm
//

import Foundation
import XCTest
@testable import sysm
@testable import SysmCore

final class NotesImportSecurityTests: XCTestCase {
    func testDeleteGateRejectsDuplicateOutputPaths() {
        let results = [
            (note: makeNote(id: "one", name: "A/B"), path: URL(fileURLWithPath: "/tmp/A-B.md")),
            (note: makeNote(id: "two", name: "A:B"), path: URL(fileURLWithPath: "/tmp/A-B.md")),
        ]

        XCTAssertThrowsError(try NotesImport.validateUniqueDeletionResults(results))
    }

    func testDeleteGateRejectsDuplicateSourceIds() {
        let results = [
            (note: makeNote(id: "same", name: "First"), path: URL(fileURLWithPath: "/tmp/first.md")),
            (note: makeNote(id: "same", name: "Second"), path: URL(fileURLWithPath: "/tmp/second.md")),
        ]

        XCTAssertThrowsError(try NotesImport.validateUniqueDeletionResults(results))
    }

    func testDeleteGateAcceptsOneToOneResults() throws {
        let results = [
            (note: makeNote(id: "one", name: "First"), path: URL(fileURLWithPath: "/tmp/first.md")),
            (note: makeNote(id: "two", name: "Second"), path: URL(fileURLWithPath: "/tmp/second.md")),
        ]

        XCTAssertNoThrow(try NotesImport.validateUniqueDeletionResults(results))
    }

    private func makeNote(id: String, name: String) -> Note {
        Note(
            id: id,
            name: name,
            folder: "Notes",
            body: "body",
            creationDate: nil,
            modificationDate: nil
        )
    }
}
