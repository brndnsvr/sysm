import Foundation

struct Note: Codable {
    let id: String
    let name: String
    let folder: String
    let body: String
    let creationDate: Date?
    let modificationDate: Date?

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

    func toMarkdown() -> String {
        var md = "---\n"
        md += "source: apple-notes\n"
        md += "folder: \(folder)\n"

        let formatter = ISO8601DateFormatter()
        if let created = creationDate {
            md += "created: \(formatter.string(from: created))\n"
        }
        if let modified = modificationDate {
            md += "modified: \(formatter.string(from: modified))\n"
        }

        md += "imported: \(formatter.string(from: Date()))\n"
        md += "---\n\n"

        // Convert HTML to basic markdown
        md += htmlToMarkdown(body)

        return md
    }

    private func htmlToMarkdown(_ html: String) -> String {
        var text = html

        // Remove style tags and their content
        if let regex = try? NSRegularExpression(pattern: "<style[^>]*>.*?</style>", options: [.caseInsensitive, .dotMatchesLineSeparators]) {
            text = regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "")
        }

        // Convert common HTML to markdown
        let replacements: [(String, String)] = [
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

        for (pattern, replacement) in replacements {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                text = regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: replacement)
            }
        }

        // Remove remaining HTML tags
        if let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: []) {
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
