import Foundation

/// Global service container for dependency injection.
/// Allows test substitution via factory pattern.
final class ServiceContainer: @unchecked Sendable {
    static let shared = ServiceContainer()

    // MARK: - Service Factories

    var calendarFactory: () -> any CalendarServiceProtocol = { CalendarService() }
    var reminderFactory: () -> any ReminderServiceProtocol = { ReminderService() }
    var contactsFactory: () -> any ContactsServiceProtocol = { ContactsService() }
    var photosFactory: () -> any PhotosServiceProtocol = { PhotosService() }
    var notesFactory: () -> any NotesServiceProtocol = { NotesService() }
    var mailFactory: () -> any MailServiceProtocol = { MailService() }
    var messagesFactory: () -> any MessagesServiceProtocol = { MessagesService() }
    var musicFactory: () -> any MusicServiceProtocol = { MusicService() }
    var focusFactory: () -> any FocusServiceProtocol = { FocusService() }
    var safariFactory: () -> any SafariServiceProtocol = { SafariService() }
    var tagsFactory: () -> any TagsServiceProtocol = { TagsService() }
    var spotlightFactory: () -> any SpotlightServiceProtocol = { SpotlightService() }
    var shortcutsFactory: () -> any ShortcutsServiceProtocol = { ShortcutsService() }
    var workflowFactory: () -> any WorkflowEngineProtocol = { WorkflowEngine() }
    var pluginFactory: () -> any PluginManagerProtocol = { PluginManager() }
    var weatherFactory: () -> any WeatherServiceProtocol = { WeatherService() }
    var weatherKitFactory: () -> any WeatherServiceProtocol = { WeatherKitService() }

    // MARK: - Service Accessors

    func calendar() -> any CalendarServiceProtocol { calendarFactory() }
    func reminders() -> any ReminderServiceProtocol { reminderFactory() }
    func contacts() -> any ContactsServiceProtocol { contactsFactory() }
    func photos() -> any PhotosServiceProtocol { photosFactory() }
    func notes() -> any NotesServiceProtocol { notesFactory() }
    func mail() -> any MailServiceProtocol { mailFactory() }
    func messages() -> any MessagesServiceProtocol { messagesFactory() }
    func music() -> any MusicServiceProtocol { musicFactory() }
    func focus() -> any FocusServiceProtocol { focusFactory() }
    func safari() -> any SafariServiceProtocol { safariFactory() }
    func tags() -> any TagsServiceProtocol { tagsFactory() }
    func spotlight() -> any SpotlightServiceProtocol { spotlightFactory() }
    func shortcuts() -> any ShortcutsServiceProtocol { shortcutsFactory() }
    func workflow() -> any WorkflowEngineProtocol { workflowFactory() }
    func plugins() -> any PluginManagerProtocol { pluginFactory() }
    func weather() -> any WeatherServiceProtocol { weatherFactory() }
    func weatherKit() -> any WeatherServiceProtocol { weatherKitFactory() }

    // MARK: - Test Support

    /// Reset all factories to their default implementations.
    /// Call this in test teardown to ensure clean state.
    func reset() {
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
    }

    private init() {}
}

/// Convenience accessor for the shared service container
let Services = ServiceContainer.shared
