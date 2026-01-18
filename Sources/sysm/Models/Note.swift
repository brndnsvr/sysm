import Foundation

/// Represents a note from macOS Notes retrieved via AppleScript.
///
/// This model includes the note's content and metadata, along with
/// methods for converting to Markdown format for export.
struct Note: Codable {
    // MARK: - Cached Regex Patterns

    private static let styleTagRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "<style[^>]*>.*?</style>", options: [.caseInsensitive, .dotMatchesLineSeparators])
    }()

    private static let htmlTagRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "<[^>]+>", options: [])
    }()

    private static let htmlReplacements: [(regex: NSRegularExpression, replacement: String)] = {
        let patterns: [(String, String)] = [
            ("<br>", "\n"),
            ("<br/>", "\n"),
            ("<br />", "\n"),
            ("</p>", "\n\n"),
            ("<p>", ""),
            ("</div>", "\n"),
            ("<div[^>]*>", ""),
            ("<h1[^>]*>", "# "),
            ("</h1>", "\n"),
            ("<h2[^>]*>", "## "),
            ("</h2>", "\n"),
            ("<h3[^>]*>", "### "),
            ("</h3>", "\n"),
            ("<strong>", "**"),
            ("</strong>", "**"),
            ("<b>", "**"),
            ("</b>", "**"),
            ("<em>", "*"),
            ("</em>", "*"),
            ("<i>", "*"),
            ("</i>", "*"),
            ("<li>", "- "),
            ("</li>", "\n"),
            ("<ul[^>]*>", ""),
            ("</ul>", "\n"),
            ("<ol[^>]*>", ""),
            ("</ol>", "\n"),
        ]
        return patterns.compactMap { pattern, replacement in
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
            return (regex, replacement)
        }
    }()

    // MARK: - Properties

    let id: String
    let name: String
    let folder: String
    let body: String
    let creationDate: Date?
    let modificationDate: Date?

    /// Name sanitized for use as a filename (special characters removed).
    var sanitizedName: String {
        var result = name
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if result.isEmpty {
            result = "Untitled"
        }

        // Limit filename length
        if result.count > 100 {
            result = String(result.prefix(100))
        }

        return result
    }

    /// Converts the note to Markdown format with YAML frontmatter.
    /// - Returns: Markdown string with metadata and converted body content.
    func toMarkdown() -> String {
        var md = "---\n"
        md += "source: apple-notes\n"
        md += "folder: \(folder)\n"

        if let created = creationDate {
            md += "created: \(DateFormatters.iso8601.string(from: created))\n"
        }
        if let modified = modificationDate {
            md += "modified: \(DateFormatters.iso8601.string(from: modified))\n"
        }

        md += "imported: \(DateFormatters.iso8601.string(from: Date()))\n"
        md += "---\n\n"

        // Convert HTML to basic markdown
        md += htmlToMarkdown(body)

        return md
    }

    private func htmlToMarkdown(_ html: String) -> String {
        var text = html

        // Remove style tags and their content
        if let regex = Self.styleTagRegex {
            text = regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "")
        }

        // Convert common HTML to markdown using cached patterns
        for (regex, replacement) in Self.htmlReplacements {
            text = regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: replacement)
        }

        // Remove remaining HTML tags
        if let regex = Self.htmlTagRegex {
            text = regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "")
        }

        // Decode HTML entities
        text = text
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")

        // Clean up multiple newlines
        while text.contains("\n\n\n") {
            text = text.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
