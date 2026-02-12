import EventKit
import Foundation

/// Represents an event alarm/reminder.
public struct EventAlarm: Codable {
    public let triggerMinutes: Int?
    public let type: String
    public let location: StructuredLocation?
    public let proximity: String? // "enter" or "leave"

    // Time-based alarm initializer
    public init(triggerMinutes: Int, type: String = "display") {
        self.triggerMinutes = triggerMinutes
        self.type = type
        self.location = nil
        self.proximity = nil
    }

    // Location-based alarm initializer
    public init(location: StructuredLocation, proximity: String, type: String = "display") {
        self.triggerMinutes = nil
        self.type = type
        self.location = location
        self.proximity = proximity
    }

    public init(from ekAlarm: EKAlarm) {
        self.type = ekAlarm.type == .audio ? "audio" : "display"

        // Check if it's a location-based alarm
        if let ekLocation = ekAlarm.structuredLocation {
            self.location = StructuredLocation(from: ekLocation)
            self.proximity = ekAlarm.proximity == .enter ? "enter" : "leave"
            self.triggerMinutes = nil
        } else {
            // Time-based alarm
            self.triggerMinutes = Int(-ekAlarm.relativeOffset / 60)
            self.location = nil
            self.proximity = nil
        }
    }

    public func toEKAlarm() -> EKAlarm {
        if let loc = location, let prox = proximity {
            // Location-based alarm
            let alarm = EKAlarm()
            alarm.structuredLocation = loc.toEKStructuredLocation()
            alarm.proximity = prox == "enter" ? .enter : .leave
            return alarm
        } else {
            // Time-based alarm
            return EKAlarm(relativeOffset: TimeInterval(-(triggerMinutes ?? 0) * 60))
        }
    }

    public var description: String {
        if let loc = location, let prox = proximity {
            let action = prox == "enter" ? "When arriving at" : "When leaving"
            return "\(action) \(loc.title)"
        } else if let minutes = triggerMinutes {
            if minutes == 0 {
                return "At time of event"
            } else if minutes < 60 {
                return "\(minutes) minute\(minutes == 1 ? "" : "s") before"
            } else if minutes < 1440 {
                let hours = minutes / 60
                return "\(hours) hour\(hours == 1 ? "" : "s") before"
            } else {
                let days = minutes / 1440
                return "\(days) day\(days == 1 ? "" : "s") before"
            }
        } else {
            return "Unknown alarm"
        }
    }
}
