import Foundation

public protocol FoundationModelsServiceProtocol: Sendable {
    func checkAvailability() -> FMAvailability
    func prompt(text: String, systemPrompt: String?) async throws -> FMResponse
    func summarize(text: String, chunkSize: Int?) async throws -> FMSummary
    func extractActionItems(text: String, chunkSize: Int?) async throws -> FMActionItemsResult
    func analyze(text: String, prompt: String) async throws -> FMAnalysisResult
}
