import Foundation

/// Converts text typed at the command line into the HTML a note body holds.
public enum NotesPlainText {
    /// Escapes HTML metacharacters and turns line breaks into `<br>`.
    ///
    /// A note's body is HTML. The CLI used to pass typed text through as is,
    /// so "<" and "&" were read as markup and line breaks collapsed into one
    /// line. The ampersand is escaped first so typed entities stay visible.
    public static func html(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\n", with: "<br>")
    }
}
