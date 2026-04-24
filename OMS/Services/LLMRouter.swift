import Foundation

/// Routes LLM calls to the backend selected in Settings.
final class LLMRouter: LLMBackend {
    static let shared = LLMRouter()

    private let remote: RemoteLLMClient
    private let local: LocalLLMClient

    init(remote: RemoteLLMClient = RemoteLLMClient(),
         local: LocalLLMClient = LocalLLMClient()) {
        self.remote = remote
        self.local = local
    }

    var mode: LLMBackendMode { LLMConfig.mode }

    var current: LLMBackend {
        switch LLMConfig.mode {
        case .remote: return remote
        case .local:  return local
        }
    }

    var visionSupported: Bool { current.visionSupported }

    func generate(_ request: LLMRequest) async throws -> String {
        try await current.generate(request)
    }

    /// True if the selected backend is ready to serve generate() calls right now.
    var isReady: Bool {
        switch LLMConfig.mode {
        case .remote:
            return !(KeychainService.loadAPIKey() ?? "").isEmpty
        case .local:
            return LLMConfig.isLocalModelPresent
        }
    }
}
