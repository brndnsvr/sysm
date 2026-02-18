import ArgumentParser
import Foundation
import SysmCore

struct UpdateCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update sysm to the latest version"
    )

    @Flag(name: .long, help: "Check for updates without installing")
    var check = false

    @Flag(name: .long, help: "Output as JSON")
    var json = false

    func run() throws {
        let service = Services.update()

        if check {
            let result = try service.checkForUpdate(currentVersion: appVersion)

            if json {
                try OutputFormatter.printJSON(result)
            } else {
                if result.updateAvailable {
                    print("Current version: \(result.currentVersion)")
                    print("Latest version:  \(result.latestVersion)")
                    print("")
                    print("Update available! Run 'sysm update' to install.")
                } else {
                    print("Already up to date (\(result.currentVersion))")
                }
            }
        } else {
            let checkResult = try service.checkForUpdate(currentVersion: appVersion)

            if !checkResult.updateAvailable {
                if json {
                    try OutputFormatter.printJSON(checkResult)
                } else {
                    print("Already up to date (\(checkResult.currentVersion))")
                }
                return
            }

            if !json {
                print("Updating sysm \(checkResult.currentVersion) → \(checkResult.latestVersion)...")
            }

            let result = try service.performUpdate(currentVersion: appVersion)

            if json {
                try OutputFormatter.printJSON(result)
            } else {
                let arch = try SysmCore.Shell.run("/usr/bin/uname", args: ["-m"])
                let archStr = arch == "arm64" ? "arm64" : "x86_64"
                print("Downloaded sysm-\(result.newVersion)-macos-\(archStr).tar.gz")
                print("Updated successfully: \(result.previousVersion) → \(result.newVersion)")
                print("")
                // Print version confirmation
                let versionOutput = try SysmCore.Shell.run(result.binaryPath, args: ["--version"])
                print(versionOutput)
            }
        }
    }
}
