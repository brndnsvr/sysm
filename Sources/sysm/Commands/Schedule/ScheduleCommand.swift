import ArgumentParser
import Foundation
import SysmCore

struct ScheduleCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "schedule",
        abstract: "Schedule recurring tasks using macOS launchd",
        discussion: """
        Create, manage, and monitor scheduled jobs that run automatically.
        Jobs are managed via macOS launchd and persist across reboots.

        Schedule formats:
          --cron "M H D Mo W"    Cron syntax (minute hour day month weekday)
          --every N              Run every N seconds

        Examples:
          sysm schedule add backup --cron "0 2 * * *" --cmd "sysm workflow run backup.yaml"
          sysm schedule add sync --every 3600 --cmd "sysm reminders sync"
          sysm schedule list
          sysm schedule logs backup
          sysm schedule remove backup
        """,
        subcommands: [
            ScheduleAdd.self,
            ScheduleList.self,
            ScheduleShow.self,
            ScheduleRemove.self,
            ScheduleEnable.self,
            ScheduleDisable.self,
            ScheduleRun.self,
            ScheduleLogs.self,
        ]
    )
}
