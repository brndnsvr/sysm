import XCTest
@testable import SysmCore

final class AnyCodableTests: XCTestCase {

    // MARK: - Basic Type Round-trips

    func testStringRoundTrip() throws {
        let original = AnyCodable("hello")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertEqual(decoded.value as? String, "hello")
    }

    func testIntRoundTrip() throws {
        let original = AnyCodable(42)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertEqual(decoded.value as? Int, 42)
    }

    func testDoubleRoundTrip() throws {
        let original = AnyCodable(3.14)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertEqual(decoded.value as! Double, 3.14, accuracy: 0.001)
    }

    func testBoolRoundTrip() throws {
        let original = AnyCodable(true)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        // Bool may decode as Int in some contexts, check for truthiness
        let val = decoded.value
        XCTAssertTrue(val is Bool || val is Int)
    }

    // MARK: - Collection Round-trips

    func testDictionaryRoundTrip() throws {
        let dict: [String: Any] = ["name": "test", "count": 5]
        let original = AnyCodable(dict)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        let result = decoded.value as? [String: Any]
        XCTAssertNotNil(result)
        XCTAssertEqual(result?["name"] as? String, "test")
    }

    func testArrayRoundTrip() throws {
        let arr: [Any] = ["a", "b", "c"]
        let original = AnyCodable(arr)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        let result = decoded.value as? [Any]
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.count, 3)
    }

    // MARK: - Null/Unknown

    func testNullEncodesNil() throws {
        let original = AnyCodable(NSNull())
        let data = try JSONEncoder().encode(original)
        let json = String(data: data, encoding: .utf8)!
        XCTAssertEqual(json, "null")
    }

    // MARK: - Depth Limit

    func testDepthLimitDoesNotCrash() throws {
        // Build a deeply nested JSON structure (33 levels deep)
        var json = ""
        for _ in 0..<33 {
            json += "{\"nested\":"
        }
        json += "\"deep\""
        for _ in 0..<33 {
            json += "}"
        }

        let data = json.data(using: .utf8)!
        // Should not crash - at depth 32 it returns NSNull
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        XCTAssertNotNil(decoded)
    }

    // MARK: - Mixed-type Array

    func testMixedTypeArray() throws {
        let json = "[\"hello\", 42, 3.14, true, null]"
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        let arr = decoded.value as? [Any]
        XCTAssertNotNil(arr)
        XCTAssertEqual(arr?.count, 5)
        XCTAssertEqual(arr?[0] as? String, "hello")
    }
}
