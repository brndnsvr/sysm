import Foundation

public protocol SpeechServiceProtocol: Sendable {
    /// List available voice names.
    func listVoices() -> [VoiceInfo]

    /// Speak text aloud using the specified voice.
    func speak(text: String, voice: String?, rate: Float?) throws

    /// Save spoken text to an audio file.
    func save(text: String, voice: String?, rate: Float?, outputPath: String) throws
}
