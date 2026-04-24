import Foundation
import SwiftData

@Model
final class UserProfile {
    var name: String
    var birthdate: Date?
    var sexRaw: String
    var heightCm: Double
    var weightKg: Double
    var bodyFatPct: Double?
    var activityLevelRaw: String
    var experienceRaw: String
    var familiarLifts: [String]
    var sessionsPerWeekTarget: Int
    var sessionMinutesTarget: Int
    var primaryGoalsRaw: [String]
    var secondaryGoalsRaw: [String]
    var limitations: [Limitation]
    var painPoints: String
    var medicalFlags: String
    var clearedForExercise: Bool
    var unitsRaw: String
    var coachPersonaRaw: String
    var createdAt: Date

    init(
        name: String = "",
        birthdate: Date? = nil,
        sex: Sex = .preferNotToSay,
        heightCm: Double = 175,
        weightKg: Double = 80,
        bodyFatPct: Double? = nil,
        activityLevel: ActivityLevel = .moderate,
        experience: TrainingExperience = .novice,
        familiarLifts: [String] = [],
        sessionsPerWeekTarget: Int = 3,
        sessionMinutesTarget: Int = 45,
        primaryGoals: [FitnessGoal] = [],
        secondaryGoals: [FitnessGoal] = [],
        limitations: [Limitation] = [],
        painPoints: String = "",
        medicalFlags: String = "",
        clearedForExercise: Bool = false,
        units: Units = .metric,
        coachPersona: CoachPersona = .upbeat
    ) {
        self.name = name
        self.birthdate = birthdate
        self.sexRaw = sex.rawValue
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.bodyFatPct = bodyFatPct
        self.activityLevelRaw = activityLevel.rawValue
        self.experienceRaw = experience.rawValue
        self.familiarLifts = familiarLifts
        self.sessionsPerWeekTarget = sessionsPerWeekTarget
        self.sessionMinutesTarget = sessionMinutesTarget
        self.primaryGoalsRaw = primaryGoals.map(\.rawValue)
        self.secondaryGoalsRaw = secondaryGoals.map(\.rawValue)
        self.limitations = limitations
        self.painPoints = painPoints
        self.medicalFlags = medicalFlags
        self.clearedForExercise = clearedForExercise
        self.unitsRaw = units.rawValue
        self.coachPersonaRaw = coachPersona.rawValue
        self.createdAt = Date()
    }

    var sex: Sex { Sex(rawValue: sexRaw) ?? .preferNotToSay }
    var activityLevel: ActivityLevel { ActivityLevel(rawValue: activityLevelRaw) ?? .moderate }
    var experience: TrainingExperience { TrainingExperience(rawValue: experienceRaw) ?? .novice }
    var units: Units { Units(rawValue: unitsRaw) ?? .metric }
    var coachPersona: CoachPersona {
        get { CoachPersona(rawValue: coachPersonaRaw) ?? .upbeat }
        set { coachPersonaRaw = newValue.rawValue }
    }
    var primaryGoals: [FitnessGoal] { primaryGoalsRaw.compactMap(FitnessGoal.init(rawValue:)) }
    var secondaryGoals: [FitnessGoal] { secondaryGoalsRaw.compactMap(FitnessGoal.init(rawValue:)) }

    var ageYears: Int? {
        guard let birthdate else { return nil }
        return Calendar.current.dateComponents([.year], from: birthdate, to: Date()).year
    }
}
