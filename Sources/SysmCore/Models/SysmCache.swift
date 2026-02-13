import Foundation

/// A cache entry with TTL (time-to-live) support.
///
/// Stores a value along with its creation timestamp and expiration time.
/// Used for general-purpose caching with automatic expiration.
public struct CacheEntry<T: Codable>: Codable {
    /// The cached value
    public let value: T

    /// Timestamp when this entry was created
    public let timestamp: Date

    /// Time-to-live in seconds (0 means no expiration)
    public let ttl: TimeInterval

    /// Whether this entry has expired
    public var isExpired: Bool {
        guard ttl > 0 else { return false }
        return Date().timeIntervalSince(timestamp) > ttl
    }

    public init(value: T, ttl: TimeInterval = 0) {
        self.value = value
        self.timestamp = Date()
        self.ttl = ttl
    }
}

/// Persistent cache for sysm state stored at ~/.sysm_cache.json.
///
/// Provides general-purpose caching with TTL support for service responses,
/// plus specialized reminder tracking for the `sysm today` command.
///
/// ## Cache Categories
///
/// - **Reminder tracking**: Persistent tracking of reminder state (no TTL)
/// - **General cache**: Service responses with configurable TTL
///   - Calendar queries: 30s TTL
///   - Contacts search: 5m TTL
///   - Photo albums: 1m TTL
///   - Safari bookmarks: 30s TTL
///
/// ## Example
///
/// ```swift
/// let cache = CacheService()
/// var state = cache.loadCache()
///
/// // Store with TTL
/// let entry = CacheEntry(value: events, ttl: 30)
/// state.cache["calendar:today"] = try AnyCodableEntry(entry)
///
/// // Retrieve and check expiration
/// if let cached: CacheEntry<[CalendarEvent]> = try? state.getCacheEntry("calendar:today"),
///    !cached.isExpired {
///     return cached.value
/// }
/// ```
public struct SysmCache: Codable {
    /// Persistent reminder tracking (no expiration)
    public var seenReminders: [String: TrackedReminder]

    /// General-purpose cache with TTL support
    /// Keys use format: "{service}:{operation}:{param}"
    /// Examples: "calendar:today", "contacts:search:john", "photos:albums"
    public var cache: [String: AnyCodable]

    public enum CodingKeys: String, CodingKey {
        case seenReminders = "seen_reminders"
        case cache
    }

    public init() {
        self.seenReminders = [:]
        self.cache = [:]
    }

    /// Retrieves a typed cache entry, returning nil if expired or missing
    public func getCacheEntry<T: Codable>(_ key: String) throws -> CacheEntry<T>? {
        guard let anyCodable = cache[key] else { return nil }

        // Decode from AnyCodable
        let data = try JSONEncoder().encode(anyCodable)
        let entry = try JSONDecoder().decode(CacheEntry<T>.self, from: data)

        return entry.isExpired ? nil : entry
    }
}
