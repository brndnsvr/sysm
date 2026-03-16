import ArgumentParser
import Foundation
import SysmCore

struct CalendarCaldavAuth: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "caldav-auth",
        abstract: "Configure CalDAV credentials for attendee invitations"
    )

    @Option(name: .long, help: "Apple ID email address")
    var appleId: String?

    @Option(name: .long, help: "App-specific password (generate at appleid.apple.com)")
    var appPassword: String?

    @Flag(name: .long, help: "Remove stored credentials")
    var remove = false

    @Flag(name: .long, help: "Show current auth status")
    var status = false

    func run() throws {
        let service = Services.caldav()

        if status {
            if service.isConfigured() {
                print("CalDAV: configured")
            } else {
                print("CalDAV: not configured")
                print("")
                print("Set up CalDAV to enable attendee invitations:")
                print("  1. Go to https://appleid.apple.com")
                print("  2. Sign-In and Security > App-Specific Passwords")
                print("  3. Generate a password for 'sysm'")
                print("  4. Run: sysm calendar caldav-auth --apple-id you@icloud.com --app-password xxxx-xxxx-xxxx-xxxx")
            }
            return
        }

        if remove {
            try service.removeCredentials()
            print("CalDAV credentials removed")
            return
        }

        guard let appleId = appleId, let appPassword = appPassword else {
            if service.isConfigured() {
                print("CalDAV: configured")
            } else {
                print("CalDAV: not configured")
                print("")
                print("Usage: sysm calendar caldav-auth --apple-id you@icloud.com --app-password xxxx-xxxx-xxxx-xxxx")
                print("")
                print("To generate an app-specific password:")
                print("  1. Go to https://appleid.apple.com")
                print("  2. Sign-In and Security > App-Specific Passwords")
                print("  3. Generate a password for 'sysm'")
            }
            return
        }

        try service.setCredentials(appleID: appleId, appPassword: appPassword)
        print("CalDAV credentials saved to Keychain")
    }
}
