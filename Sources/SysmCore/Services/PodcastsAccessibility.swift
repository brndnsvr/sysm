import ApplicationServices
import AppKit
import Foundation

protocol PodcastsPlaybackControlling: Sendable {
    func play() throws
    func pause() throws
}

struct AccessibilityPodcastsPlaybackController: PodcastsPlaybackControlling {
    private static let transportButtonIdentifiers = [
        "podcasts.miniPlayer.playbackTransportControl",
        "podcasts.nowPlaying.playbackTransportControl",
    ]

    func play() throws {
        try setPlayback(shouldPlay: true)
    }

    func pause() throws {
        try setPlayback(shouldPlay: false)
    }

    private func setPlayback(shouldPlay: Bool) throws {
        do {
            _ = try Shell.run("/usr/bin/open", args: ["-g", "-a", "Podcasts"], timeout: 10)
        } catch {
            throw PodcastsError.playbackFailed(error.localizedDescription)
        }
        try PodcastsAccessibility.requirePermission()

        for _ in 0..<100 {
            if let button = Self.transportButtonIdentifiers.lazy.compactMap({
                PodcastsAccessibility.element(identifier: $0)
            }).first {
                let description = PodcastsAccessibility.description(of: button)
                if shouldPlay, description == "Pause" { return }
                if !shouldPlay, description == "Play" { return }
                try PodcastsAccessibility.press(button)
                return
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
        throw PodcastsError.playbackFailed("Timed out waiting for Podcasts playback controls")
    }
}

enum PodcastsAccessibility {
    private static let podcastsBundleIdentifier = "com.apple.podcasts"

    static func requirePermission() throws {
        guard AXIsProcessTrusted() else {
            throw PodcastsError.playbackFailed(
                "Accessibility permission is required in System Settings > Privacy & Security > Accessibility"
            )
        }
    }

    static func element(identifier: String) -> AXUIElement? {
        guard let application = NSRunningApplication
            .runningApplications(withBundleIdentifier: podcastsBundleIdentifier)
            .first else {
            return nil
        }
        return findElement(
            in: AXUIElementCreateApplication(application.processIdentifier),
            identifier: identifier,
            remainingDepth: 20
        )
    }

    static func description(of element: AXUIElement) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element,
            kAXDescriptionAttribute as CFString,
            &value
        ) == .success else {
            return nil
        }
        return value as? String
    }

    static func press(_ element: AXUIElement) throws {
        guard AXUIElementPerformAction(element, kAXPressAction as CFString) == .success else {
            throw PodcastsError.playbackFailed("Could not press the Podcasts playback control")
        }
    }

    private static func findElement(
        in element: AXUIElement,
        identifier: String,
        remainingDepth: Int
    ) -> AXUIElement? {
        guard remainingDepth > 0 else { return nil }

        var identifierValue: CFTypeRef?
        if AXUIElementCopyAttributeValue(
            element,
            kAXIdentifierAttribute as CFString,
            &identifierValue
        ) == .success,
            (identifierValue as? String) == identifier {
            return element
        }

        var childrenValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element,
            kAXChildrenAttribute as CFString,
            &childrenValue
        ) == .success,
            let children = childrenValue as? [AXUIElement] else {
            return nil
        }
        for child in children {
            if let match = findElement(
                in: child,
                identifier: identifier,
                remainingDepth: remainingDepth - 1
            ) {
                return match
            }
        }
        return nil
    }
}
