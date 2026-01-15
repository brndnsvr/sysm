import Foundation

/// Protocol for focus/DND service operations
protocol FocusServiceProtocol {
    func getStatus() throws -> FocusStatusInfo
    func enableDND() throws
    func disableDND() throws
    func listFocusModes() throws -> [String]
}
