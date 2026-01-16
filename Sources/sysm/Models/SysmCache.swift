import Foundation

struct SysmCache: Codable {
    var seenReminders: [String: TrackedReminder]
    var events: [String: AnyCodable]?
    var reminders: [String: AnyCodable]?
    var notes: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case seenReminders = "seen_reminders"
        case events
        case reminders
        case notes
    }

    init() {
        self.seenReminders = [:]
    }
}
