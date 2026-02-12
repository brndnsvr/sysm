import Foundation

/// Extension to support tag extraction from reminder notes.
extension Reminder {
    /// Extract tags from notes field (hashtag format: #tag1 #tag2)
    public var tags: [String] {
        guard let notes = notes else { return [] }

        // Match hashtags: #word or #word-with-dashes
        let pattern = #"#([a-zA-Z0-9_-]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let nsString = notes as NSString
        let results = regex.matches(in: notes, range: NSRange(location: 0, length: nsString.length))

        return results.compactMap { match in
            guard match.numberOfRanges > 1 else { return nil }
            let tagRange = match.range(at: 1)
            return nsString.substring(with: tagRange).lowercased()
        }
    }

    /// Check if reminder has a specific tag
    public func hasTag(_ tag: String) -> Bool {
        return tags.contains(tag.lowercased())
    }
}

/// Helper for working with tags in reminder notes
public struct TagHelper {
    /// Add tags to notes content (preserves existing content)
    public static func addTags(_ tags: [String], to notes: String?) -> String {
        let existingNotes = notes ?? ""
        let tagString = tags.map { "#\($0.lowercased())" }.joined(separator: " ")

        if existingNotes.isEmpty {
            return tagString
        } else if existingNotes.contains("#") {
            // Tags already exist, append new ones
            return "\(existingNotes) \(tagString)"
        } else {
            // Add tags at the end with separator
            return "\(existingNotes)\n\nTags: \(tagString)"
        }
    }

    /// Remove a specific tag from notes
    public static func removeTag(_ tag: String, from notes: String?) -> String? {
        guard let notes = notes else { return nil }

        let pattern = "#\(tag.lowercased())\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return notes }

        let result = regex.stringByReplacingMatches(
            in: notes,
            range: NSRange(location: 0, length: notes.utf16.count),
            withTemplate: ""
        )

        // Clean up extra whitespace
        return result.replacingOccurrences(of: "  ", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Extract all unique tags from notes
    public static func extractTags(from notes: String?) -> [String] {
        guard let notes = notes else { return [] }

        let pattern = #"#([a-zA-Z0-9_-]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let nsString = notes as NSString
        let results = regex.matches(in: notes, range: NSRange(location: 0, length: nsString.length))

        return results.compactMap { match in
            guard match.numberOfRanges > 1 else { return nil }
            let tagRange = match.range(at: 1)
            return nsString.substring(with: tagRange).lowercased()
        }
    }
}
