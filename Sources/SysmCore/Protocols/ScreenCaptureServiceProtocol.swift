import Foundation

public protocol ScreenCaptureServiceProtocol: Sendable {
    func captureScreen(outputPath: String, display: Int?) throws
    func captureWindow(outputPath: String, title: String?) throws
    func captureArea(outputPath: String, rect: CaptureRect?) throws
}
