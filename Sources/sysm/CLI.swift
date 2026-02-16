import Foundation

enum CLI {
    /// Prompts the user for confirmation and returns true if they accept.
    /// Accepts "y" or "yes" (case-insensitive). Anything else is treated as decline.
    static func confirm(_ message: String) -> Bool {
        print(message, terminator: "")
        guard let response = readLine()?.lowercased(),
              response == "y" || response == "yes" else {
            print("Cancelled")
            return false
        }
        return true
    }
}
