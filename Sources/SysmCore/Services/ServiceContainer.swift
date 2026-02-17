import Foundation

/// Global service container for dependency injection.
///
/// This container uses the factory pattern to enable dependency injection and test substitution.
/// Service instances are lazily created and cached for performance.
///
/// ## Thread-Safety Model
///
/// This class is marked as `@unchecked Sendable` with explicit thread-safety guarantees:
///
/// 1. **NSLock Protection**: All cached instance access is protected by an NSLock, ensuring
///    only one thread can read/write cached instances at a time.
///
/// 2. **Lazy Initialization**: Services are created on first access within the lock, preventing
///    race conditions during initialization.
///
/// 3. **Actor Services**: Framework-based services (Calendar, Contacts, Photos, Reminders) are
///    declared as `actor`, providing automatic thread-safety for their mutable state (EventStore,
///    ContactStore, etc.).
///
/// 4. **Struct Services**: AppleScript-based services (Mail, Notes, Messages, etc.) are stateless
///    `struct` types that don't require synchronization.
///
/// 5. **Factory Pattern**: Factories are `var` properties to allow test substitution, but are
///    only written during test setup (single-threaded) and read during service creation (lock-protected).
///
/// ## Usage
///
/// ```swift
/// // Production code
/// let calendar = ServiceContainer.shared.calendar()
/// let events = try await calendar.getTodayEvents()
///
/// // Test code
/// ServiceContainer.shared.calendarFactory = { MockCalendarService() }
/// let calendar = ServiceContainer.shared.calendar()
/// // ... test with mock
/// ```
///
/// ## Why @unchecked Sendable is Safe
///
/// - The lock ensures exclusive access to all mutable state (cached instances)
/// - Factories are only mutated during single-threaded test setup
/// - Returned service instances are either actors (thread-safe) or structs (no shared state)
/// - The singleton pattern ensures a single shared container across all threads
///
public final class ServiceContainer: @unchecked Sendable {
    public static let shared = ServiceContainer()

    // MARK: - Thread Safety

    /// NSLock protecting all cached instance access.
    /// Ensures only one thread can create or retrieve cached services at a time.
    private let lock = NSLock()

    // MARK: - Service Factories

    public var calendarFactory: () -> any CalendarServiceProtocol = { CalendarService() }
    public var reminderFactory: () -> any ReminderServiceProtocol = { ReminderService() }
    public var contactsFactory: () -> any ContactsServiceProtocol = { ContactsService() }
    public var photosFactory: () -> any PhotosServiceProtocol = { PhotosService() }
    public var notesFactory: () -> any NotesServiceProtocol = { NotesService() }
    public var mailFactory: () -> any MailServiceProtocol = { MailService() }
    public var messagesFactory: () -> any MessagesServiceProtocol = { MessagesService() }
    public var musicFactory: () -> any MusicServiceProtocol = { MusicService() }
    public var focusFactory: () -> any FocusServiceProtocol = { FocusService() }
    public var safariFactory: () -> any SafariServiceProtocol = { SafariService() }
    public var tagsFactory: () -> any TagsServiceProtocol = { TagsService() }
    public var spotlightFactory: () -> any SpotlightServiceProtocol = { SpotlightService() }
    public var shortcutsFactory: () -> any ShortcutsServiceProtocol = { ShortcutsService() }
    public var workflowFactory: () -> any WorkflowEngineProtocol = { WorkflowEngine() }
    public var pluginFactory: () -> any PluginManagerProtocol = { PluginManager() }
    public var weatherFactory: () -> any WeatherServiceProtocol = { WeatherService() }
    public var weatherKitFactory: () -> any WeatherServiceProtocol = { WeatherKitService() }
    public var scriptRunnerFactory: () -> any ScriptRunnerProtocol = { ScriptRunner() }
    public var appleScriptRunnerFactory: () -> any AppleScriptRunnerProtocol = { AppleScriptRunner() }
    public var launchdFactory: () -> any LaunchdServiceProtocol = { LaunchdService() }
    public var cacheFactory: () -> any CacheServiceProtocol = { CacheService() }
    public var markdownExporterFactory: () -> any MarkdownExporterProtocol = { MarkdownExporter() }
    public var triggerFactory: () -> any TriggerServiceProtocol = { TriggerService() }
    public var dateParserFactory: () -> any DateParserProtocol = { DateParser() }
    public var clipboardFactory: () -> any ClipboardServiceProtocol = { ClipboardService() }
    public var systemFactory: () -> any SystemServiceProtocol = { SystemService() }
    public var speechFactory: () -> any SpeechServiceProtocol = { SpeechService() }

    // MARK: - Cached Instances

    private var _calendar: (any CalendarServiceProtocol)?
    private var _reminders: (any ReminderServiceProtocol)?
    private var _contacts: (any ContactsServiceProtocol)?
    private var _photos: (any PhotosServiceProtocol)?
    private var _notes: (any NotesServiceProtocol)?
    private var _mail: (any MailServiceProtocol)?
    private var _messages: (any MessagesServiceProtocol)?
    private var _music: (any MusicServiceProtocol)?
    private var _focus: (any FocusServiceProtocol)?
    private var _safari: (any SafariServiceProtocol)?
    private var _tags: (any TagsServiceProtocol)?
    private var _spotlight: (any SpotlightServiceProtocol)?
    private var _shortcuts: (any ShortcutsServiceProtocol)?
    private var _workflow: (any WorkflowEngineProtocol)?
    private var _plugins: (any PluginManagerProtocol)?
    private var _weather: (any WeatherServiceProtocol)?
    private var _weatherKit: (any WeatherServiceProtocol)?
    private var _scriptRunner: (any ScriptRunnerProtocol)?
    private var _appleScriptRunner: (any AppleScriptRunnerProtocol)?
    private var _launchd: (any LaunchdServiceProtocol)?
    private var _cache: (any CacheServiceProtocol)?
    private var _markdownExporter: (any MarkdownExporterProtocol)?
    private var _trigger: (any TriggerServiceProtocol)?
    private var _dateParser: (any DateParserProtocol)?
    private var _clipboard: (any ClipboardServiceProtocol)?
    private var _system: (any SystemServiceProtocol)?
    private var _speech: (any SpeechServiceProtocol)?

    // MARK: - Service Accessors

    public func calendar() -> any CalendarServiceProtocol {
        lock.lock()
        defer { lock.unlock() }
        if _calendar == nil { _calendar = calendarFactory() }
        return _calendar!
    }

    public func reminders() -> any ReminderServiceProtocol {
        lock.lock()
        defer { lock.unlock() }
        if _reminders == nil { _reminders = reminderFactory() }
        return _reminders!
    }

    public func contacts() -> any ContactsServiceProtocol {
        lock.lock()
        defer { lock.unlock() }
        if _contacts == nil { _contacts = contactsFactory() }
        return _contacts!
    }

    public func photos() -> any PhotosServiceProtocol {
        lock.lock()
        defer { lock.unlock() }
        if _photos == nil { _photos = photosFactory() }
        return _photos!
    }

    public func notes() -> any NotesServiceProtocol {
        lock.lock()
        defer { lock.unlock() }
        if _notes == nil { _notes = notesFactory() }
        return _notes!
    }

    public func mail() -> any MailServiceProtocol {
        lock.lock()
        defer { lock.unlock() }
        if _mail == nil { _mail = mailFactory() }
        return _mail!
    }

    public func messages() -> any MessagesServiceProtocol {
        lock.lock()
        defer { lock.unlock() }
        if _messages == nil { _messages = messagesFactory() }
        return _messages!
    }

    public func music() -> any MusicServiceProtocol {
        lock.lock()
        defer { lock.unlock() }
        if _music == nil { _music = musicFactory() }
        return _music!
    }

    public func focus() -> any FocusServiceProtocol {
        lock.lock()
        defer { lock.unlock() }
        if _focus == nil { _focus = focusFactory() }
        return _focus!
    }

    public func safari() -> any SafariServiceProtocol {
        lock.lock()
        defer { lock.unlock() }
        if _safari == nil { _safari = safariFactory() }
        return _safari!
    }

    public func tags() -> any TagsServiceProtocol {
        lock.lock()
        defer { lock.unlock() }
        if _tags == nil { _tags = tagsFactory() }
        return _tags!
    }

    public func spotlight() -> any SpotlightServiceProtocol {
        lock.lock()
        defer { lock.unlock() }
        if _spotlight == nil { _spotlight = spotlightFactory() }
        return _spotlight!
    }

    public func shortcuts() -> any ShortcutsServiceProtocol {
        lock.lock()
        defer { lock.unlock() }
        if _shortcuts == nil { _shortcuts = shortcutsFactory() }
        return _shortcuts!
    }

    public func workflow() -> any WorkflowEngineProtocol {
        lock.lock()
        defer { lock.unlock() }
        if _workflow == nil { _workflow = workflowFactory() }
        return _workflow!
    }

    public func plugins() -> any PluginManagerProtocol {
        lock.lock()
        defer { lock.unlock() }
        if _plugins == nil { _plugins = pluginFactory() }
        return _plugins!
    }

    public func weather() -> any WeatherServiceProtocol {
        lock.lock()
        defer { lock.unlock() }
        if _weather == nil { _weather = weatherFactory() }
        return _weather!
    }

    public func weatherKit() -> any WeatherServiceProtocol {
        lock.lock()
        defer { lock.unlock() }
        if _weatherKit == nil { _weatherKit = weatherKitFactory() }
        return _weatherKit!
    }

    public func scriptRunner() -> any ScriptRunnerProtocol {
        lock.lock()
        defer { lock.unlock() }
        if _scriptRunner == nil { _scriptRunner = scriptRunnerFactory() }
        return _scriptRunner!
    }

    public func appleScriptRunner() -> any AppleScriptRunnerProtocol {
        lock.lock()
        defer { lock.unlock() }
        if _appleScriptRunner == nil { _appleScriptRunner = appleScriptRunnerFactory() }
        return _appleScriptRunner!
    }

    public func launchd() -> any LaunchdServiceProtocol {
        lock.lock()
        defer { lock.unlock() }
        if _launchd == nil { _launchd = launchdFactory() }
        return _launchd!
    }

    public func cache() -> any CacheServiceProtocol {
        lock.lock()
        defer { lock.unlock() }
        if _cache == nil { _cache = cacheFactory() }
        return _cache!
    }

    public func markdownExporter() -> any MarkdownExporterProtocol {
        lock.lock()
        defer { lock.unlock() }
        if _markdownExporter == nil { _markdownExporter = markdownExporterFactory() }
        return _markdownExporter!
    }

    public func trigger() -> any TriggerServiceProtocol {
        lock.lock()
        defer { lock.unlock() }
        if _trigger == nil { _trigger = triggerFactory() }
        return _trigger!
    }

    public func dateParser() -> any DateParserProtocol {
        lock.lock()
        defer { lock.unlock() }
        if _dateParser == nil { _dateParser = dateParserFactory() }
        return _dateParser!
    }

    public func clipboard() -> any ClipboardServiceProtocol {
        lock.lock()
        defer { lock.unlock() }
        if _clipboard == nil { _clipboard = clipboardFactory() }
        return _clipboard!
    }

    public func system() -> any SystemServiceProtocol {
        lock.lock()
        defer { lock.unlock() }
        if _system == nil { _system = systemFactory() }
        return _system!
    }

    public func speech() -> any SpeechServiceProtocol {
        lock.lock()
        defer { lock.unlock() }
        if _speech == nil { _speech = speechFactory() }
        return _speech!
    }

    // MARK: - Test Support

    /// Reset all factories to their default implementations and clear cached instances.
    /// Call this in test teardown to ensure clean state.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }

        // Reset factories
        calendarFactory = { CalendarService() }
        reminderFactory = { ReminderService() }
        contactsFactory = { ContactsService() }
        photosFactory = { PhotosService() }
        notesFactory = { NotesService() }
        mailFactory = { MailService() }
        messagesFactory = { MessagesService() }
        musicFactory = { MusicService() }
        focusFactory = { FocusService() }
        safariFactory = { SafariService() }
        tagsFactory = { TagsService() }
        spotlightFactory = { SpotlightService() }
        shortcutsFactory = { ShortcutsService() }
        workflowFactory = { WorkflowEngine() }
        pluginFactory = { PluginManager() }
        weatherFactory = { WeatherService() }
        weatherKitFactory = { WeatherKitService() }
        scriptRunnerFactory = { ScriptRunner() }
        appleScriptRunnerFactory = { AppleScriptRunner() }
        launchdFactory = { LaunchdService() }
        cacheFactory = { CacheService() }
        markdownExporterFactory = { MarkdownExporter() }
        triggerFactory = { TriggerService() }
        dateParserFactory = { DateParser() }
        clipboardFactory = { ClipboardService() }
        systemFactory = { SystemService() }
        speechFactory = { SpeechService() }

        // Clear cached instances
        _clearCacheUnsafe()
    }

    /// Clear all cached service instances without resetting factories.
    /// Useful when you want services to be recreated on next access.
    public func clearCache() {
        lock.lock()
        defer { lock.unlock() }
        _clearCacheUnsafe()
    }

    private func _clearCacheUnsafe() {
        _calendar = nil
        _reminders = nil
        _contacts = nil
        _photos = nil
        _notes = nil
        _mail = nil
        _messages = nil
        _music = nil
        _focus = nil
        _safari = nil
        _tags = nil
        _spotlight = nil
        _shortcuts = nil
        _workflow = nil
        _plugins = nil
        _weather = nil
        _weatherKit = nil
        _scriptRunner = nil
        _appleScriptRunner = nil
        _launchd = nil
        _cache = nil
        _markdownExporter = nil
        _trigger = nil
        _dateParser = nil
        _clipboard = nil
        _system = nil
        _speech = nil
    }

    private init() {}
}

/// Convenience accessor for the shared service container
public let Services = ServiceContainer.shared
