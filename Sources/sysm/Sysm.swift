import ArgumentParser
import Foundation
import SysmCore

@main
struct Sysm: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sysm",
        abstract: "Unified Apple ecosystem CLI",
        version: "1.0.0",
        subcommands: [
            // Phase 1: Core PIM
            CalendarCommand.self,
            RemindersCommand.self,
            NotesCommand.self,
            // Phase 2: Extended Apple Apps
            ShortcutsCommand.self,
            SafariCommand.self,
            FocusCommand.self,
            ContactsCommand.self,
            MailCommand.self,
            MessagesCommand.self,
            // Phase 3: System Integration
            TagsCommand.self,
            SpotlightCommand.self,
            MusicCommand.self,
            PhotosCommand.self,
            // Phase 4: Automation
            ExecCommand.self,
            WorkflowCommand.self,
            ScheduleCommand.self,
            PluginCommand.self,
            // Phase 5: External APIs
            WeatherCommand.self,
            // Utilities
            CompletionsCommand.self,
        ]
    )
}
