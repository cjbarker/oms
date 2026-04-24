import Foundation
import AVFoundation

/// Optional text-to-speech coach. Off by default; gated by LLMConfig.Keys.ttsEnabled.
@MainActor
final class SpeechService: NSObject, ObservableObject {
    static let shared = SpeechService()
    private let synth = AVSpeechSynthesizer()

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: LLMConfig.Keys.ttsEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: LLMConfig.Keys.ttsEnabled) }
    }

    var voiceIdentifier: String? {
        get { UserDefaults.standard.string(forKey: LLMConfig.Keys.ttsVoice) }
        set { UserDefaults.standard.set(newValue, forKey: LLMConfig.Keys.ttsVoice) }
    }

    var availableVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("en") }
    }

    func speak(_ text: String) {
        guard isEnabled, !text.isEmpty else { return }
        let utt = AVSpeechUtterance(string: text)
        if let id = voiceIdentifier, let v = AVSpeechSynthesisVoice(identifier: id) {
            utt.voice = v
        } else {
            utt.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        utt.rate = AVSpeechUtteranceDefaultSpeechRate * 1.05
        synth.speak(utt)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
    }
}
