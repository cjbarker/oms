import Foundation

enum CoachPersona: String, CaseIterable, Identifiable, Codable {
    case upbeat
    case drillSergeant
    case mixed

    var id: String { rawValue }

    var label: String {
        switch self {
        case .upbeat:         return "Upbeat motivator"
        case .drillSergeant:  return "Drill sergeant"
        case .mixed:          return "Mix of both"
        }
    }

    var sampleLine: String {
        switch self {
        case .upbeat:
            return "You showed up — that's half the battle. Let's make today count!"
        case .drillSergeant:
            return "On your feet. No excuses, no shortcuts. Move!"
        case .mixed:
            return "I believe in you — now prove I'm right. Three sets. Go."
        }
    }

    /// Guidance string injected into LLM system prompts so coach lines stay on-tone.
    var toneGuidance: String {
        switch self {
        case .upbeat:
            return "Warm, encouraging, positive. Celebrate effort. Use exclamation points sparingly."
        case .drillSergeant:
            return "Terse, commanding, direct. No hand-holding. Short imperative sentences."
        case .mixed:
            return "Firm but supportive. Push hard, then acknowledge the effort. Vary tone within the session."
        }
    }
}
