import Foundation

final class EquipmentAnalyzer {
    private let router: LLMRouter

    init(router: LLMRouter = .shared) { self.router = router }

    func analyze(imageData: Data, mime: String = "image/jpeg") async throws -> [EquipmentType] {
        guard router.visionSupported else {
            throw LLMError.vision_unsupported
        }
        let req = LLMRequest(
            system: EquipmentPrompt.system,
            messages: [.userWithImage(EquipmentPrompt.userInstruction, image: imageData, mime: mime)],
            maxTokens: 600,
            temperature: 0.1
        )
        let raw = try await router.generate(req)
        return try Self.parse(raw)
    }

    static func parse(_ raw: String) throws -> [EquipmentType] {
        let json = JSONExtractor.extract(raw)
        guard let data = json.data(using: .utf8) else {
            throw LLMError.decoding("Empty response.")
        }
        let decoded: DetectedEquipmentResponse
        do {
            decoded = try JSONDecoder().decode(DetectedEquipmentResponse.self, from: data)
        } catch {
            throw LLMError.decoding("Could not decode equipment JSON: \(error.localizedDescription)")
        }
        return decoded.detected.compactMap(EquipmentType.init(rawValue:))
    }
}
