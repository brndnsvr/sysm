import AppKit
import Foundation

public struct ClipboardService: ClipboardServiceProtocol {
    public init() {}

    public func getText() -> String? {
        NSPasteboard.general.string(forType: .string)
    }

    public func setText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    public func clear() {
        NSPasteboard.general.clearContents()
    }

    public func getTypes() -> [String] {
        NSPasteboard.general.types?.map(\.rawValue) ?? []
    }
}
