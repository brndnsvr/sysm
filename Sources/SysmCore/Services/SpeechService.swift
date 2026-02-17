import AppKit
import Foundation

public struct SpeechService: SpeechServiceProtocol {
    public init() {}

    public func listVoices() -> [VoiceInfo] {
        NSSpeechSynthesizer.availableVoices.map { voiceId in
            let attrs = NSSpeechSynthesizer.attributes(forVoice: voiceId)
            let name = attrs[.name] as? String ?? voiceId.rawValue
            let language = attrs[.localeIdentifier] as? String ?? "unknown"
            return VoiceInfo(name: name, language: language, identifier: voiceId.rawValue)
        }
    }

    public func speak(text: String, voice: String? = nil, rate: Float? = nil) throws {
        let synth = NSSpeechSynthesizer()

        if let voice = voice {
            let voiceId = resolveVoice(voice)
            synth.setVoice(voiceId)
        }

        if let rate = rate {
            synth.rate = rate
        }

        guard synth.startSpeaking(text) else {
            throw SpeechError.speakFailed
        }

        // Block until speech finishes
        while synth.isSpeaking {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }
    }

    public func save(text: String, voice: String? = nil, rate: Float? = nil, outputPath: String) throws {
        let synth = NSSpeechSynthesizer()

        if let voice = voice {
            let voiceId = resolveVoice(voice)
            synth.setVoice(voiceId)
        }

        if let rate = rate {
            synth.rate = rate
        }

        let url = URL(fileURLWithPath: (outputPath as NSString).expandingTildeInPath)
        guard synth.startSpeaking(text, to: url) else {
            throw SpeechError.saveFailed(outputPath)
        }

        while synth.isSpeaking {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }
    }

    // MARK: - Private

    private func resolveVoice(_ name: String) -> NSSpeechSynthesizer.VoiceName {
        // Try exact match first
        let voices = NSSpeechSynthesizer.availableVoices
        if let exact = voices.first(where: {
            let attrs = NSSpeechSynthesizer.attributes(forVoice: $0)
            return (attrs[.name] as? String)?.lowercased() == name.lowercased()
        }) {
            return exact
        }
        // Fall back to identifier-based lookup
        return NSSpeechSynthesizer.VoiceName(rawValue: name)
    }
}

public enum SpeechError: LocalizedError {
    case speakFailed
    case saveFailed(String)

    public var errorDescription: String? {
        switch self {
        case .speakFailed:
            return "Failed to speak text"
        case .saveFailed(let path):
            return "Failed to save speech to: \(path)"
        }
    }
}
