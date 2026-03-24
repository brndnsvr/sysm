import Foundation

public final class CacheService: CacheServiceProtocol, @unchecked Sendable {
    private let cachePath: URL
    private let maxCacheEntries = 1000
    private let lock = NSLock()
    private var cachedState: SysmCache?

    public init(cachePath: URL? = nil) {
        self.cachePath = cachePath ?? FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".sysm_cache.json")
    }

    // MARK: - Internal State Management

    /// Returns the in-memory cache, loading from disk on first access.
    private func state() -> SysmCache {
        if let cached = cachedState {
            return cached
        }

        guard FileManager.default.fileExists(atPath: cachePath.path) else {
            let empty = SysmCache()
            cachedState = empty
            return empty
        }

        do {
            let data = try Data(contentsOf: cachePath)
            let decoded = try JSONDecoder().decode(SysmCache.self, from: data)
            cachedState = decoded
            return decoded
        } catch {
            fputs("warning: cache file corrupt (\(cachePath.path)): \(error.localizedDescription)\n", stderr)
            let empty = SysmCache()
            cachedState = empty
            return empty
        }
    }

    /// Writes the in-memory cache to disk atomically.
    private func flush() throws {
        guard let state = cachedState else { return }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(state)
        try data.write(to: cachePath, options: .atomic)
    }

    // MARK: - General-Purpose Cache

    public func get<T: Codable>(_ key: String, as type: T.Type) throws -> T? {
        lock.lock()
        defer { lock.unlock() }

        let cache = state()
        guard let entry: CacheEntry<T> = try? cache.getCacheEntry(key) else {
            return nil
        }
        return entry.value
    }

    public func set<T: Codable>(_ key: String, value: T, ttl: TimeInterval = 0) throws {
        lock.lock()
        defer { lock.unlock() }

        var cache = state()

        let entry = CacheEntry(value: value, ttl: ttl)
        let data = try JSONEncoder().encode(entry)
        let anyCodable = try JSONDecoder().decode(AnyCodable.self, from: data)

        cache.cache[key] = anyCodable

        cleanupCacheInternal(&cache)

        cachedState = cache
        try flush()
    }

    public func invalidate(_ key: String) throws {
        lock.lock()
        defer { lock.unlock() }

        var cache = state()
        cache.cache.removeValue(forKey: key)
        cachedState = cache
        try flush()
    }

    public func invalidatePrefix(_ prefix: String) throws {
        lock.lock()
        defer { lock.unlock() }

        var cache = state()
        let keysToRemove = cache.cache.keys.filter { $0.hasPrefix(prefix) }
        for key in keysToRemove {
            cache.cache.removeValue(forKey: key)
        }
        cachedState = cache
        try flush()
    }

    public func clearCache() throws {
        lock.lock()
        defer { lock.unlock() }

        var cache = state()
        cache.cache.removeAll()
        cachedState = cache
        try flush()
    }

    public func cleanupExpired() throws {
        lock.lock()
        defer { lock.unlock() }

        var cache = state()
        cleanupCacheInternal(&cache)
        cachedState = cache
        try flush()
    }

    /// Metadata-only view of a cache entry for expiration checks.
    private struct CacheEntryMetadata: Codable {
        let timestamp: Date
        let ttl: TimeInterval

        var isExpired: Bool {
            guard ttl > 0 else { return false }
            return Date().timeIntervalSince(timestamp) > ttl
        }
    }

    /// Removes expired entries and enforces size limit.
    private func cleanupCacheInternal(_ cache: inout SysmCache) {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        // Remove expired entries
        var keysToRemove: [String] = []
        for (key, value) in cache.cache {
            if let data = try? encoder.encode(value),
               let metadata = try? decoder.decode(CacheEntryMetadata.self, from: data),
               metadata.isExpired {
                keysToRemove.append(key)
            }
        }
        for key in keysToRemove {
            cache.cache.removeValue(forKey: key)
        }

        // Enforce size limit by removing oldest entries
        if cache.cache.count > maxCacheEntries {
            var entries: [(key: String, timestamp: Date)] = []
            for (key, value) in cache.cache {
                if let data = try? encoder.encode(value),
                   let metadata = try? decoder.decode(CacheEntryMetadata.self, from: data) {
                    entries.append((key: key, timestamp: metadata.timestamp))
                }
            }
            entries.sort { $0.timestamp < $1.timestamp }
            let toRemove = cache.cache.count - maxCacheEntries
            for i in 0..<toRemove {
                cache.cache.removeValue(forKey: entries[i].key)
            }
        }
    }

    // MARK: - Reminder Tracking

    public func getSeenReminders() -> [String: TrackedReminder] {
        lock.lock()
        defer { lock.unlock() }
        return state().seenReminders
    }

    public func saveSeenReminders(_ seen: [String: TrackedReminder]) throws {
        lock.lock()
        defer { lock.unlock()  }
        var cache = state()
        cache.seenReminders = seen
        cachedState = cache
        try flush()
    }

    public func trackReminder(name: String, project: String?) throws {
        lock.lock()
        defer { lock.unlock() }

        var cache = state()
        let key = TrackedReminder.makeKey(name)

        var tracked = cache.seenReminders[key] ?? TrackedReminder(originalName: name)
        tracked.originalName = name
        tracked.tracked = true
        tracked.dismissed = false
        tracked.project = project ?? ""
        tracked.firstSeen = TrackedReminder.todayString()
        tracked.status = "pending"

        cache.seenReminders[key] = tracked
        cachedState = cache
        try flush()
    }

    public func dismissReminder(name: String) throws {
        lock.lock()
        defer { lock.unlock() }

        var cache = state()
        let key = TrackedReminder.makeKey(name)

        var dismissed = cache.seenReminders[key] ?? TrackedReminder(originalName: name)
        dismissed.originalName = name
        dismissed.tracked = false
        dismissed.dismissed = true
        dismissed.firstSeen = TrackedReminder.todayString()

        cache.seenReminders[key] = dismissed
        cachedState = cache
        try flush()
    }

    public func completeTracked(name: String) throws -> Bool {
        lock.lock()
        defer { lock.unlock() }

        var cache = state()
        let key = TrackedReminder.makeKey(name)

        guard var tracked = cache.seenReminders[key], tracked.tracked else {
            return false
        }

        tracked.status = "done"
        tracked.completedDate = TrackedReminder.todayString()
        cache.seenReminders[key] = tracked
        cachedState = cache
        try flush()
        return true
    }

    public func untrackReminder(name: String) throws -> Bool {
        lock.lock()
        defer { lock.unlock() }

        var cache = state()
        let key = TrackedReminder.makeKey(name)

        guard cache.seenReminders[key] != nil else {
            return false
        }

        cache.seenReminders.removeValue(forKey: key)
        cachedState = cache
        try flush()
        return true
    }

    public func getTrackedReminders() -> [(key: String, reminder: TrackedReminder)] {
        lock.lock()
        defer { lock.unlock() }

        let seen = state().seenReminders
        return seen
            .filter { $0.value.tracked }
            .sorted { $0.value.firstSeen > $1.value.firstSeen }
            .map { ($0.key, $0.value) }
    }

    public func getNewReminders(currentReminders: [Reminder]) -> [Reminder] {
        lock.lock()
        defer { lock.unlock() }

        let seen = state().seenReminders
        return currentReminders.filter { reminder in
            let key = TrackedReminder.makeKey(reminder.title)
            return seen[key] == nil
        }
    }
}
