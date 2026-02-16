import ArgumentParser
import SysmCore

struct MusicCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "music",
        abstract: "Control Music.app playback and library",
        subcommands: [
            MusicPlay.self,
            MusicPause.self,
            MusicNext.self,
            MusicPrev.self,
            MusicStatus.self,
            MusicVolume.self,
            MusicShuffle.self,
            MusicRepeat.self,
            MusicPlaylists.self,
            MusicPlayPlaylist.self,
            MusicPlayTrack.self,
            MusicPlayNext.self,
            MusicSearch.self,
        ]
    )
}
