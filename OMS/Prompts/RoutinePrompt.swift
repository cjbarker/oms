import Foundation

struct RoutinePromptInput {
    var profile: UserProfile
    var snapshot: HealthSnapshot
    var ownedEquipment: [EquipmentType]
    var recentHistory: [RecentSession]
    var persona: CoachPersona
    var todaysFocusHint: String?

    struct RecentSession {
        var daysAgo: Int
        var focus: String
        var exerciseIds: [String]
    }
}

/// Decoded response shape the LLM is asked to produce.
struct GeneratedRoutine: Codable {
    struct Item: Codable {
        var exerciseId: String
        var sets: Int
        var reps: String
        var restSec: Int
        var tempo: String?
        var group: String?
        var structure: String?
        var coachLine: String?
        var notes: String?
    }
    var focus: String
    var rationale: String
    var items: [Item]
    var cooldown: [String]?
    var coachIntro: String?
}

enum RoutinePrompt {
    static func system(for persona: CoachPersona) -> String {
        """
        You are OMS, a no-nonsense AI strength coach for adults who value longevity and compound movements.

        \(CoachPrompt.toneSection(for: persona))

        HARD CONSTRAINTS:
        - Only select exercises whose `exerciseId` appears in the provided catalog list. Do not invent ids.
        - Favour compound, full-body-economical movements. Bodyweight variants when no equipment is given.
        - Respect every limitation. If a movement pattern is contraindicated (e.g. lumbar flexion for acute low-back pain), substitute a safer pattern and note why.
        - A session must fit within the user's target session length. Assume ~2 min per straight set including rest.
        - Balance categories across the week: strength, core, mobility, cardio.
        - Never prescribe 1-rep-max work or contest-style efforts.
        - Output STRICT JSON matching the provided schema, wrapped in ```json fences. No prose outside the fences.
        """
    }

    static func user(_ input: RoutinePromptInput, availableIds: [String]) -> String {
        let p = input.profile
        let goals = (p.primaryGoals + p.secondaryGoals).map(\.label).joined(separator: ", ")
        let lims = p.limitations.map { l -> String in
            l.note.map { "\(l.tag): \($0)" } ?? l.tag
        }.joined(separator: "; ")
        let equip = input.ownedEquipment.isEmpty ? "none (bodyweight only)" : input.ownedEquipment.map(\.label).joined(separator: ", ")
        let historyBlock = input.recentHistory.isEmpty ? "No recent sessions logged." :
            input.recentHistory.map { "• \($0.daysAgo)d ago — focus: \($0.focus); did: \($0.exerciseIds.joined(separator: ", "))" }.joined(separator: "\n")

        let snap = input.snapshot
        var snapLines: [String] = []
        if let s = snap.lastNightSleepHours { snapLines.append("Sleep last night: \(String(format: "%.1f", s)) h") }
        if let h = snap.hrvMs { snapLines.append("HRV (SDNN): \(Int(h)) ms") }
        if let r = snap.restingHeartRate { snapLines.append("Resting HR: \(Int(r)) bpm") }
        if let k = snap.yesterdayActiveEnergyKcal { snapLines.append("Yesterday active energy: \(Int(k)) kcal") }
        if let w = snap.lastWorkoutSummary { snapLines.append("Last workout: \(w)") }
        snapLines.append("Derived readiness: \(snap.readiness.rawValue)")

        let schema = """
        {
          "focus": "string (e.g. 'Upper body push + core')",
          "rationale": "2–3 sentence why, acknowledging recovery + recent work",
          "coachIntro": "one sentence in coach persona voice",
          "items": [
            {
              "exerciseId": "string (must be in catalog)",
              "sets": 3,
              "reps": "8-10 or 30s or AMRAP",
              "restSec": 90,
              "tempo": "optional e.g. 3-1-1",
              "group": "optional group id for supersets/circuits",
              "structure": "straight | superset | circuit | emom | amrap",
              "coachLine": "one short persona-flavoured cue for this exercise",
              "notes": "optional form/injury note"
            }
          ],
          "cooldown": ["optional mobility exerciseIds for 3–5 min"]
        }
        """

        return """
        USER PROFILE
        - Name: \(p.name.isEmpty ? "Athlete" : p.name)
        - Age: \(p.ageYears.map { "\($0)" } ?? "unknown"), sex: \(p.sex.label)
        - Height / weight: \(Int(p.heightCm)) cm / \(Int(p.weightKg)) kg
        - Experience: \(p.experience.label)
        - Activity level: \(p.activityLevel.label)
        - Goals: \(goals.isEmpty ? "general health" : goals)
        - Limitations / injuries: \(lims.isEmpty ? "none reported" : lims)
        - Current pain points: \(p.painPoints.isEmpty ? "none" : p.painPoints)
        - Medical flags: \(p.medicalFlags.isEmpty ? "none" : p.medicalFlags) (cleared for exercise: \(p.clearedForExercise ? "yes" : "no"))
        - Target sessions/week: \(p.sessionsPerWeekTarget), session length: \(p.sessionMinutesTarget) min
        - Units: \(p.units.label)

        TODAY — RECOVERY
        \(snapLines.map { "• \($0)" }.joined(separator: "\n"))

        AVAILABLE EQUIPMENT: \(equip)

        RECENT SESSIONS (last 7 days)
        \(historyBlock)

        CATALOG — you may only pick from these exerciseIds:
        \(availableIds.joined(separator: ", "))

        FOCUS HINT (optional): \(input.todaysFocusHint ?? "infer the best focus for today")

        Return the routine as JSON matching this schema (wrapped in ```json fences, no other prose):
        \(schema)
        """
    }
}
