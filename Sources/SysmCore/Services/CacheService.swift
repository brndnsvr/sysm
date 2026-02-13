import Foundation

public final class CacheService: CacheServiceProtocol, @unchecked Sendable {
    private let cachePath: URL
    private let maxCacheEntries = 1000 // Prevent unbounded growth

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

    // MARK: - General-Purpose Cache

    public func get<T: Codable>(_ key: String, as type: T.Type) throws -> T? {
        let cache = loadCache()

        // Try to get and decode the entry
        guard let entry: CacheEntry<T> = try? cache.getCacheEntry(key) else {
            return nil
        }

        return entry.value
    }

    public func set<T: Codable>(_ key: String, value: T, ttl: TimeInterval = 0) throws {
        var cache = loadCache()

        // Create cache entry with TTL
        let entry = CacheEntry(value: value, ttl: ttl)

        // Encode to AnyCodable
        let data = try JSONEncoder().encode(entry)
        let anyCodable = try JSONDecoder().decode(AnyCodable.self, from: data)

        cache.cache[key] = anyCodable

        // Cleanup expired entries and enforce size limit
        try cleanupCacheInternal(&cache)

        try saveCache(cache)
    }

    public func invalidate(_ key: String) throws {
        var cache = loadCache()
        cache.cache.removeValue(forKey: key)
        try saveCache(cache)
    }

    public func invalidatePrefix(_ prefix: String) throws {
        var cache = loadCache()
        let keysToRemove = cache.cache.keys.filter { $0.hasPrefix(prefix) }
        for key in keysToRemove {
            cache.cache.removeValue(forKey: key)
        }
        try saveCache(cache)
    }

    public func clearCache() throws {
        var cache = loadCache()
        cache.cache.removeAll()
        try saveCache(cache)
    }

    public func cleanupExpired() throws {
        var cache = loadCache()
        try cleanupCacheInternal(&cache)
        try saveCache(cache)
    }

    /// Internal cleanup that removes expired entries and enforces size limit
    private func cleanupCacheInternal(_ cache: inout SysmCache) throws {
        // Remove expired entries
        var keysToRemove: [String] = []

        for (key, value) in cache.cache {
            // Try to decode as a generic cache entry to check expiration
            do {
                let data = try JSONEncoder().encode(value)
                let decoder = JSONDecoder()

                // Peek at the structure to get timestamp and ttl
                let container = try decoder.decode([String: AnyCodable].self, from: data)

                if let timestampAny = container["timestamp"],
                   let ttlAny = container["ttl"],
                   let timestampData = try? JSONEncoder().encode(timestampAny),
                   let ttlData = try? JSONEncoder().encode(ttlAny),
                   let timestamp = try? JSONDecoder().decode(Date.self, from: timestampData),
                   let ttl = try? JSONDecoder().decode(TimeInterval.self, from: ttlData),
                   ttl > 0 {

                    let age = Date().timeIntervalSince(timestamp)
                    if age > ttl {
                        keysToRemove.append(key)
                    }
                }
            } catch {
                // If we can't decode, skip this entry
                continue
            }
        }

        for key in keysToRemove {
            cache.cache.removeValue(forKey: key)
        }

        // Enforce size limit by removing oldest entries
        if cache.cache.count > maxCacheEntries {
            // Sort by timestamp (oldest first) and remove excess
            var entries: [(key: String, timestamp: Date)] = []

            for (key, value) in cache.cache {
                do {
                    let data = try JSONEncoder().encode(value)
                    let container = try JSONDecoder().decode([String: AnyCodable].self, from: data)

                    if let timestampAny = container["timestamp"],
                       let timestampData = try? JSONEncoder().encode(timestampAny),
                       let timestamp = try? JSONDecoder().decode(Date.self, from: timestampData) {
                        entries.append((key: key, timestamp: timestamp))
                    }
                } catch {
                    continue
                }
            }

            // Sort by timestamp (oldest first)
            entries.sort { $0.timestamp < $1.timestamp }

            // Remove oldest entries beyond limit
            let toRemove = cache.cache.count - maxCacheEntries
            for i in 0..<toRemove {
                cache.cache.removeValue(forKey: entries[i].key)
            }
        }
    }

    // MARK: - Reminder Tracking

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
