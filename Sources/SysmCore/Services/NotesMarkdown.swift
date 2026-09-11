import Foundation

/// A narrow set of Markdown blocks supported by structured Apple Notes creation.
public enum NotesMarkdownBlock: Equatable, Sendable {
    case title(String)
    case heading(String)
    case subheading(String)
    case paragraph(String)
    case checklistItem(text: String, isChecked: Bool)

    public var text: String {
        switch self {
        case .title(let text), .heading(let text), .subheading(let text), .paragraph(let text):
            return text
        case .checklistItem(let text, _):
            return text
        }
    }
}

/// Parsed structured content for one Apple Note.
public struct NotesMarkdownDocument: Equatable, Sendable {
    public let blocks: [NotesMarkdownBlock]

    public init(blocks: [NotesMarkdownBlock]) {
        self.blocks = blocks
    }
}

/// Errors produced by the intentionally small Notes Markdown dialect.
public enum NotesMarkdownError: LocalizedError, Equatable {
    case emptyDocument
    case emptyBlock(line: Int, marker: String)

    public var errorDescription: String? {
        switch self {
        case .emptyDocument:
            return "Markdown content is empty"
        case .emptyBlock(let line, let marker):
            return "Markdown line \(line) has an empty \(marker)"
        }
    }
}

/// Parses the Markdown subset supported by native Apple Notes formatting.
///
/// Supported mappings are `#` title, `##` heading, `###` subheading,
/// plain paragraphs, and top-level `- [ ]` / `- [x]` checklist items.
public struct NotesMarkdownParser: Sendable {
    public init() {}

    public func parse(_ markdown: String) throws -> NotesMarkdownDocument {
        let normalized = markdown
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let lines = normalized.components(separatedBy: "\n")

        var blocks: [NotesMarkdownBlock] = []
        var paragraphLines: [String] = []

        func flushParagraph() {
            guard !paragraphLines.isEmpty else { return }
            blocks.append(.paragraph(paragraphLines.joined(separator: " ")))
            paragraphLines.removeAll(keepingCapacity: true)
        }

        for (offset, rawLine) in lines.enumerated() {
            let lineNumber = offset + 1
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.isEmpty {
                flushParagraph()
                continue
            }

            if let block = try parseStructuredLine(line, lineNumber: lineNumber) {
                flushParagraph()
                blocks.append(block)
            } else {
                paragraphLines.append(line)
            }
        }

        flushParagraph()

        guard !blocks.isEmpty else {
            throw NotesMarkdownError.emptyDocument
        }
        return NotesMarkdownDocument(blocks: blocks)
    }

    private func parseStructuredLine(_ line: String, lineNumber: Int) throws -> NotesMarkdownBlock? {
        let emptyHeadings = ["#": "title", "##": "heading", "###": "subheading"]
        if let marker = emptyHeadings[line] {
            throw NotesMarkdownError.emptyBlock(line: lineNumber, marker: marker)
        }
        if line == "- [ ]" || line == "- [x]" || line == "- [X]" {
            throw NotesMarkdownError.emptyBlock(line: lineNumber, marker: "checklist item")
        }

        let headingMarkers: [(String, String, (String) -> NotesMarkdownBlock)] = [
            ("### ", "subheading", NotesMarkdownBlock.subheading),
            ("## ", "heading", NotesMarkdownBlock.heading),
            ("# ", "title", NotesMarkdownBlock.title),
        ]

        for (prefix, marker, makeBlock) in headingMarkers where line.hasPrefix(prefix) {
            let text = String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
            guard !text.isEmpty else {
                throw NotesMarkdownError.emptyBlock(line: lineNumber, marker: marker)
            }
            return makeBlock(text)
        }

        let checklistPrefixes: [(String, Bool)] = [
            ("- [ ] ", false),
            ("- [x] ", true),
            ("- [X] ", true),
        ]
        for (prefix, isChecked) in checklistPrefixes where line.hasPrefix(prefix) {
            let text = String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
            guard !text.isEmpty else {
                throw NotesMarkdownError.emptyBlock(line: lineNumber, marker: "checklist item")
            }
            return .checklistItem(text: text, isChecked: isChecked)
        }

        return nil
    }
}

/// Produces plain bootstrap HTML that Notes can safely create before native formatting is applied.
public struct NotesHTMLRenderer: Sendable {
    public init() {}

    public func renderBootstrapHTML(_ document: NotesMarkdownDocument) -> String {
        document.blocks
            .map { "<div>\(escapeHTML($0.text))</div>" }
            .joined(separator: "\n")
    }

    private func escapeHTML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
