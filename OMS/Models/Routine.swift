import Foundation
import SwiftData

enum RoutineGeneratedBy: String, Codable {
    case auto
    case manual
    case fallback
}

enum SetStructure: String, Codable, CaseIterable {
    case straight
    case superset
    case circuit
    case emom
    case amrap

    var label: String {
        switch self {
        case .straight: return "Straight sets"
        case .superset: return "Superset"
        case .circuit:  return "Circuit"
        case .emom:     return "EMOM"
        case .amrap:    return "AMRAP"
        }
    }
}

@Model
final class Routine {
    var date: Date
    var focus: String
    var rationale: String
    var notes: String
    var generatedByRaw: String
    @Relationship(deleteRule: .cascade, inverse: \RoutineItem.routine)
    var items: [RoutineItem]

    init(date: Date = Date(), focus: String = "", rationale: String = "",
         notes: String = "", generatedBy: RoutineGeneratedBy = .auto,
         items: [RoutineItem] = []) {
        self.date = date
        self.focus = focus
        self.rationale = rationale
        self.notes = notes
        self.generatedByRaw = generatedBy.rawValue
        self.items = items
    }

    var generatedBy: RoutineGeneratedBy {
        RoutineGeneratedBy(rawValue: generatedByRaw) ?? .auto
    }
}

@Model
final class RoutineItem {
    var routine: Routine?
    var exerciseId: String
    var order: Int
    var targetSets: Int
    var targetReps: String
    var restSec: Int
    var tempo: String?
    var groupId: String?
    var structureRaw: String
    var coachLine: String?
    @Relationship(deleteRule: .cascade, inverse: \SetLog.item)
    var setLogs: [SetLog]

    init(exerciseId: String,
         order: Int,
         targetSets: Int = 3,
         targetReps: String = "8-10",
         restSec: Int = 90,
         tempo: String? = nil,
         groupId: String? = nil,
         structure: SetStructure = .straight,
         coachLine: String? = nil) {
        self.exerciseId = exerciseId
        self.order = order
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.restSec = restSec
        self.tempo = tempo
        self.groupId = groupId
        self.structureRaw = structure.rawValue
        self.coachLine = coachLine
        self.setLogs = []
    }

    var structure: SetStructure {
        get { SetStructure(rawValue: structureRaw) ?? .straight }
        set { structureRaw = newValue.rawValue }
    }

    var isComplete: Bool { setLogs.count >= targetSets }
}

@Model
final class SetLog {
    var item: RoutineItem?
    var setIndex: Int
    var weightKg: Double?
    var reps: Int
    var rpe: Double?
    var completedAt: Date

    init(setIndex: Int, weightKg: Double? = nil, reps: Int, rpe: Double? = nil) {
        self.setIndex = setIndex
        self.weightKg = weightKg
        self.reps = reps
        self.rpe = rpe
        self.completedAt = Date()
    }
}
