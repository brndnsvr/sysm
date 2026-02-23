import Foundation

public struct LanguageDetection: Codable, Sendable {
    public let language: String
    public let languageName: String
    public let confidence: Double

    public init(language: String, languageName: String, confidence: Double) {
        self.language = language
        self.languageName = languageName
        self.confidence = confidence
    }
}

public struct LanguageToken: Codable, Sendable {
    public let text: String
    public let rangeStart: Int
    public let rangeEnd: Int
    public let unit: String

    public init(text: String, rangeStart: Int, rangeEnd: Int, unit: String) {
        self.text = text
        self.rangeStart = rangeStart
        self.rangeEnd = rangeEnd
        self.unit = unit
    }
}

public struct LanguageEntity: Codable, Sendable {
    public let text: String
    public let type: String
    public let rangeStart: Int
    public let rangeEnd: Int

    public init(text: String, type: String, rangeStart: Int, rangeEnd: Int) {
        self.text = text
        self.type = type
        self.rangeStart = rangeStart
        self.rangeEnd = rangeEnd
    }
}

public struct LanguageTag: Codable, Sendable {
    public let text: String
    public let tag: String
    public let rangeStart: Int
    public let rangeEnd: Int

    public init(text: String, tag: String, rangeStart: Int, rangeEnd: Int) {
        self.text = text
        self.tag = tag
        self.rangeStart = rangeStart
        self.rangeEnd = rangeEnd
    }
}

public struct LanguageLemma: Codable, Sendable {
    public let text: String
    public let lemma: String
    public let rangeStart: Int
    public let rangeEnd: Int

    public init(text: String, lemma: String, rangeStart: Int, rangeEnd: Int) {
        self.text = text
        self.lemma = lemma
        self.rangeStart = rangeStart
        self.rangeEnd = rangeEnd
    }
}

public enum TokenUnit: String, Codable, Sendable, CaseIterable {
    case word
    case sentence
    case paragraph
}
