import Foundation

public protocol LanguageServiceProtocol: Sendable {
    func detectLanguage(text: String) throws -> [LanguageDetection]
    func tokenize(text: String, unit: TokenUnit) throws -> [LanguageToken]
    func entities(text: String) throws -> [LanguageEntity]
    func tag(text: String) throws -> [LanguageTag]
    func lemmatize(text: String) throws -> [LanguageLemma]
}
