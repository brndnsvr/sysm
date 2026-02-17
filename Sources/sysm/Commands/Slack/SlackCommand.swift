import ArgumentParser

struct SlackCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "slack",
        abstract: "Slack messaging and status",
        subcommands: [
            SlackAuth.self,
            SlackSend.self,
            SlackStatus.self,
            SlackChannels.self,
        ]
    )
}
