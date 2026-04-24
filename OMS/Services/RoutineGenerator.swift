import Foundation
import SwiftData

/// Top-level orchestrator that turns a profile + health snapshot into a persisted Routine.
final class RoutineGenerator {
    private let router: LLMRouter
    private let catalog: ExerciseCatalogService

    init(router: LLMRouter = .shared,
         catalog: ExerciseCatalogService = .shared) {
        self.router = router
        self.catalog = catalog
    }

    func generate(
        for profile: UserProfile,
        snapshot: HealthSnapshot,
        owned: [EquipmentType],
        recent: [RoutinePromptInput.RecentSession],
        focusHint: String? = nil
    ) async throws -> Routine {
        let input = RoutinePromptInput(
            profile: profile,
            snapshot: snapshot,
            ownedEquipment: owned,
            recentHistory: recent,
            persona: profile.coachPersona,
            todaysFocusHint: focusHint
        )

        let availableIds = catalog.availableIds(owned: Set(owned))
        let system = RoutinePrompt.system(for: profile.coachPersona)
        let user   = RoutinePrompt.user(input, availableIds: availableIds)

        let req = LLMRequest(
            system: system,
            messages: [.user(user)],
            maxTokens: 2400,
            temperature: 0.5
        )
        let raw = try await router.generate(req)
        let parsed = try Self.parse(raw, availableIds: Set(availableIds))
        return Self.persist(parsed)
    }

    /// Simple deterministic fallback when no backend is configured or the call fails.
    /// Picks a bodyweight-forward rotation from the catalog.
    func fallback(for profile: UserProfile, owned: [EquipmentType]) -> Routine {
        let ownedSet = Set(owned)
        let strength = catalog.all(matching: .strength, owned: ownedSet).prefix(3)
        let core = catalog.all(matching: .core, owned: ownedSet).prefix(1)
        let mobility = catalog.all(matching: .mobility, owned: ownedSet).prefix(1)

        var items: [RoutineItem] = []
        var order = 0
        for e in strength {
            items.append(RoutineItem(exerciseId: e.id, order: order, targetSets: 3, targetReps: "8-10", restSec: 90))
            order += 1
        }
        for e in core {
            items.append(RoutineItem(exerciseId: e.id, order: order, targetSets: 3, targetReps: "30s", restSec: 45))
            order += 1
        }
        for e in mobility {
            items.append(RoutineItem(exerciseId: e.id, order: order, targetSets: 2, targetReps: "45s", restSec: 20))
            order += 1
        }
        return Routine(
            date: Date(),
            focus: "Full body — no-key fallback",
            rationale: "Built from the on-device catalog because no LLM backend is configured yet.",
            notes: "Add an API key or download the on-device model in Settings for tailored sessions.",
            generatedBy: .fallback,
            items: items
        )
    }

    // MARK: - Parsing

    static func parse(_ raw: String, availableIds: Set<String>) throws -> GeneratedRoutine {
        let json = JSONExtractor.extract(raw)
        guard let data = json.data(using: .utf8) else {
            throw LLMError.decoding("Empty response.")
        }
        let decoded: GeneratedRoutine
        do {
            decoded = try JSONDecoder().decode(GeneratedRoutine.self, from: data)
        } catch {
            throw LLMError.decoding("Could not decode routine JSON: \(error.localizedDescription)")
        }
        let filtered = decoded.items.filter { availableIds.contains($0.exerciseId) }
        guard !filtered.isEmpty else {
            throw LLMError.decoding("Model returned no recognisable exercise ids.")
        }
        var cleaned = decoded
        cleaned.items = filtered
        return cleaned
    }

    static func persist(_ g: GeneratedRoutine) -> Routine {
        let items: [RoutineItem] = g.items.enumerated().map { idx, i in
            let structure = SetStructure(rawValue: i.structure ?? "straight") ?? .straight
            return RoutineItem(
                exerciseId: i.exerciseId,
                order: idx,
                targetSets: max(1, i.sets),
                targetReps: i.reps,
                restSec: max(0, i.restSec),
                tempo: i.tempo,
                groupId: i.group,
                structure: structure,
                coachLine: i.coachLine
            )
        }
        return Routine(
            date: Date(),
            focus: g.focus,
            rationale: g.rationale,
            notes: g.coachIntro ?? "",
            generatedBy: .auto,
            items: items
        )
    }
}
