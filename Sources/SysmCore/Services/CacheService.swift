import Foundation

public class CacheService {
    private let cachePath: URL

    public init() {
        self.cachePath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".sysm_cache.json")
    }

    public func loadCache() -> SysmCache {
        guard FileManager.default.fileExists(atPath: cachePath.path) else {
            return SysmCache()
        }

        do {
            let data = try Data(contentsOf: cachePath)
            let decoder = JSONDecoder()
            return try decoder.decode(SysmCache.self, from: data)
        } catch {
            return SysmCache()
        }
    }

    public func saveCache(_ cache: SysmCache) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(cache)
        try data.write(to: cachePath)
    }

    public func getSeenReminders() -> [String: TrackedReminder] {
        return loadCache().seenReminders
    }

    public func saveSeenReminders(_ seen: [String: TrackedReminder]) throws {
        var cache = loadCache()
        cache.seenReminders = seen
        try saveCache(cache)
    }

    public func trackReminder(name: String, project: String?) throws {
        var seen = getSeenReminders()
        let key = TrackedReminder.makeKey(name)

        var tracked = seen[key] ?? TrackedReminder(originalName: name)
        tracked.originalName = name
        tracked.tracked = true
        tracked.dismissed = false
        tracked.project = project ?? ""
        tracked.firstSeen = TrackedReminder.todayString()
        tracked.status = "pending"

        seen[key] = tracked
        try saveSeenReminders(seen)
    }

    public func dismissReminder(name: String) throws {
        var seen = getSeenReminders()
        let key = TrackedReminder.makeKey(name)

        var dismissed = seen[key] ?? TrackedReminder(originalName: name)
        dismissed.originalName = name
        dismissed.tracked = false
        dismissed.dismissed = true
        dismissed.firstSeen = TrackedReminder.todayString()

        seen[key] = dismissed
        try saveSeenReminders(seen)
    }

    public func completeTracked(name: String) throws -> Bool {
        var seen = getSeenReminders()
        let key = TrackedReminder.makeKey(name)

        guard var tracked = seen[key], tracked.tracked else {
            return false
        }

        tracked.status = "done"
        tracked.completedDate = TrackedReminder.todayString()
        seen[key] = tracked
        try saveSeenReminders(seen)
        return true
    }

    public func untrackReminder(name: String) throws -> Bool {
        var seen = getSeenReminders()
        let key = TrackedReminder.makeKey(name)

        guard seen[key] != nil else {
            return false
        }

        seen.removeValue(forKey: key)
        try saveSeenReminders(seen)
        return true
    }

    public func getTrackedReminders() -> [(key: String, reminder: TrackedReminder)] {
        let seen = getSeenReminders()
        return seen
            .filter { $0.value.tracked }
            .sorted { $0.value.firstSeen > $1.value.firstSeen }
            .map { ($0.key, $0.value) }
    }

    public func getNewReminders(currentReminders: [Reminder]) -> [Reminder] {
        let seen = getSeenReminders()
        return currentReminders.filter { reminder in
            let key = TrackedReminder.makeKey(reminder.title)
            return seen[key] == nil
        }
    }
}
