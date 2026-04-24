import Foundation

/// Persona-aware lines used when the LLM hasn't supplied one for a given moment.
enum CoachVoice {
    static func routineIntro(persona: CoachPersona, focus: String) -> String {
        switch persona {
        case .upbeat:
            return "Let's do this — \(focus.isEmpty ? "today's session" : focus.lowercased()) is going to feel great."
        case .drillSergeant:
            return "Today: \(focus.isEmpty ? "work" : focus.lowercased()). Head down, do the reps."
        case .mixed:
            return "Focus: \(focus.isEmpty ? "the work" : focus.lowercased()). Show up, earn it, move on."
        }
    }

    static func betweenSets(persona: CoachPersona) -> String {
        switch persona {
        case .upbeat:         return "Breathe. You've got one more in you."
        case .drillSergeant:  return "Reset your grip. Next set."
        case .mixed:          return "Shake it off. Back to work."
        }
    }

    static func done(persona: CoachPersona) -> String {
        switch persona {
        case .upbeat:         return "Beautiful work today."
        case .drillSergeant:  return "Dismissed. Same time tomorrow."
        case .mixed:          return "Session banked. Recover hard."
        }
    }
}
