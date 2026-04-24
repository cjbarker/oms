import Foundation

/// On-device GGUF backend. Loads Gemma 3 E4B Q4_K_M via the `llama.cpp` Swift Package.
///
/// The `llama` dependency is declared but commented out in `project.yml` so a fresh checkout
/// builds without network access. To enable on-device inference:
///
/// 1. Uncomment the `llama` dependency block in `project.yml` under the OMS target.
/// 2. Re-run `xcodegen generate`.
/// 3. Remove the `#if false` guard in this file.
///
/// Until the dependency is wired in, `generate` throws `.unavailable` and the UI routes the
/// user to the Remote backend via `LLMRouter`.
final class LocalLLMClient: LLMBackend {
    let mode: LLMBackendMode = .local
    let visionSupported: Bool = false

    private var warmed = false

    func generate(_ request: LLMRequest) async throws -> String {
        guard LLMConfig.isLocalModelPresent else { throw LLMError.modelMissing }
        if !request.messages.allSatisfy({ $0.content.allSatisfy { if case .text = $0 { return true } else { return false } } }) {
            throw LLMError.vision_unsupported
        }

        #if false // Enable after wiring in the `llama` Swift Package (see header docstring).
        try await warmUpIfNeeded()
        let prompt = Self.buildGemmaPrompt(system: request.system, messages: request.messages)
        let output = try await Self.runLlamaInference(
            modelPath: LLMConfig.localFileURL.path,
            prompt: prompt,
            maxTokens: request.maxTokens,
            temperature: request.temperature
        )
        return output
        #else
        throw LLMError.unavailable(
            "On-device Gemma is not built into this copy of OMS. See README → 'On-device model' to enable it."
        )
        #endif
    }

    /// Formats messages using Gemma 3's chat template (`<start_of_turn>user ... <end_of_turn>`).
    static func buildGemmaPrompt(system: String?, messages: [LLMMessage]) -> String {
        var out = ""
        if let system, !system.isEmpty {
            out += "<start_of_turn>system\n\(system)<end_of_turn>\n"
        }
        for m in messages {
            let role = (m.role == .assistant) ? "model" : "user"
            let text = m.content.compactMap { part -> String? in
                if case .text(let t) = part { return t } else { return nil }
            }.joined(separator: "\n")
            out += "<start_of_turn>\(role)\n\(text)<end_of_turn>\n"
        }
        out += "<start_of_turn>model\n"
        return out
    }

    // MARK: - Bindings (enabled once the llama.cpp SPM dependency is wired in)
    #if false
    private func warmUpIfNeeded() async throws {
        guard !warmed else { return }
        warmed = true
        // llama_backend_init()
        // _ = LlamaContext.load(path: LLMConfig.localFileURL.path)
    }

    static func runLlamaInference(modelPath: String, prompt: String,
                                  maxTokens: Int, temperature: Double) async throws -> String {
        // Replace with real llama.cpp Swift bindings once the package is wired in.
        throw LLMError.unavailable("Inference bindings not wired up.")
    }
    #endif
}
