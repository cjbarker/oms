import Foundation

enum CoachPrompt {
    static func toneSection(for persona: CoachPersona) -> String {
        """
        Coach persona: \(persona.label).
        Tone guidance: \(persona.toneGuidance)
        Speak directly to the user ("you"), not about them. Keep every coach line under 120 characters.
        """
    }
}
