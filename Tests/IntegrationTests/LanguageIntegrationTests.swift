import XCTest

final class LanguageIntegrationTests: IntegrationTestCase {

    // MARK: - Help

    func testLanguageHelp() throws {
        let output = try runCommand(["language", "--help"])

        XCTAssertTrue(output.contains("detect"))
        XCTAssertTrue(output.contains("tokenize"))
        XCTAssertTrue(output.contains("tag"))
        XCTAssertTrue(output.contains("lemma"))
        XCTAssertTrue(output.contains("entities"))
    }

    // MARK: - Detect

    func testLanguageDetect() throws {
        let output = try runCommand(["language", "detect", "This is an English sentence", "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        let obj = try JSONSerialization.jsonObject(with: data)

        // Should contain language code "en"
        let jsonStr = String(data: try JSONSerialization.data(withJSONObject: obj), encoding: .utf8) ?? ""
        XCTAssertTrue(jsonStr.contains("en"), "Should detect English, got: \(output)")
    }

    func testLanguageDetectSpanish() throws {
        let output = try runCommand([
            "language", "detect",
            "Esta es una oración en español",
            "--json",
        ])
        let data = try XCTUnwrap(output.data(using: .utf8))
        let obj = try JSONSerialization.jsonObject(with: data)

        let jsonStr = String(data: try JSONSerialization.data(withJSONObject: obj), encoding: .utf8) ?? ""
        XCTAssertTrue(jsonStr.contains("es"), "Should detect Spanish, got: \(output)")
    }

    // MARK: - Tokenize

    func testLanguageTokenize() throws {
        let output = try runCommand(["language", "tokenize", "Hello world", "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data)

        XCTAssertTrue(output.contains("Hello"), "Tokens should contain 'Hello'")
        XCTAssertTrue(output.contains("world"), "Tokens should contain 'world'")
    }

    func testLanguageTokenizeSentence() throws {
        let output = try runCommand([
            "language", "tokenize",
            "First sentence. Second sentence.",
            "--unit", "sentence",
            "--json",
        ])
        let data = try XCTUnwrap(output.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data)

        XCTAssertTrue(output.contains("First"), "Should contain first sentence")
        XCTAssertTrue(output.contains("Second"), "Should contain second sentence")
    }

    // MARK: - Tag

    func testLanguageTag() throws {
        let output = try runCommand(["language", "tag", "The quick brown fox jumps", "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data)

        // Should have POS tags in output
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertFalse(trimmed.isEmpty, "Should have POS tag results")
    }

    // MARK: - Lemma

    func testLanguageLemma() throws {
        let output = try runCommand(["language", "lemma", "running cats jumped", "--json"])
        let data = try XCTUnwrap(output.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data)

        // Lemmatization should produce base forms
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertFalse(trimmed.isEmpty, "Should have lemma results")
    }

    // MARK: - Entities

    func testLanguageEntities() throws {
        let output = try runCommand([
            "language", "entities",
            "Tim Cook works at Apple in Cupertino",
            "--json",
        ])
        let data = try XCTUnwrap(output.data(using: .utf8))
        _ = try JSONSerialization.jsonObject(with: data)

        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertFalse(trimmed.isEmpty, "Should have entity results")
    }
}
