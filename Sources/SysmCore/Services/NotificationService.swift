import Foundation
import UserNotifications

public actor NotificationService: NotificationServiceProtocol {
    private let center = UNUserNotificationCenter.current()

    // MARK: - Authorization

    private func ensureAccess() async throws {
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

    // MARK: - Send

    public func send(title: String, body: String, subtitle: String?, sound: Bool) async throws {
        try await ensureAccess()

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if let subtitle = subtitle {
            content.subtitle = subtitle
        }
        if sound {
            content.sound = .default
        }

        let identifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        try await center.add(request)
    }

    // MARK: - Schedule

    public func schedule(title: String, body: String, subtitle: String?, triggerDate: Date, sound: Bool) async throws -> String {
        try await ensureAccess()

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
        try await ensureAccess()

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
        try await ensureAccess()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    public func removeAllPending() async throws {
        try await ensureAccess()
        center.removeAllPendingNotificationRequests()
    }
}

public enum NotificationError: LocalizedError {
    case accessDenied
    case scheduleFailed(String)

    public var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Notification permission denied"
        case .scheduleFailed(let msg):
            return "Failed to schedule notification: \(msg)"
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
        }
    }
}
