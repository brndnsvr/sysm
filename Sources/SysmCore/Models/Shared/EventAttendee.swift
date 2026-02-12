import EventKit
import Foundation

/// Represents an event attendee.
public struct EventAttendee: Codable {
    public let name: String?
    public let email: String?
    public let status: String
    public let isOrganizer: Bool

    public init(from participant: EKParticipant) {
        self.name = participant.name
        self.email = participant.url.absoluteString.replacingOccurrences(of: "mailto:", with: "")
        self.isOrganizer = participant.isCurrentUser && participant.participantRole == .chair

        switch participant.participantStatus {
        case .accepted: self.status = "accepted"
        case .declined: self.status = "declined"
        case .tentative: self.status = "tentative"
        case .pending: self.status = "pending"
        case .delegated: self.status = "delegated"
        case .completed: self.status = "completed"
        case .inProcess: self.status = "in-process"
        case .unknown: self.status = "unknown"
        @unknown default: self.status = "unknown"
        }
    }

    public var formatted: String {
        let displayName = name ?? email ?? "Unknown"
        let statusIcon: String
        switch status {
        case "accepted": statusIcon = "✓"
        case "declined": statusIcon = "✗"
        case "tentative": statusIcon = "?"
        default: statusIcon = "○"
        }
        return "\(statusIcon) \(displayName)\(isOrganizer ? " (organizer)" : "")"
    }
}
