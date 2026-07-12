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

    @Flag(name: .long, help: "Prompt securely for the app-specific password")
    var configure = false

    @Flag(name: .long, help: "Read the app-specific password from non-terminal stdin")
    var appPasswordStdin = false

    @Option(name: .long, help: "Read the app-specific password from an inherited file descriptor (3 or greater)")
    var appPasswordFd: Int?

    @Flag(name: .long, help: "Remove stored credentials")
    var remove = false

    @Flag(name: .long, help: "Show current auth status")
    var status = false

    func validate() throws {
        if status && remove {
            throw ValidationError("Choose only one operation: --status or --remove")
        }

        let sourceSelected = configure || appPasswordStdin || appPasswordFd != nil
        if (status || remove) && (sourceSelected || appleId != nil) {
            throw ValidationError("Credential input cannot be combined with --status or --remove")
        }
        if sourceSelected && appleId == nil {
            throw ValidationError("--apple-id is required when configuring CalDAV")
        }
        if appleId != nil && !sourceSelected {
            throw ValidationError("Select --configure, --app-password-stdin, or --app-password-fd")
        }

        _ = try secretSource()
    }

    func run() throws {
        try run(service: Services.caldav(), secretReader: SecretInputReader())
    }

    func run(
        service: any CalDAVServiceProtocol,
        secretReader: any SecretInputReading
    ) throws {
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
                print("  4. Run: sysm calendar caldav-auth --apple-id you@icloud.com --configure")
            }
            return
        }

        if remove {
            try service.removeCredentials()
            print("CalDAV credentials removed")
            return
        }

        guard let appleId, let source = try secretSource() else {
            if service.isConfigured() {
                print("CalDAV: configured")
            } else {
                print("CalDAV: not configured")
                print("")
                print("Usage: sysm calendar caldav-auth --apple-id you@icloud.com --configure")
                print("")
                print("To generate an app-specific password:")
                print("  1. Go to https://appleid.apple.com")
                print("  2. Sign-In and Security > App-Specific Passwords")
                print("  3. Generate a password for 'sysm'")
            }
            return
        }

        let appPassword = try secretReader.read(
            from: source,
            prompt: "CalDAV app-specific password: ",
            maximumBytes: 65_536
        )

        try service.setCredentials(appleID: appleId, appPassword: appPassword)
        print("CalDAV credentials saved to Keychain")
    }

    private func secretSource() throws -> SecretInputSource? {
        try CLI.secretSource(
            prompt: configure,
            standardInput: appPasswordStdin,
            fileDescriptor: appPasswordFd,
            defaultToPrompt: false,
            label: "CalDAV app-specific password"
        )
    }
}
