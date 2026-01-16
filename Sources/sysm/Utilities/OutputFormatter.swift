import Foundation

enum OutputFormatter {
    /// Print an Encodable value as pretty-printed JSON
    static func printJSON<T: Encodable>(_ value: T) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(value)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw OutputError.encodingFailed
        }
        print(jsonString)
    }

    /// Encode a value to JSON Data
    static func encodeJSON<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(value)
    }
}

enum OutputError: LocalizedError {
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode output as UTF-8"
        }
    }
}
