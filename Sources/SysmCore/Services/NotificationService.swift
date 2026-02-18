import Foundation
import UserNotifications

public struct NotificationService: NotificationServiceProtocol {
    public init() {}

    // MARK: - Send

    public func send(title: String, body: String, subtitle: String?, sound: Bool) async throws {
        var script = "display notification \(appleScriptString(body)) with title \(appleScriptString(title))"
        if let subtitle = subtitle {
            script += " subtitle \(appleScriptString(subtitle))"
        }
        if sound {
            script += " sound name \"default\""
        }
        _ = try Shell.run("/usr/bin/osascript", args: ["-e", script])
    }

    // MARK: - Schedule

    public func schedule(title: String, body: String, subtitle: String?, triggerDate: Date, sound: Bool) async throws -> String {
        let center = try notificationCenter()
        try await ensureAccess(center: center)

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if let subtitle = subtitle {
            content.subtitle = subtitle
        }
        if sound {
            content.sound = .default
        }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let identifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try await center.add(request)
        return identifier
    }

    // MARK: - List & Remove

    public func listPending() async throws -> [PendingNotification] {
        let center = try notificationCenter()
        try await ensureAccess(center: center)

        let requests = await center.pendingNotificationRequests()
        return requests.map { request in
            let trigger = request.trigger as? UNCalendarNotificationTrigger
            let triggerDate = trigger?.nextTriggerDate()
            return PendingNotification(
                identifier: request.identifier,
                title: request.content.title,
                body: request.content.body,
                subtitle: request.content.subtitle.isEmpty ? nil : request.content.subtitle,
                triggerDate: triggerDate
            )
        }
    }

    public func removePending(identifier: String) async throws {
        let center = try notificationCenter()
        try await ensureAccess(center: center)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    public func removeAllPending() async throws {
        let center = try notificationCenter()
        try await ensureAccess(center: center)
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Private

    private func notificationCenter() throws -> UNUserNotificationCenter {
        guard Bundle.main.bundleIdentifier != nil else {
            throw NotificationError.noBundleContext
        }
        return UNUserNotificationCenter.current()
    }

    private func ensureAccess(center: UNUserNotificationCenter) async throws {
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return
        case .notDetermined:
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else {
                throw NotificationError.accessDenied
            }
        case .denied:
            throw NotificationError.accessDenied
        @unknown default:
            throw NotificationError.accessDenied
        }
    }

    private func appleScriptString(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }
}

public enum NotificationError: LocalizedError {
    case accessDenied
    case scheduleFailed(String)
    case noBundleContext

    public var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Notification permission denied"
        case .scheduleFailed(let msg):
            return "Failed to schedule notification: \(msg)"
        case .noBundleContext:
            return "Scheduling requires an app bundle context (not available for standalone binaries)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .accessDenied:
            return """
            Notification permission is required:
            1. Open System Settings
            2. Navigate to Notifications
            3. Find sysm and enable notifications
            """
        case .scheduleFailed:
            return nil
        case .noBundleContext:
            return "Use 'sysm notify send' for immediate notifications, or install sysm as an app bundle for scheduling support."
        }
    }
}
