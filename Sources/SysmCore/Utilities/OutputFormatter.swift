import Foundation

/// Utilities for formatting command output.
///
/// Provides consistent JSON encoding for all command output when the `--json` flag is used.
public enum OutputFormatter {
    /// Formats a byte count as a human-readable file size (KB, MB, GB).
    public static func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    /// Prints an Encodable value as pretty-printed, sorted JSON to stdout.
    /// - Parameter value: The value to encode and print.
    /// - Throws: `OutputError.encodingFailed` if encoding fails.
    public static func printJSON<T: Encodable>(_ value: T) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(value)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw OutputError.encodingFailed
        }
        print(jsonString)
    }

    /// Encodes a value to pretty-printed JSON Data.
    /// - Parameter value: The value to encode.
    /// - Returns: JSON-encoded data.
    public static func encodeJSON<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(value)
    }
}

public enum OutputError: LocalizedError {
    case encodingFailed

    public var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode output as UTF-8"
        }
    }
}
