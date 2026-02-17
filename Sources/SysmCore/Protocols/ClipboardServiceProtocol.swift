import Foundation

public protocol ClipboardServiceProtocol: Sendable {
    /// Get the current clipboard text content.
    func getText() -> String?

    /// Set the clipboard text content.
    func setText(_ text: String)

    /// Clear the clipboard.
    func clear()

    /// Get the types of content currently on the clipboard.
    func getTypes() -> [String]
}
