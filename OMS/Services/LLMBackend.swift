import Foundation

/// A single message in a chat-style exchange.
struct LLMMessage: Codable, Equatable {
    enum Role: String, Codable { case system, user, assistant }
    enum Content: Equatable {
        case text(String)
        /// Raw image bytes + MIME type (e.g. "image/jpeg"). Only honored by vision-capable backends.
        case image(Data, mime: String)
    }
    var role: Role
    var content: [Content]

    static func user(_ text: String) -> LLMMessage {
        .init(role: .user, content: [.text(text)])
    }
    static func userWithImage(_ text: String, image: Data, mime: String = "image/jpeg") -> LLMMessage {
        .init(role: .user, content: [.text(text), .image(image, mime: mime)])
    }
    static func assistant(_ text: String) -> LLMMessage {
        .init(role: .assistant, content: [.text(text)])
    }
}

struct LLMRequest {
    var system: String?
    var messages: [LLMMessage]
    var maxTokens: Int = 2048
    var temperature: Double = 0.6
}

enum LLMError: Error, LocalizedError {
    case notConfigured(String)
    case vision_unsupported
    case http(Int, String)
    case decoding(String)
    case modelMissing
    case unavailable(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured(let m):   return m
        case .vision_unsupported:     return "The selected LLM backend does not support image input."
        case .http(let code, let m):  return "LLM request failed (\(code)): \(m)"
        case .decoding(let m):        return "LLM response was not in the expected format: \(m)"
        case .modelMissing:           return "The on-device model file is not present yet."
        case .unavailable(let m):     return m
        }
    }
}

/// Common surface implemented by both the remote and on-device backends.
protocol LLMBackend: AnyObject {
    var mode: LLMBackendMode { get }
    var visionSupported: Bool { get }
    func generate(_ request: LLMRequest) async throws -> String
}
