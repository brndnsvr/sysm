import EventKit
import Foundation

/// Represents a calendar with its properties.
public struct Calendar: Codable {
    public let identifier: String
    public let title: String
    public let type: String
    public let color: String
    public let allowsContentModifications: Bool
    public let isSubscribed: Bool
    public let source: String?

    /// Creates a Calendar from an EventKit calendar.
    public init(from ekCalendar: EKCalendar) {
        self.identifier = ekCalendar.calendarIdentifier
        self.title = ekCalendar.title
        self.allowsContentModifications = ekCalendar.allowsContentModifications
        self.isSubscribed = ekCalendar.isSubscribed

        switch ekCalendar.type {
        case .local: self.type = "local"
        case .calDAV: self.type = "caldav"
        case .exchange: self.type = "exchange"
        case .subscription: self.type = "subscription"
        case .birthday: self.type = "birthday"
        @unknown default: self.type = "unknown"
        }

        // Convert CGColor to hex string
        if let cgColor = ekCalendar.cgColor {
            self.color = cgColor.toHexString()
        } else {
            self.color = "#000000"
        }

        self.source = ekCalendar.source?.title
    }

    public var formatted: String {
        var parts = [title]
        parts.append("[\(type)]")
        if !allowsContentModifications {
            parts.append("(read-only)")
        }
        return parts.joined(separator: " ")
    }
}

extension CGColor {
    func toHexString() -> String {
        guard let components = self.components, components.count >= 3 else {
            return "#000000"
        }
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
