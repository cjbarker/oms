import Foundation
import SwiftData
import SwiftUI

/// Draft answers gathered during the onboarding flow. Committed to SwiftData + Keychain
/// on finish.
@Observable
final class OnboardingStore {
    // Persona
    var persona: CoachPersona = .upbeat

    // Basics
    var name: String = ""
    var birthdate: Date = Calendar.current.date(byAdding: .year, value: -40, to: Date()) ?? Date()
    var sex: Sex = .preferNotToSay
    var units: Units = .metric

    // Anthropometrics
    var heightCm: Double = 175
    var weightKg: Double = 80
    var bodyFatPct: String = ""

    // Activity / experience / availability
    var activityLevel: ActivityLevel = .moderate
    var experience: TrainingExperience = .novice
    var familiarLifts: Set<String> = []
    var sessionsPerWeekTarget: Int = 3
    var sessionMinutesTarget: Int = 45

    // Goals
    var primaryGoals: Set<FitnessGoal> = []
    var secondaryGoals: Set<FitnessGoal> = []

    // Limitations & medical
    var limitationTags: Set<String> = []
    var limitationNote: String = ""
    var painPoints: String = ""
    var medicalFlags: String = ""
    var clearedForExercise: Bool = false

    // Equipment
    enum StartingEquipmentSet: String, CaseIterable, Identifiable {
        case gym, home, travel, none
        var id: String { rawValue }
        var label: String {
            switch self {
            case .gym:   return "Gym"
            case .home:  return "Home"
            case .travel: return "Travel"
            case .none:  return "Nothing yet"
            }
        }
        var defaultItems: [EquipmentType] {
            switch self {
            case .gym:    return [.barbell, .dumbbells, .bench, .squatRack, .cable, .pullUpBar, .kettlebell, .treadmill, .rower]
            case .home:   return [.dumbbells, .pullUpBar, .resistanceBand, .yogaMat, .kettlebell]
            case .travel: return [.resistanceBand, .jumpRope, .yogaMat]
            case .none:   return []
            }
        }
    }
    var equipmentSet: StartingEquipmentSet = .home

    // Appearance
    var appearance: AppearanceMode = .system

    // LLM backend
    var llmMode: LLMBackendMode = .remote
    var remoteEndpoint: String = LLMConfig.defaultRemoteEndpoint
    var remoteModel: String = LLMConfig.defaultRemoteModel
    var apiKey: String = ""

    // MARK: - Validation
    func validate(section: OnboardingFlow.Section) -> String? {
        switch section {
        case .basics where name.trimmingCharacters(in: .whitespaces).isEmpty:
            return "Please add your preferred name."
        case .goals where primaryGoals.isEmpty:
            return "Pick at least one primary goal."
        default:
            return nil
        }
    }

    // MARK: - Commit
    @MainActor
    func commit(modelContext: ModelContext) {
        // Profile
        let profile = UserProfile(
            name: name,
            birthdate: birthdate,
            sex: sex,
            heightCm: heightCm,
            weightKg: weightKg,
            bodyFatPct: Double(bodyFatPct),
            activityLevel: activityLevel,
            experience: experience,
            familiarLifts: Array(familiarLifts),
            sessionsPerWeekTarget: sessionsPerWeekTarget,
            sessionMinutesTarget: sessionMinutesTarget,
            primaryGoals: Array(primaryGoals),
            secondaryGoals: Array(secondaryGoals),
            limitations: limitationTags.map { Limitation(tag: $0, note: limitationNote.isEmpty ? nil : limitationNote) },
            painPoints: painPoints,
            medicalFlags: medicalFlags,
            clearedForExercise: clearedForExercise,
            units: units,
            coachPersona: persona
        )
        modelContext.insert(profile)

        // Equipment profile
        let ep = EquipmentProfile(
            name: equipmentSet.label,
            equipment: equipmentSet.defaultItems,
            isActive: true
        )
        modelContext.insert(ep)

        // LLM config + key
        UserDefaults.standard.set(llmMode.rawValue, forKey: LLMConfig.Keys.mode)
        UserDefaults.standard.set(remoteEndpoint, forKey: LLMConfig.Keys.remoteEndpoint)
        UserDefaults.standard.set(remoteModel, forKey: LLMConfig.Keys.remoteModel)
        if llmMode == .remote, !apiKey.isEmpty {
            try? KeychainService.saveAPIKey(apiKey)
        }

        // Appearance
        UserDefaults.standard.set(appearance.rawValue, forKey: AppearanceMode.storageKey)

        try? modelContext.save()
    }
}
