import Foundation

struct NotesReadBackValidator: Sendable {
    func validate(
        document: NotesMarkdownDocument,
        plaintext: String,
        body: String
    ) throws {
        for text in Set(document.blocks.map(\.text)) {
            let expectedCount = document.blocks.filter { $0.text == text }.count
            let actualCount = occurrenceCount(of: text, in: plaintext)
            guard actualCount >= expectedCount else {
                throw NotesStructuredFormattingError.verificationFailed("missing content '\(text)'")
            }
        }

        let expectedHeadingCounts: [(pattern: String, count: Int, name: String)] = [
            (#"(?i)<h1(?:\s|>)"#, blockCount(.title, in: document), "Title"),
            (#"(?i)<h2(?:\s|>)"#, blockCount(.heading, in: document), "Heading"),
            (#"(?i)<h3(?:\s|>)"#, blockCount(.subheading, in: document), "Subheading"),
        ]
        for expected in expectedHeadingCounts where expected.count > 0 {
            let actual = matchCount(pattern: expected.pattern, in: body)
            guard actual >= expected.count else {
                throw NotesStructuredFormattingError.verificationFailed(
                    "expected \(expected.count) \(expected.name) blocks, found \(actual)"
                )
            }
        }

        let expectedChecklistItems = document.blocks.reduce(into: 0) { count, block in
            if case .checklistItem = block { count += 1 }
        }
        if expectedChecklistItems > 0 {
            let actualListItems = matchCount(pattern: #"(?i)<li(?:\s|>)"#, in: body)
            guard actualListItems >= expectedChecklistItems else {
                throw NotesStructuredFormattingError.verificationFailed(
                    "expected \(expectedChecklistItems) checklist items, found \(actualListItems)"
                )
            }
        }
    }

    private enum HeadingKind {
        case title
        case heading
        case subheading
    }

    private func blockCount(_ kind: HeadingKind, in document: NotesMarkdownDocument) -> Int {
        document.blocks.filter { block in
            switch (kind, block) {
            case (.title, .title), (.heading, .heading), (.subheading, .subheading):
                return true
            default:
                return false
            }
        }.count
    }

    private func occurrenceCount(of needle: String, in haystack: String) -> Int {
        guard !needle.isEmpty else { return 0 }
        let text = haystack as NSString
        var count = 0
        var location = 0
        while location < text.length {
            let range = text.range(
                of: needle,
                options: [],
                range: NSRange(location: location, length: text.length - location)
            )
            guard range.location != NSNotFound else { break }
            count += 1
            location = NSMaxRange(range)
        }
        return count
    }

    private func matchCount(pattern: String, in value: String) -> Int {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return 0 }
        return regex.numberOfMatches(in: value, range: NSRange(value.startIndex..., in: value))
    }
}
