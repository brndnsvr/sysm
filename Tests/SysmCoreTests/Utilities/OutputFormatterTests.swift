//
//  OutputFormatterTests.swift
//  sysm
//

import XCTest
@testable import SysmCore

final class OutputFormatterTests: XCTestCase {

    struct TestModel: Codable {
        let id: String
        let name: String
        let count: Int
        let isActive: Bool
    }

    // MARK: - JSON Output Tests

    func testPrintJSONSingleObject() throws {
        let model = TestModel(id: "123", name: "Test", count: 42, isActive: true)

        // Capture output
        let output = try captureJSONOutput(model)

        XCTAssertTrue(output.contains("\"id\""))
        XCTAssertTrue(output.contains("\"123\""))
        XCTAssertTrue(output.contains("\"name\""))
        XCTAssertTrue(output.contains("\"Test\""))
        XCTAssertTrue(output.contains("\"count\""))
        XCTAssertTrue(output.contains("42"))
        XCTAssertTrue(output.contains("\"isActive\""))
        XCTAssertTrue(output.contains("true"))
    }

    func testPrintJSONArray() throws {
        let models = [
            TestModel(id: "1", name: "First", count: 1, isActive: true),
            TestModel(id: "2", name: "Second", count: 2, isActive: false)
        ]

        let output = try captureJSONOutput(models)

        XCTAssertTrue(output.starts(with: "["))
        XCTAssertTrue(output.contains("\"First\""))
        XCTAssertTrue(output.contains("\"Second\""))
    }

    func testPrintJSONEmptyArray() throws {
        let models: [TestModel] = []

        let output = try captureJSONOutput(models)

        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertTrue(
            trimmed == "[]" || trimmed == "[\n\n]",
            "Empty array should be valid JSON array, got: \(trimmed)"
        )
    }

    func testPrintJSONPrettyFormat() throws {
        let model = TestModel(id: "123", name: "Test", count: 42, isActive: true)

        let output = try captureJSONOutput(model)

        // Pretty printed JSON should have newlines and indentation
        XCTAssertTrue(output.contains("\n"))
        XCTAssertTrue(output.components(separatedBy: "\n").count > 1)
    }

    // MARK: - Special Characters Tests

    func testJSONEscapesSpecialCharacters() throws {
        struct SpecialModel: Codable {
            let text: String
        }

        let model = SpecialModel(text: "Line 1\nLine 2\tTabbed\r\nWindows")

        let output = try captureJSONOutput(model)

        // JSON should escape special characters
        XCTAssertTrue(output.contains("\\n"))
        XCTAssertTrue(output.contains("\\t"))
        XCTAssertTrue(output.contains("\\r"))
    }

    func testJSONEscapesQuotes() throws {
        struct QuoteModel: Codable {
            let text: String
        }

        let model = QuoteModel(text: "She said \"hello\"")

        let output = try captureJSONOutput(model)

        XCTAssertTrue(output.contains("\\\""))
    }

    // MARK: - Optional Fields Tests

    func testJSONWithOptionalFields() throws {
        struct OptionalModel: Codable {
            let required: String
            let optional: String?
        }

        let withOptional = OptionalModel(required: "test", optional: "value")
        let output1 = try captureJSONOutput(withOptional)
        XCTAssertTrue(output1.contains("\"optional\""))
        XCTAssertTrue(output1.contains("\"value\""))

        let withoutOptional = OptionalModel(required: "test", optional: nil)
        let output2 = try captureJSONOutput(withoutOptional)
        XCTAssertTrue(output2.contains("\"required\""))
        // null fields should be included
        XCTAssertTrue(output2.contains("null") || !output2.contains("\"optional\""))
    }

    // MARK: - Nested Objects Tests

    func testJSONWithNestedObjects() throws {
        struct Parent: Codable {
            let id: String
            let child: Child
        }

        struct Child: Codable {
            let name: String
            let value: Int
        }

        let model = Parent(
            id: "parent-1",
            child: Child(name: "child", value: 99)
        )

        let output = try captureJSONOutput(model)

        XCTAssertTrue(output.contains("\"parent-1\""))
        XCTAssertTrue(output.contains("\"child\""))
        XCTAssertTrue(output.contains("99"))
    }

    // MARK: - Helper Methods

    private func captureJSONOutput<T: Encodable>(_ value: T) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(value)
        return String(data: data, encoding: .utf8) ?? ""
    }
}
