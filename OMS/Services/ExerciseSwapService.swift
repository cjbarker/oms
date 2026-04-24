import Foundation

final class ExerciseSwapService {
    enum Reason: String, CaseIterable, Identifiable {
        case pain
        case equipmentBusy
        case tooEasy
        case tooHard
        case other
        var id: String { rawValue }
        var label: String {
            switch self {
            case .pain:           return "Hurts / discomfort"
            case .equipmentBusy:  return "Equipment occupied"
            case .tooEasy:        return "Too easy"
            case .tooHard:        return "Too hard"
            case .other:          return "Other"
            }
        }
    }

    private let router: LLMRouter
    private let catalog: ExerciseCatalogService

    init(router: LLMRouter = .shared, catalog: ExerciseCatalogService = .shared) {
        self.router = router
        self.catalog = catalog
    }

    func swap(item: RoutineItem, reason: Reason,
              profile: UserProfile, owned: [EquipmentType]) async -> String? {
        // Try LLM first if ready.
        if router.isReady,
           let id = try? await askLLM(item: item, reason: reason, profile: profile, owned: owned) {
            return id
        }
        // Deterministic fallback — pick another exercise in the same category using only owned gear.
        guard let current = catalog.exercise(id: item.exerciseId) else { return nil }
        let ownedSet = Set(owned)
        let candidates = catalog.all(matching: current.category, owned: ownedSet)
            .filter { $0.id != current.id && $0.pattern == current.pattern }
        return candidates.first?.id ?? catalog.all(matching: current.category, owned: ownedSet)
            .first(where: { $0.id != current.id })?.id
    }

    private func askLLM(item: RoutineItem, reason: Reason,
                        profile: UserProfile, owned: [EquipmentType]) async throws -> String? {
        let availableIds = catalog.availableIds(owned: Set(owned))
        let current = catalog.exercise(id: item.exerciseId)
        let currentStr = current.map { "\($0.id) (\($0.name), \($0.category.label), pattern: \($0.pattern.rawValue))" } ?? item.exerciseId

        let system = """
        Replace a single exercise with a safe, equivalent alternative from a fixed catalog.
        Respect the user's limitations. Match the same movement pattern where possible.
        Respond ONLY with JSON: {"exerciseId": "..."} wrapped in ```json fences.
        """
        let limsLine = profile.limitations.map { $0.note.map { "\($0.tag): \($0)" } ?? $0.tag }.joined(separator: "; ")
        let user = """
        CURRENT EXERCISE: \(currentStr)
        REASON FOR SWAP: \(reason.label)
        USER LIMITATIONS: \(limsLine.isEmpty ? "none" : limsLine)
        CATALOG (pick one id): \(availableIds.joined(separator: ", "))
        """

        let req = LLMRequest(system: system, messages: [.user(user)], maxTokens: 200, temperature: 0.3)
        let raw = try await router.generate(req)
        let json = JSONExtractor.extract(raw)
        guard let data = json.data(using: .utf8),
              let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let id = obj["exerciseId"] as? String,
              catalog.exercise(id: id) != nil else {
            return nil
        }
        return id
    }
}
