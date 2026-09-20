import ApplicationServices
import AppKit
import Foundation

struct NotesAccessibilityUI {
    private static let waitIterations = 100
    private static let waitInterval: TimeInterval = 0.05
    private static let autoSortPromptMarker = "automatic sorting of checked items"
    private static let autoSortDeclineButton = "Not Now"

    private let application: AXUIElement
    private let beforeAction: () throws -> Void

    init(application: AXUIElement, beforeAction: @escaping () throws -> Void) {
        self.application = application
        self.beforeAction = beforeAction
    }

    func apply(document: NotesMarkdownDocument) throws {
        try resolveBlockingSheet()
        let match = try waitForEditor(document: document)
        let styleActions = makeStyleActions(document: document, ranges: match.ranges)
        for action in styleActions {
            try applyFormat(action.command, to: action.range, editor: match.element)
        }

        // Notes can automatically move checked items to the bottom. Processing checked items from
        // the bottom up keeps every unprocessed range stable even when that preference is enabled.
        let checkedRanges = zip(document.blocks, match.ranges)
            .compactMap { block, range -> NSRange? in
                guard case .checklistItem(_, let isChecked) = block, isChecked else { return nil }
                return range
            }
            .sorted { $0.location > $1.location }

        for range in checkedRanges {
            try applyFormat(.toggleChecklistItem, to: range, editor: match.element)
        }
    }

    private struct EditorMatch {
        let element: AXUIElement
        let ranges: [NSRange]
    }

    private func waitForEditor(document: NotesMarkdownDocument) throws -> EditorMatch {
        for _ in 0..<Self.waitIterations {
            if let window = NotesAccessibilityBridge.elementAttribute(
                application,
                kAXFocusedWindowAttribute as CFString
            ) {
                var textAreas: [AXUIElement] = []
                NotesAccessibilityBridge.collectElements(
                    in: window,
                    role: kAXTextAreaRole as String,
                    remainingDepth: 24,
                    results: &textAreas
                )

                let matches = textAreas.compactMap { element -> EditorMatch? in
                    guard NotesAccessibilityBridge.isSettable(
                        element,
                        attribute: kAXSelectedTextRangeAttribute as CFString
                    ),
                        let value = NotesAccessibilityBridge.stringAttribute(
                            element,
                            kAXValueAttribute as CFString
                        ),
                        let ranges = ranges(for: document.blocks, in: value) else {
                        return nil
                    }
                    return EditorMatch(element: element, ranges: ranges)
                }

                if matches.count == 1 {
                    return matches[0]
                }
                if matches.count > 1 {
                    throw NotesStructuredFormattingError.ambiguousEditor
                }
            }
            Thread.sleep(forTimeInterval: Self.waitInterval)
        }
        throw NotesStructuredFormattingError.editorNotFound
    }

    private func ranges(for blocks: [NotesMarkdownBlock], in value: String) -> [NSRange]? {
        let text = value as NSString
        var searchLocation = 0
        var result: [NSRange] = []

        for block in blocks {
            let remaining = NSRange(location: searchLocation, length: text.length - searchLocation)
            let match = text.range(of: block.text, options: [], range: remaining)
            guard match.location != NSNotFound else { return nil }
            result.append(match)
            searchLocation = NSMaxRange(match)
        }
        return result
    }

    private struct StyleAction {
        let command: FormatCommand
        let range: NSRange
    }

    private func makeStyleActions(
        document: NotesMarkdownDocument,
        ranges: [NSRange]
    ) -> [StyleAction] {
        var actions: [StyleAction] = []
        var index = 0

        while index < document.blocks.count {
            switch document.blocks[index] {
            case .title:
                actions.append(StyleAction(command: .title, range: ranges[index]))
            case .heading:
                actions.append(StyleAction(command: .heading, range: ranges[index]))
            case .subheading:
                actions.append(StyleAction(command: .subheading, range: ranges[index]))
            case .paragraph:
                actions.append(StyleAction(command: .body, range: ranges[index]))
            case .checklistItem:
                let first = ranges[index]
                var last = first
                var next = index + 1
                while next < document.blocks.count {
                    guard case .checklistItem = document.blocks[next] else { break }
                    last = ranges[next]
                    next += 1
                }
                actions.append(
                    StyleAction(
                        command: .checklist,
                        range: NSRange(location: first.location, length: NSMaxRange(last) - first.location)
                    )
                )
                index = next - 1
            }
            index += 1
        }
        return actions
    }

    private enum FormatCommand: String {
        case title = "Title"
        case heading = "Heading"
        case subheading = "Subheading"
        case body = "Body"
        case checklist = "Checklist"
        case toggleChecklistItem = "Mark or unmark checklist item"

        var commandCharacter: String {
            switch self {
            case .title: return "T"
            case .heading: return "H"
            case .subheading: return "J"
            case .body: return "B"
            case .checklist: return "L"
            case .toggleChecklistItem: return "U"
            }
        }
    }

    private func applyFormat(
        _ command: FormatCommand,
        to range: NSRange,
        editor: AXUIElement
    ) throws {
        // The sheet has to be cleared first: while it is up, Notes reports an empty selection
        // to AppleScript, so the target check below would fail before we ever saw the dialog.
        try resolveBlockingSheet()
        try beforeAction()
        try verifyFocus(editor: editor)
        try NotesAccessibilityBridge.select(range: range, in: editor)

        let menuItem = try waitForEnabledMenuItem(command, range: range, editor: editor)

        guard AXUIElementPerformAction(menuItem, kAXPressAction as CFString) == .success else {
            throw NotesStructuredFormattingError.formatCommandFailed(command.rawValue)
        }
    }

    /// Notes validates its Format menu on its own main loop, so a command can report disabled
    /// for a short time after the selection or a paragraph style changes. Marking a checklist
    /// item immediately after converting the block is the case that trips this: the item is
    /// found and the selection is correct, but Notes has not revalidated the menu yet.
    ///
    /// Poll within the same bounded budget the editor lookup uses, re-asserting the selection
    /// so Notes revalidates, rather than failing on the first read. A command that is genuinely
    /// unavailable for the account or keyboard layout still fails, just at the end of the wait.
    private func waitForEnabledMenuItem(
        _ command: FormatCommand,
        range: NSRange,
        editor: AXUIElement
    ) throws -> AXUIElement {
        for attempt in 0..<Self.waitIterations {
            if attempt > 0 {
                try NotesAccessibilityBridge.select(range: range, in: editor)
            }

            if let menuItem = findMenuItem(
                commandCharacter: command.commandCharacter,
                modifiers: .shift
            ),
               NotesAccessibilityBridge.boolAttribute(
                   menuItem,
                   kAXEnabledAttribute as CFString
               ) != false {
                return menuItem
            }

            Thread.sleep(forTimeInterval: Self.waitInterval)
        }

        throw NotesStructuredFormattingError.formatCommandUnavailable(command.rawValue)
    }


    /// Notes asks "Would you like to enable automatic sorting of checked items?" the first time
    /// anything marks a checklist item as checked. The alert is a sheet, so it takes focus and
    /// every later format action fails until it is answered.
    ///
    /// Answer it with "Not Now", which declines the change and leaves the user's Notes settings
    /// exactly as they were. Any other sheet is something this command did not cause and cannot
    /// safely answer, so it fails closed and reports what Notes is asking.
    private func resolveBlockingSheet() throws {
        guard let window = NotesAccessibilityBridge.elementAttribute(
            application,
            kAXFocusedWindowAttribute as CFString
        ) else {
            return
        }

        var sheets: [AXUIElement] = []
        NotesAccessibilityBridge.collectElements(
            in: window,
            role: kAXSheetRole as String,
            remainingDepth: 4,
            results: &sheets
        )
        guard let sheet = sheets.first else { return }

        var labels: [AXUIElement] = []
        NotesAccessibilityBridge.collectElements(
            in: sheet,
            role: kAXStaticTextRole as String,
            remainingDepth: 6,
            results: &labels
        )
        let prompt = labels
            .compactMap { NotesAccessibilityBridge.stringAttribute($0, kAXValueAttribute as CFString) }
            .joined(separator: " ")

        guard prompt.contains(Self.autoSortPromptMarker) else {
            throw NotesStructuredFormattingError.blockedByDialog(
                prompt.isEmpty ? "unrecognized Notes dialog" : prompt
            )
        }

        var buttons: [AXUIElement] = []
        NotesAccessibilityBridge.collectElements(
            in: sheet,
            role: kAXButtonRole as String,
            remainingDepth: 6,
            results: &buttons
        )
        guard let declineButton = buttons.first(where: {
            NotesAccessibilityBridge.stringAttribute($0, kAXTitleAttribute as CFString) == Self.autoSortDeclineButton
        }) else {
            throw NotesStructuredFormattingError.blockedByDialog(prompt)
        }

        guard AXUIElementPerformAction(declineButton, kAXPressAction as CFString) == .success else {
            throw NotesStructuredFormattingError.blockedByDialog(prompt)
        }

        // The sheet has to actually go away before the editor can take focus again.
        for _ in 0..<Self.waitIterations {
            var remaining: [AXUIElement] = []
            NotesAccessibilityBridge.collectElements(
                in: window,
                role: kAXSheetRole as String,
                remainingDepth: 4,
                results: &remaining
            )
            if remaining.isEmpty { return }
            Thread.sleep(forTimeInterval: Self.waitInterval)
        }

        throw NotesStructuredFormattingError.blockedByDialog(prompt)
    }

    private func verifyFocus(editor: AXUIElement) throws {
        guard let notesApplication = NSRunningApplication
            .runningApplications(withBundleIdentifier: "com.apple.Notes")
            .first,
            NSWorkspace.shared.frontmostApplication?.processIdentifier == notesApplication.processIdentifier else {
            throw NotesStructuredFormattingError.focusLost
        }

        guard AXUIElementSetAttributeValue(
            editor,
            kAXFocusedAttribute as CFString,
            kCFBooleanTrue
        ) == .success,
            let focusedElement = NotesAccessibilityBridge.elementAttribute(
                application,
                kAXFocusedUIElementAttribute as CFString
            ),
            CFEqual(focusedElement, editor) else {
            throw NotesStructuredFormattingError.focusLost
        }
    }

    private func findMenuItem(
        commandCharacter: String,
        modifiers: AXMenuItemModifiers
    ) -> AXUIElement? {
        guard let menuBar = NotesAccessibilityBridge.elementAttribute(
            application,
            kAXMenuBarAttribute as CFString
        ) else {
            return nil
        }
        return findMenuItem(
            in: menuBar,
            commandCharacter: commandCharacter,
            modifiers: modifiers,
            remainingDepth: 12
        )
    }

    private func findMenuItem(
        in element: AXUIElement,
        commandCharacter: String,
        modifiers: AXMenuItemModifiers,
        remainingDepth: Int
    ) -> AXUIElement? {
        guard remainingDepth > 0 else { return nil }

        if NotesAccessibilityBridge.stringAttribute(element, kAXRoleAttribute as CFString) == kAXMenuItemRole as String,
           NotesAccessibilityBridge.stringAttribute(
               element,
               kAXMenuItemCmdCharAttribute as CFString
           )?.uppercased() == commandCharacter,
           NotesAccessibilityBridge.intAttribute(
               element,
               kAXMenuItemCmdModifiersAttribute as CFString
           ) == Int(modifiers.rawValue) {
            return element
        }

        for child in NotesAccessibilityBridge.children(of: element) {
            if let match = findMenuItem(
                in: child,
                commandCharacter: commandCharacter,
                modifiers: modifiers,
                remainingDepth: remainingDepth - 1
            ) {
                return match
            }
        }
        return nil
    }
}
