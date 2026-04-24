import Foundation
import SwiftUI

enum LLMBackendMode: String, CaseIterable, Identifiable, Codable {
    case remote
    case local

    var id: String { rawValue }

    var label: String {
        switch self {
        case .remote: return "Remote (Claude API)"
        case .local:  return "On-device (Gemma 3 E4B)"
        }
    }

    var summary: String {
        switch self {
        case .remote: return "Best quality. Requires an API key. Routine inputs are sent to the configured endpoint."
        case .local:  return "Private. Nothing leaves your phone. Requires a ~3 GB model download and a recent iPhone."
        }
    }
}

/// Centralised LLM configuration, backed by UserDefaults via @AppStorage.
enum LLMConfig {
    enum Keys {
        static let mode             = "oms.llm.mode"
        static let remoteEndpoint   = "oms.llm.remote.endpoint"
        static let remoteModel      = "oms.llm.remote.model"
        static let localFileName    = "oms.llm.local.filename"
        static let localSourceURL   = "oms.llm.local.url"
        static let localExpectedSHA = "oms.llm.local.sha256"
        static let autoRegenerate   = "oms.routine.autoRegenerate"
        static let ttsEnabled       = "oms.tts.enabled"
        static let ttsVoice         = "oms.tts.voice"
    }

    static let defaultRemoteEndpoint = "https://api.anthropic.com/v1/messages"
    static let defaultRemoteModel    = "claude-sonnet-4-6"
    static let defaultLocalFileName  = "google_gemma-4-E4B-it-Q4_K_M.gguf"
    static let defaultLocalSourceURL = "https://huggingface.co/bartowski/google_gemma-4-E4B-it-GGUF/resolve/main/google_gemma-4-E4B-it-Q4_K_M.gguf"

    static var mode: LLMBackendMode {
        let raw = UserDefaults.standard.string(forKey: Keys.mode) ?? LLMBackendMode.remote.rawValue
        return LLMBackendMode(rawValue: raw) ?? .remote
    }

    static var remoteEndpoint: String {
        UserDefaults.standard.string(forKey: Keys.remoteEndpoint) ?? defaultRemoteEndpoint
    }

    static var remoteModel: String {
        UserDefaults.standard.string(forKey: Keys.remoteModel) ?? defaultRemoteModel
    }

    static var localFileName: String {
        UserDefaults.standard.string(forKey: Keys.localFileName) ?? defaultLocalFileName
    }

    static var localSourceURL: URL? {
        let s = UserDefaults.standard.string(forKey: Keys.localSourceURL) ?? defaultLocalSourceURL
        return URL(string: s)
    }

    /// Application Support path where the GGUF lives once downloaded.
    static var localFileURL: URL {
        let fm = FileManager.default
        let dir = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask,
                              appropriateFor: nil, create: true)
        let base = dir ?? fm.temporaryDirectory
        let modelsDir = base.appendingPathComponent("Models", isDirectory: true)
        try? fm.createDirectory(at: modelsDir, withIntermediateDirectories: true)
        return modelsDir.appendingPathComponent(localFileName)
    }

    static var isLocalModelPresent: Bool {
        FileManager.default.fileExists(atPath: localFileURL.path)
    }
}
