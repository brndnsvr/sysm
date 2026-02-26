import Foundation

#if canImport(FoundationModels)
import FoundationModels

@available(macOS 26, *)
public struct FoundationModelsService: FoundationModelsServiceProtocol {
    public init() {}

    public func checkAvailability() -> FMAvailability {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            return FMAvailability(available: true, status: .available, message: "Apple Intelligence is available")
        case .unavailable(.deviceNotEligible):
            return FMAvailability(available: false, status: .deviceNotEligible, message: "Device not eligible for Apple Intelligence")
        case .unavailable(.appleIntelligenceNotEnabled):
            return FMAvailability(available: false, status: .appleIntelligenceNotEnabled, message: "Apple Intelligence is not enabled in System Settings")
        case .unavailable(.modelNotReady):
            return FMAvailability(available: false, status: .modelNotReady, message: "Model is downloading or not yet ready")
        default:
            return FMAvailability(available: false, status: .modelNotReady, message: "Model not available")
        }
    }

    public func prompt(text: String, systemPrompt: String?) async throws -> FMResponse {
        try ensureAvailable()
        let session: LanguageModelSession
        if let systemPrompt = systemPrompt {
            session = LanguageModelSession(instructions: systemPrompt)
        } else {
            session = LanguageModelSession()
        }
        let response = try await session.respond(to: text)
        return FMResponse(content: response.content)
    }

    public func summarize(text: String, chunkSize: Int?) async throws -> FMSummary {
        try ensureAvailable()
        let effectiveChunkSize = chunkSize ?? 4000

        if text.count <= effectiveChunkSize {
            return try await summarizeSingle(text: text)
        }

        // Multi-chunk: summarize each chunk, then summarize summaries
        let chunks = FMTextProcessing.chunkText(text, size: effectiveChunkSize)
        var chunkSummaries: [String] = []

        for chunk in chunks {
            let result = try await summarizeSingle(text: chunk)
            chunkSummaries.append(result.summary)
        }

        let combined = chunkSummaries.joined(separator: "\n\n")
        return try await summarizeSingle(text: combined)
    }

    public func extractActionItems(text: String, chunkSize: Int?) async throws -> FMActionItemsResult {
        try ensureAvailable()
        let effectiveChunkSize = chunkSize ?? 4000

        let chunks = text.count <= effectiveChunkSize ? [text] : FMTextProcessing.chunkText(text, size: effectiveChunkSize)
        var allItems: [FMActionItem] = []

        for chunk in chunks {
            let session = LanguageModelSession(instructions: """
                Extract action items from the text. For each action item, output one line in this exact format:
                ACTION: <action description> | OWNER: <owner or "unassigned"> | PRIORITY: <high/medium/low>
                Only output action lines, nothing else.
                """)
            let response = try await session.respond(to: chunk)
            let items = FMTextProcessing.parseActionItems(response.content)
            allItems.append(contentsOf: items)
        }

        return FMActionItemsResult(items: allItems)
    }

    public func analyze(text: String, prompt: String) async throws -> FMAnalysisResult {
        try ensureAvailable()

        let session = LanguageModelSession(instructions: "You are an analytical assistant. Provide clear, structured analysis.")
        let fullPrompt = "\(prompt)\n\nText to analyze:\n\(text)"
        let response = try await session.respond(to: fullPrompt)

        return FMAnalysisResult(analysis: response.content)
    }

    // MARK: - Private

    private func ensureAvailable() throws {
        let availability = checkAvailability()
        guard availability.available else {
            throw FoundationModelsError.notAvailable(availability.message)
        }
    }

    private func summarizeSingle(text: String) async throws -> FMSummary {
        let session = LanguageModelSession(instructions: "Summarize the following text concisely. Preserve key points and important details.")
        let response = try await session.respond(to: text)
        let summary = response.content
        let wordCount = summary.split(separator: " ").count
        return FMSummary(summary: summary, wordCount: wordCount)
    }

}
#endif

// Fallback for systems without FoundationModels
public struct FoundationModelsUnavailableService: FoundationModelsServiceProtocol {
    public init() {}

    public func checkAvailability() -> FMAvailability {
        FMAvailability(available: false, status: .frameworkUnavailable, message: "FoundationModels framework not available on this system (requires macOS 26+)")
    }

    public func prompt(text: String, systemPrompt: String?) async throws -> FMResponse {
        throw FoundationModelsError.notAvailable("FoundationModels framework requires macOS 26+")
    }

    public func summarize(text: String, chunkSize: Int?) async throws -> FMSummary {
        throw FoundationModelsError.notAvailable("FoundationModels framework requires macOS 26+")
    }

    public func extractActionItems(text: String, chunkSize: Int?) async throws -> FMActionItemsResult {
        throw FoundationModelsError.notAvailable("FoundationModels framework requires macOS 26+")
    }

    public func analyze(text: String, prompt: String) async throws -> FMAnalysisResult {
        throw FoundationModelsError.notAvailable("FoundationModels framework requires macOS 26+")
    }
}

// MARK: - Text Processing (testable on all platforms)

enum FMTextProcessing {
    static func chunkText(_ text: String, size: Int) -> [String] {
        var chunks: [String] = []
        let paragraphs = text.components(separatedBy: "\n\n")
        var current = ""

        for paragraph in paragraphs {
            if current.count + paragraph.count + 2 > size && !current.isEmpty {
                chunks.append(current)
                current = ""
            }
            if !current.isEmpty { current += "\n\n" }
            current += paragraph
        }

        if !current.isEmpty {
            chunks.append(current)
        }

        return chunks
    }

    static func parseActionItems(_ text: String) -> [FMActionItem] {
        var items: [FMActionItem] = []
        let lines = text.components(separatedBy: "\n")

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("ACTION:") else { continue }

            let parts = trimmed.components(separatedBy: " | ")
            let action = parts.first?
                .replacingOccurrences(of: "ACTION:", with: "")
                .trimmingCharacters(in: .whitespaces) ?? trimmed

            var owner: String?
            var priority: String?

            for part in parts.dropFirst() {
                let p = part.trimmingCharacters(in: .whitespaces)
                if p.hasPrefix("OWNER:") {
                    let val = p.replacingOccurrences(of: "OWNER:", with: "").trimmingCharacters(in: .whitespaces)
                    if val.lowercased() != "unassigned" { owner = val }
                } else if p.hasPrefix("PRIORITY:") {
                    priority = p.replacingOccurrences(of: "PRIORITY:", with: "").trimmingCharacters(in: .whitespaces).lowercased()
                }
            }

            items.append(FMActionItem(action: action, owner: owner, priority: priority))
        }

        return items
    }
}

public enum FoundationModelsError: LocalizedError {
    case notAvailable(String)
    case generationFailed(String)
    case fileNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .notAvailable(let reason):
            return "Apple Intelligence not available: \(reason)"
        case .generationFailed(let reason):
            return "Generation failed: \(reason)"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        }
    }
}
