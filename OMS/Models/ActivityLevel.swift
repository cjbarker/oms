import Foundation

enum ActivityLevel: String, CaseIterable, Identifiable, Codable {
    case sedentary
    case light
    case moderate
    case active
    case veryActive

    var id: String { rawValue }

    var label: String {
        switch self {
        case .sedentary:  return "Sedentary"
        case .light:      return "Lightly active"
        case .moderate:   return "Moderately active"
        case .active:     return "Very active"
        case .veryActive: return "Athlete"
        }
    }

    var detail: String {
        switch self {
        case .sedentary:  return "Desk job, little to no exercise."
        case .light:      return "Walks, light chores, 1–2 short sessions/wk."
        case .moderate:   return "3–4 structured sessions/wk."
        case .active:     return "5+ sessions/wk or physical job."
        case .veryActive: return "Training twice a day, competitive."
        }
    }
}

enum TrainingExperience: String, CaseIterable, Identifiable, Codable {
    case novice
    case intermediate
    case advanced

    var id: String { rawValue }
    var label: String {
        switch self {
        case .novice:       return "Novice (< 1 yr)"
        case .intermediate: return "Intermediate (1–3 yrs)"
        case .advanced:     return "Advanced (3+ yrs)"
        }
    }
}

enum Sex: String, CaseIterable, Identifiable, Codable {
    case male, female, other, preferNotToSay
    var id: String { rawValue }
    var label: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other / non-binary"
        case .preferNotToSay: return "Prefer not to say"
        }
    }
}

enum Units: String, CaseIterable, Identifiable, Codable {
    case metric, imperial
    var id: String { rawValue }
    var label: String { self == .metric ? "Metric (kg, cm)" : "Imperial (lb, in)" }
}

enum FitnessGoal: String, CaseIterable, Identifiable, Codable {
    case strength
    case hypertrophy
    case fatLoss
    case mobility
    case endurance
    case posture
    case generalHealth

    var id: String { rawValue }

    var label: String {
        switch self {
        case .strength:      return "Build strength"
        case .hypertrophy:   return "Build muscle"
        case .fatLoss:       return "Lose fat"
        case .mobility:      return "Improve mobility"
        case .endurance:     return "Cardio / endurance"
        case .posture:       return "Better posture"
        case .generalHealth: return "General health"
        }
    }
}

/// Structured limitation: a common tag + an optional free-text note.
struct Limitation: Codable, Hashable, Identifiable {
    var tag: String
    var note: String?
    var id: String { tag + (note ?? "") }

    static let commonTags: [String] = [
        "Lower back", "Knee", "Shoulder", "Neck", "Hip",
        "Wrist / elbow", "Post-op", "Pregnancy / postpartum",
        "Hypertension", "Diabetes"
    ]
}
