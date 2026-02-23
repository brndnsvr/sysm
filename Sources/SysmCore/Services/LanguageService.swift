import Foundation
import NaturalLanguage

public struct LanguageService: LanguageServiceProtocol {
    public init() {}

    public func detectLanguage(text: String) throws -> [LanguageDetection] {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LanguageError.emptyInput
        }

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        let hypotheses = recognizer.languageHypotheses(withMaximum: 5)
        guard !hypotheses.isEmpty else {
            throw LanguageError.analysisUnavailable
        }

        return hypotheses.map { (lang, confidence) in
            LanguageDetection(
                language: lang.rawValue,
                languageName: languageName(for: lang),
                confidence: confidence
            )
        }.sorted { $0.confidence > $1.confidence }
    }

    public func tokenize(text: String, unit: TokenUnit) throws -> [LanguageToken] {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LanguageError.emptyInput
        }

        let tokenizer = NLTokenizer(unit: nlTokenUnit(unit))
        tokenizer.string = text

        var tokens: [LanguageToken] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let tokenText = String(text[range])
            let start = text.distance(from: text.startIndex, to: range.lowerBound)
            let end = text.distance(from: text.startIndex, to: range.upperBound)
            tokens.append(LanguageToken(text: tokenText, rangeStart: start, rangeEnd: end, unit: unit.rawValue))
            return true
        }

        return tokens
    }

    public func entities(text: String) throws -> [LanguageEntity] {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LanguageError.emptyInput
        }

        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text

        var results: [LanguageEntity] = []
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .joinNames]
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, range in
            if let tag = tag, tag != .otherWord {
                let entityText = String(text[range])
                let start = text.distance(from: text.startIndex, to: range.lowerBound)
                let end = text.distance(from: text.startIndex, to: range.upperBound)
                let typeName: String
                switch tag {
                case .personalName: typeName = "Person"
                case .placeName: typeName = "Place"
                case .organizationName: typeName = "Organization"
                default: typeName = tag.rawValue
                }
                results.append(LanguageEntity(text: entityText, type: typeName, rangeStart: start, rangeEnd: end))
            }
            return true
        }

        return results
    }

    public func tag(text: String) throws -> [LanguageTag] {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LanguageError.emptyInput
        }

        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text

        var results: [LanguageTag] = []
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation]
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, range in
            if let tag = tag {
                let wordText = String(text[range])
                let start = text.distance(from: text.startIndex, to: range.lowerBound)
                let end = text.distance(from: text.startIndex, to: range.upperBound)
                results.append(LanguageTag(text: wordText, tag: tag.rawValue, rangeStart: start, rangeEnd: end))
            }
            return true
        }

        return results
    }

    public func lemmatize(text: String) throws -> [LanguageLemma] {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LanguageError.emptyInput
        }

        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = text

        var results: [LanguageLemma] = []
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation]
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lemma, options: options) { tag, range in
            let wordText = String(text[range])
            let lemma = tag?.rawValue ?? wordText
            let start = text.distance(from: text.startIndex, to: range.lowerBound)
            let end = text.distance(from: text.startIndex, to: range.upperBound)
            results.append(LanguageLemma(text: wordText, lemma: lemma, rangeStart: start, rangeEnd: end))
            return true
        }

        return results
    }

    // MARK: - Private

    private func nlTokenUnit(_ unit: TokenUnit) -> NLTokenUnit {
        switch unit {
        case .word: return .word
        case .sentence: return .sentence
        case .paragraph: return .paragraph
        }
    }

    private func languageName(for language: NLLanguage) -> String {
        let locale = Locale(identifier: "en")
        if let name = locale.localizedString(forLanguageCode: language.rawValue) {
            return name
        }
        return language.rawValue
    }
}

public enum LanguageError: LocalizedError {
    case emptyInput
    case analysisUnavailable
    case fileNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Input text is empty"
        case .analysisUnavailable:
            return "Language analysis unavailable for this text"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        }
    }
}
