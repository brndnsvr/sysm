import ArgumentParser
import Foundation

struct PluginCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "plugin",
        abstract: "Extend sysm with custom commands",
        discussion: """
        Install, manage, and run custom plugins that add new commands to sysm.

        Plugins are stored in ~/.sysm/plugins/ and consist of:
        - plugin.yaml: Manifest defining commands and arguments
        - Scripts: Executable scripts for each command

        Examples:
          sysm plugin list
          sysm plugin create my-tools
          sysm plugin run my-tools hello --name "World"
          sysm plugin install ./my-plugin
          sysm plugin remove my-tools
        """,
        subcommands: [
            PluginList.self,
            PluginCreate.self,
            PluginInstall.self,
            PluginRemove.self,
            PluginRun.self,
            PluginInfo.self,
        ]
    )
}
