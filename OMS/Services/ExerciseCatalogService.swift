import Foundation

/// Loads the bundled exercise catalog once and serves lookups.
final class ExerciseCatalogService {
    static let shared = ExerciseCatalogService()

    let exercises: [Exercise]
    private let byId: [String: Exercise]

    init(bundle: Bundle = .main) {
        let decoder = JSONDecoder()
        let loaded: [Exercise]
        if let url = bundle.url(forResource: "ExerciseCatalog", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let parsed = try? decoder.decode([Exercise].self, from: data) {
            loaded = parsed
        } else {
            // Last-resort fallback so the app boots even without the resource.
            loaded = []
        }
        self.exercises = loaded
        self.byId = Dictionary(uniqueKeysWithValues: loaded.map { ($0.id, $0) })
    }

    func exercise(id: String) -> Exercise? { byId[id] }

    func all(matching category: ExerciseCategory? = nil,
             owned: Set<EquipmentType> = []) -> [Exercise] {
        exercises.filter { e in
            (category == nil || e.category == category!) && e.isAvailable(given: owned)
        }
    }

    /// Comma-separated list of ids appropriate for current equipment — used in LLM prompts.
    func availableIds(owned: Set<EquipmentType>) -> [String] {
        exercises.filter { $0.isAvailable(given: owned) }.map(\.id)
    }
}
