import Foundation

/// Protocol for Shortcuts service operations
protocol ShortcutsServiceProtocol {
    func list() throws -> [String]
    func run(name: String, input: String?) throws -> String
}
