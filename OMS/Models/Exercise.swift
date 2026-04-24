import Foundation

/// Static catalog entry loaded from ExerciseCatalog.json. Not persisted.
struct Exercise: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: ExerciseCategory
    let pattern: MovementPattern
    let bodyweight: Bool
    let equipment: [EquipmentType]
    let primaryMuscles: [String]
    let cues: [String]
    let youtubeSearch: String
    let youtubeId: String?

    /// Convenience — is this exercise doable given an equipment profile?
    func isAvailable(given owned: Set<EquipmentType>) -> Bool {
        if equipment.isEmpty { return true }
        return equipment.allSatisfy { owned.contains($0) }
    }
}

enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
    case strength
    case core
    case mobility
    case cardio

    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}

enum MovementPattern: String, Codable, CaseIterable {
    case horizontalPush
    case horizontalPull
    case verticalPush
    case verticalPull
    case squat
    case hinge
    case lunge
    case carry
    case core
    case rotation
    case locomotion
    case mobility
    case steadyStateCardio
    case intervalCardio
}
