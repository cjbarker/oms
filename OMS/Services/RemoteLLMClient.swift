import Foundation

/// Talks to Anthropic's Messages API (or any compatible endpoint) directly from the device.
final class RemoteLLMClient: LLMBackend {
    let mode: LLMBackendMode = .remote
    let visionSupported: Bool = true

    private let session: URLSession
    private let endpointProvider: () -> String
    private let modelProvider: () -> String
    private let apiKeyProvider: () -> String?

    init(session: URLSession = .shared,
         endpointProvider: @escaping () -> String = { LLMConfig.remoteEndpoint },
         modelProvider: @escaping () -> String = { LLMConfig.remoteModel },
         apiKeyProvider: @escaping () -> String? = { KeychainService.loadAPIKey() }) {
        self.session = session
        self.endpointProvider = endpointProvider
        self.modelProvider = modelProvider
        self.apiKeyProvider = apiKeyProvider
    }

    func generate(_ request: LLMRequest) async throws -> String {
        guard let apiKey = apiKeyProvider(), !apiKey.isEmpty else {
            throw LLMError.notConfigured("Add your Anthropic API key in Settings to enable routine generation.")
        }
        guard let url = URL(string: endpointProvider()) else {
            throw LLMError.notConfigured("Invalid API endpoint URL.")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        urlRequest.httpBody = try encodeBody(for: request)

        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else {
            throw LLMError.http(0, "No HTTP response.")
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw LLMError.http(http.statusCode, body)
        }

        return try decodeText(from: data)
    }

    private func encodeBody(for request: LLMRequest) throws -> Data {
        var messages: [[String: Any]] = []
        for m in request.messages {
            guard m.role != .system else { continue } // system is top-level
            var parts: [[String: Any]] = []
            for part in m.content {
                switch part {
                case .text(let t):
                    parts.append(["type": "text", "text": t])
                case .image(let data, let mime):
                    parts.append([
                        "type": "image",
                        "source": [
                            "type": "base64",
                            "media_type": mime,
                            "data": data.base64EncodedString()
                        ]
                    ])
                }
            }
            messages.append(["role": m.role.rawValue, "content": parts])
        }
        var body: [String: Any] = [
            "model": modelProvider(),
            "max_tokens": request.maxTokens,
            "temperature": request.temperature,
            "messages": messages
        ]
        if let system = request.system { body["system"] = system }
        return try JSONSerialization.data(withJSONObject: body)
    }

    private func decodeText(from data: Data) throws -> String {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LLMError.decoding("Response was not JSON.")
        }
        if let content = root["content"] as? [[String: Any]] {
            let texts: [String] = content.compactMap { block in
                guard (block["type"] as? String) == "text" else { return nil }
                return block["text"] as? String
            }
            if !texts.isEmpty { return texts.joined(separator: "\n") }
        }
        // Fallback: OpenAI-style { choices: [{ message: { content: "..." } }] }
        if let choices = root["choices"] as? [[String: Any]],
           let first = choices.first,
           let msg = first["message"] as? [String: Any],
           let text = msg["content"] as? String {
            return text
        }
        throw LLMError.decoding("No text content in LLM response.")
    }
}
