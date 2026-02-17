import Foundation

public struct PodcastShow: Codable, Sendable {
    public let name: String
    public let episodeCount: Int
    public let author: String?

    public init(name: String, episodeCount: Int, author: String?) {
        self.name = name
        self.episodeCount = episodeCount
        self.author = author
    }
}

public struct PodcastEpisode: Codable, Sendable {
    public let title: String
    public let showName: String?
    public let date: String?
    public let duration: String?
    public let played: Bool?

    public init(title: String, showName: String?, date: String?, duration: String?, played: Bool?) {
        self.title = title
        self.showName = showName
        self.date = date
        self.duration = duration
        self.played = played
    }
}
