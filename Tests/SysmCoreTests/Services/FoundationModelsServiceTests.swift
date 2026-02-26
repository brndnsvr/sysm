import XCTest
@testable import SysmCore

final class FoundationModelsServiceTests: XCTestCase {

    // MARK: - Model Codable Round-Trips

    func testFMResponseCodable() throws {
        let response = FMResponse(content: "Hello from AI")
        let data = try JSONEncoder().encode(response)
        let decoded = try JSONDecoder().decode(FMResponse.self, from: data)
        XCTAssertEqual(decoded.content, "Hello from AI")
    }

    func testFMSummaryCodable() throws {
        let summary = FMSummary(summary: "This is a summary", wordCount: 4)
        let data = try JSONEncoder().encode(summary)
        let decoded = try JSONDecoder().decode(FMSummary.self, from: data)
        XCTAssertEqual(decoded.summary, "This is a summary")
        XCTAssertEqual(decoded.wordCount, 4)
    }

    func testFMActionItemCodable() throws {
        let item = FMActionItem(action: "Fix the bug", owner: "Alice", priority: "high")
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(FMActionItem.self, from: data)
        XCTAssertEqual(decoded.action, "Fix the bug")
        XCTAssertEqual(decoded.owner, "Alice")
        XCTAssertEqual(decoded.priority, "high")
    }

    func testFMActionItemNilFields() throws {
        let item = FMActionItem(action: "Do something", owner: nil, priority: nil)
        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(FMActionItem.self, from: data)
        XCTAssertEqual(decoded.action, "Do something")
        XCTAssertNil(decoded.owner)
        XCTAssertNil(decoded.priority)
    }

    func testFMActionItemsResultCodable() throws {
        let items = [
            FMActionItem(action: "Task 1", owner: "Bob", priority: "low"),
            FMActionItem(action: "Task 2", owner: nil, priority: "high"),
        ]
        let result = FMActionItemsResult(items: items)
        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(FMActionItemsResult.self, from: data)
        XCTAssertEqual(decoded.items.count, 2)
        XCTAssertEqual(decoded.items[0].action, "Task 1")
        XCTAssertEqual(decoded.items[1].action, "Task 2")
    }

    func testFMAnalysisResultCodable() throws {
        let result = FMAnalysisResult(analysis: "The text is well-structured")
        let data = try JSONEncoder().encode(result)
        let decoded = try JSONDecoder().decode(FMAnalysisResult.self, from: data)
        XCTAssertEqual(decoded.analysis, "The text is well-structured")
    }

    func testFMAvailabilityCodable() throws {
        let availability = FMAvailability(available: true, status: .available, message: "Ready")
        let data = try JSONEncoder().encode(availability)
        let decoded = try JSONDecoder().decode(FMAvailability.self, from: data)
        XCTAssertTrue(decoded.available)
        XCTAssertEqual(decoded.status, .available)
        XCTAssertEqual(decoded.message, "Ready")
    }

    func testFMAvailabilityStatusAllCases() throws {
        let cases: [FMAvailabilityStatus] = [
            .available, .deviceNotEligible, .appleIntelligenceNotEnabled,
            .modelNotReady, .frameworkUnavailable,
        ]
        for status in cases {
            let data = try JSONEncoder().encode(status)
            let decoded = try JSONDecoder().decode(FMAvailabilityStatus.self, from: data)
            XCTAssertEqual(decoded, status)
        }
    }

    // MARK: - FoundationModelsUnavailableService

    func testUnavailableServiceCheckAvailability() {
        let service = FoundationModelsUnavailableService()
        let result = service.checkAvailability()
        XCTAssertFalse(result.available)
        XCTAssertEqual(result.status, .frameworkUnavailable)
    }

    func testUnavailableServicePromptThrows() async {
        let service = FoundationModelsUnavailableService()
        do {
            _ = try await service.prompt(text: "hello", systemPrompt: nil)
            XCTFail("Expected FoundationModelsError.notAvailable")
        } catch let error as FoundationModelsError {
            guard case .notAvailable = error else {
                XCTFail("Expected .notAvailable, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected FoundationModelsError, got \(error)")
        }
    }

    func testUnavailableServiceSummarizeThrows() async {
        let service = FoundationModelsUnavailableService()
        do {
            _ = try await service.summarize(text: "hello", chunkSize: nil)
            XCTFail("Expected FoundationModelsError.notAvailable")
        } catch let error as FoundationModelsError {
            guard case .notAvailable = error else {
                XCTFail("Expected .notAvailable, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected FoundationModelsError, got \(error)")
        }
    }

    func testUnavailableServiceExtractActionsThrows() async {
        let service = FoundationModelsUnavailableService()
        do {
            _ = try await service.extractActionItems(text: "hello", chunkSize: nil)
            XCTFail("Expected FoundationModelsError.notAvailable")
        } catch let error as FoundationModelsError {
            guard case .notAvailable = error else {
                XCTFail("Expected .notAvailable, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected FoundationModelsError, got \(error)")
        }
    }

    func testUnavailableServiceAnalyzeThrows() async {
        let service = FoundationModelsUnavailableService()
        do {
            _ = try await service.analyze(text: "hello", prompt: "analyze")
            XCTFail("Expected FoundationModelsError.notAvailable")
        } catch let error as FoundationModelsError {
            guard case .notAvailable = error else {
                XCTFail("Expected .notAvailable, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected FoundationModelsError, got \(error)")
        }
    }

    // MARK: - FoundationModelsError Descriptions

    func testFoundationModelsErrorDescriptions() {
        let cases: [FoundationModelsError] = [
            .notAvailable("test reason"),
            .generationFailed("test failure"),
            .fileNotFound("/tmp/test.txt"),
        ]
        for error in cases {
            XCTAssertNotNil(error.errorDescription,
                            "FoundationModelsError.\(error) should have errorDescription")
        }
    }

    // MARK: - FMTextProcessing.chunkText

    func testChunkTextSingleChunk() {
        let text = "Short text that fits in one chunk"
        let chunks = FMTextProcessing.chunkText(text, size: 1000)
        XCTAssertEqual(chunks.count, 1)
        XCTAssertEqual(chunks[0], text)
    }

    func testChunkTextMultipleChunks() {
        let para1 = String(repeating: "a", count: 50)
        let para2 = String(repeating: "b", count: 50)
        let para3 = String(repeating: "c", count: 50)
        let text = [para1, para2, para3].joined(separator: "\n\n")
        let chunks = FMTextProcessing.chunkText(text, size: 60)
        XCTAssertEqual(chunks.count, 3)
        XCTAssertEqual(chunks[0], para1)
        XCTAssertEqual(chunks[1], para2)
        XCTAssertEqual(chunks[2], para3)
    }

    func testChunkTextEmptyInput() {
        let chunks = FMTextProcessing.chunkText("", size: 100)
        XCTAssertEqual(chunks.count, 0)
    }

    func testChunkTextNoParagraphBreaks() {
        let text = String(repeating: "x", count: 200)
        let chunks = FMTextProcessing.chunkText(text, size: 100)
        // Single paragraph, can't split further — returns as-is
        XCTAssertEqual(chunks.count, 1)
        XCTAssertEqual(chunks[0], text)
    }

    // MARK: - FMTextProcessing.parseActionItems

    func testParseActionItemsStandard() {
        let text = "ACTION: Fix the login bug | OWNER: Alice | PRIORITY: high"
        let items = FMTextProcessing.parseActionItems(text)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].action, "Fix the login bug")
        XCTAssertEqual(items[0].owner, "Alice")
        XCTAssertEqual(items[0].priority, "high")
    }

    func testParseActionItemsUnassignedOwner() {
        let text = "ACTION: Review PR | OWNER: unassigned | PRIORITY: medium"
        let items = FMTextProcessing.parseActionItems(text)
        XCTAssertEqual(items.count, 1)
        XCTAssertNil(items[0].owner, "Unassigned owner should be nil")
        XCTAssertEqual(items[0].priority, "medium")
    }

    func testParseActionItemsMultipleLines() {
        let text = """
        ACTION: Task one | OWNER: Bob | PRIORITY: high
        Some non-action line
        ACTION: Task two | OWNER: unassigned | PRIORITY: low
        """
        let items = FMTextProcessing.parseActionItems(text)
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].action, "Task one")
        XCTAssertEqual(items[1].action, "Task two")
    }

    func testParseActionItemsEmptyAndNonActionLines() {
        let text = """
        Here is the analysis:
        No action items found.
        """
        let items = FMTextProcessing.parseActionItems(text)
        XCTAssertEqual(items.count, 0)
    }
}
