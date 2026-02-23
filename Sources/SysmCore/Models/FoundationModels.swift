import Foundation

public struct FMResponse: Codable, Sendable {
    public let content: String

    public init(content: String) {
        self.content = content
    }
}

public struct FMSummary: Codable, Sendable {
    public let summary: String
    public let wordCount: Int

    public init(summary: String, wordCount: Int) {
        self.summary = summary
        self.wordCount = wordCount
    }
}

public struct FMActionItem: Codable, Sendable {
    public let action: String
    public let owner: String?
    public let priority: String?

    public init(action: String, owner: String?, priority: String?) {
        self.action = action
        self.owner = owner
        self.priority = priority
    }
}

public struct FMActionItemsResult: Codable, Sendable {
    public let items: [FMActionItem]

    public init(items: [FMActionItem]) {
        self.items = items
    }
}

public struct FMAnalysisResult: Codable, Sendable {
    public let analysis: String

    public init(analysis: String) {
        self.analysis = analysis
    }
}

public enum FMAvailabilityStatus: String, Codable, Sendable {
    case available
    case deviceNotEligible
    case appleIntelligenceNotEnabled
    case modelNotReady
    case frameworkUnavailable
}

public struct FMAvailability: Codable, Sendable {
    public let available: Bool
    public let status: FMAvailabilityStatus
    public let message: String

    public init(available: Bool, status: FMAvailabilityStatus, message: String) {
        self.available = available
        self.status = status
        self.message = message
    }
}
