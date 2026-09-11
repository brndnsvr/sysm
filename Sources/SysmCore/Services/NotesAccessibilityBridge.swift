import ApplicationServices
import Foundation

enum NotesAccessibilityBridge {
    static func select(range: NSRange, in editor: AXUIElement) throws {
        var cfRange = CFRange(location: range.location, length: range.length)
        guard let rangeValue = AXValueCreate(.cfRange, &cfRange),
              AXUIElementSetAttributeValue(
                  editor,
                  kAXSelectedTextRangeAttribute as CFString,
                  rangeValue
              ) == .success,
              let selectedRange = selectedTextRange(in: editor),
              selectedRange.location == range.location,
              selectedRange.length == range.length else {
            throw NotesStructuredFormattingError.textSelectionFailed
        }
    }

    static func collectElements(
        in element: AXUIElement,
        role: String,
        remainingDepth: Int,
        results: inout [AXUIElement]
    ) {
        guard remainingDepth > 0 else { return }
        if stringAttribute(element, kAXRoleAttribute as CFString) == role {
            results.append(element)
        }
        for child in children(of: element) {
            collectElements(in: child, role: role, remainingDepth: remainingDepth - 1, results: &results)
        }
    }

    static func children(of element: AXUIElement) -> [AXUIElement] {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element,
            kAXChildrenAttribute as CFString,
            &value
        ) == .success,
            let children = value as? [AXUIElement] else {
            return []
        }
        return children
    }

    static func elementAttribute(_ element: AXUIElement, _ attribute: CFString) -> AXUIElement? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success,
              let value,
              CFGetTypeID(value) == AXUIElementGetTypeID() else {
            return nil
        }
        return unsafeBitCast(value, to: AXUIElement.self)
    }

    static func stringAttribute(_ element: AXUIElement, _ attribute: CFString) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else { return nil }
        return value as? String
    }

    static func boolAttribute(_ element: AXUIElement, _ attribute: CFString) -> Bool? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else { return nil }
        return value as? Bool
    }

    static func intAttribute(_ element: AXUIElement, _ attribute: CFString) -> Int? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success else { return nil }
        return (value as? NSNumber)?.intValue
    }

    static func isSettable(_ element: AXUIElement, attribute: CFString) -> Bool {
        var settable = DarwinBoolean(false)
        return AXUIElementIsAttributeSettable(element, attribute, &settable) == .success && settable.boolValue
    }

    private static func selectedTextRange(in element: AXUIElement) -> CFRange? {
        var rawValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            &rawValue
        ) == .success,
            let rawValue,
            CFGetTypeID(rawValue) == AXValueGetTypeID() else {
            return nil
        }

        let value = unsafeBitCast(rawValue, to: AXValue.self)
        guard AXValueGetType(value) == .cfRange else { return nil }
        var range = CFRange()
        guard AXValueGetValue(value, .cfRange, &range) else { return nil }
        return range
    }
}
