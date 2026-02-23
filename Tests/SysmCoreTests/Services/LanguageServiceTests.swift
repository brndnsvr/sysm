import XCTest
@testable import SysmCore

final class LanguageServiceTests: XCTestCase {
    private var service: LanguageService!

    override func setUp() {
        super.setUp()
        service = LanguageService()
    }

    func testDetectEnglish() throws {
        let results = try service.detectLanguage(text: "Hello, how are you today?")
        XCTAssertFalse(results.isEmpty)
        XCTAssertEqual(results[0].language, "en")
    }

    func testDetectSpanish() throws {
        let results = try service.detectLanguage(text: "Hola, ¿cómo estás hoy? Me llamo Juan.")
        XCTAssertFalse(results.isEmpty)
        XCTAssertEqual(results[0].language, "es")
    }

    func testTokenizeWords() throws {
        let tokens = try service.tokenize(text: "Hello world", unit: .word)
        XCTAssertEqual(tokens.count, 2)
        XCTAssertEqual(tokens[0].text, "Hello")
        XCTAssertEqual(tokens[1].text, "world")
    }

    func testTokenizeSentences() throws {
        let tokens = try service.tokenize(text: "Hello world. How are you?", unit: .sentence)
        XCTAssertEqual(tokens.count, 2)
    }

    func testTagPOS() throws {
        let tags = try service.tag(text: "The cat sat on the mat")
        XCTAssertFalse(tags.isEmpty)
        // "cat" should be tagged as Noun
        let catTag = tags.first { $0.text == "cat" }
        XCTAssertNotNil(catTag)
        XCTAssertEqual(catTag?.tag, "Noun")
    }

    func testLemmatize() throws {
        let lemmas = try service.lemmatize(text: "running cats")
        XCTAssertFalse(lemmas.isEmpty)
    }

    func testEmptyInputThrows() {
        XCTAssertThrowsError(try service.detectLanguage(text: "")) { error in
            guard case LanguageError.emptyInput = error else {
                XCTFail("Expected emptyInput, got \(error)")
                return
            }
        }
        XCTAssertThrowsError(try service.tokenize(text: "", unit: .word)) { error in
            guard case LanguageError.emptyInput = error else {
                XCTFail("Expected emptyInput, got \(error)")
                return
            }
        }
    }

    func testErrorDescriptions() {
        let errors: [(LanguageError, String)] = [
            (.emptyInput, "Input text is empty"),
            (.analysisUnavailable, "Language analysis unavailable for this text"),
            (.fileNotFound("/test.txt"), "File not found: /test.txt"),
        ]
        for (error, expected) in errors {
            XCTAssertEqual(error.errorDescription, expected)
        }
    }
}
