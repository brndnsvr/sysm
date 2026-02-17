import Foundation

public struct ScreenCaptureService: ScreenCaptureServiceProtocol {
    public init() {}

    public func captureScreen(outputPath: String, display: Int?) throws {
        let expanded = expandPath(outputPath)
        ensureDirectory(expanded)

        var args = ["-x"] // no sound
        if let display = display {
            args += ["-D", String(display)]
        }
        args.append(expanded)

        try runScreencapture(args)
    }

    public func captureWindow(outputPath: String, title: String?) throws {
        let expanded = expandPath(outputPath)
        ensureDirectory(expanded)

        if title != nil {
            // Interactive window selection mode
            var args = ["-x", "-w", expanded]
            // screencapture -w enters interactive mode for window pick
            args = ["-x", "-w", expanded]
            try runScreencapture(args)
        } else {
            try runScreencapture(["-x", "-w", expanded])
        }
    }

    public func captureArea(outputPath: String, rect: CaptureRect?) throws {
        let expanded = expandPath(outputPath)
        ensureDirectory(expanded)

        if let rect = rect {
            // Use -R flag for specific rectangle
            let rectStr = "\(rect.x),\(rect.y),\(rect.width),\(rect.height)"
            try runScreencapture(["-x", "-R", rectStr, expanded])
        } else {
            // Interactive selection
            try runScreencapture(["-x", "-s", expanded])
        }
    }

    // MARK: - Private

    private func runScreencapture(_ args: [String]) throws {
        // Shell.run throws on non-zero exit, which is what we want
        _ = try Shell.run("/usr/sbin/screencapture", args: args)
    }

    private func expandPath(_ path: String) -> String {
        (path as NSString).expandingTildeInPath
    }

    private func ensureDirectory(_ filePath: String) {
        let dir = (filePath as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
    }
}

public enum ScreenCaptureError: LocalizedError {
    case captureFailed(String)

    public var errorDescription: String? {
        switch self {
        case .captureFailed(let msg):
            return "Screen capture failed: \(msg)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .captureFailed:
            return """
            Screen recording permission may be required:
            1. Open System Settings
            2. Navigate to Privacy & Security > Screen Recording
            3. Enable access for Terminal (or your terminal app)
            """
        }
    }
}
