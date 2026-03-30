import ArgumentParser
import Foundation
import SysmCore

@main
struct Sysm: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sysm",
        abstract: "Unified Apple ecosystem CLI",
        version: appVersion,
        subcommands: [
            AICommand.self,
            AppStoreCommand.self,
            AudioCommand.self,
            AVCommand.self,
            BluetoothCommand.self,
            BooksCommand.self,
            CalendarCommand.self,
            CaptureCommand.self,
            ClipboardCommand.self,
            CompletionsCommand.self,
            ContactsCommand.self,
            DiskCommand.self,
            ExecCommand.self,
            FinderCommand.self,
            FocusCommand.self,
            GeoCommand.self,
            ImageCommand.self,
            KeychainCommand.self,
            LanguageCommand.self,
            MailCommand.self,
            MessagesCommand.self,
            MusicCommand.self,
            NetworkCommand.self,
            NotesCommand.self,
            NotifyCommand.self,
            OutlookCommand.self,
            PDFCommand.self,
            PhotosCommand.self,
            PluginCommand.self,
            PodcastsCommand.self,
            RemindersCommand.self,
            SafariCommand.self,
            ScheduleCommand.self,
            ShortcutsCommand.self,
            SlackCommand.self,
            SpeakCommand.self,
            SpotlightCommand.self,
            SystemCommand.self,
            TagsCommand.self,
            TimeMachineCommand.self,
            UpdateCommand.self,
            VisionCommand.self,
            VMCommand.self,
            WeatherCommand.self,
            WorkflowCommand.self,
        ]
    )
}
