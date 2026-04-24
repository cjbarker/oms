import Foundation

/// Decides next-session prescription for an exercise given its recent set logs.
///
/// Rules (intentionally simple; the LLM may further adjust when generating):
/// - If the most recent session hit every target set at RPE ≤ 8, bump +2.5 kg (compound)
///   or +1.0 kg (isolation); if bodyweight, add one rep to the top of the range.
/// - If any set missed target reps at RPE ≥ 9 or failed, hold or drop 5%.
/// - Otherwise, hold.
enum ProgressionEngine {
    struct Prescription: Equatable {
        var targetWeightKg: Double?
        var targetRepsRange: String
        var rationale: String
    }

    static func nextPrescription(
        for exercise: Exercise,
        recent sessions: [[SetLog]],
        currentRepsRange: String,
        currentWeightKg: Double?
    ) -> Prescription {
        guard let latest = sessions.first, !latest.isEmpty else {
            return Prescription(
                targetWeightKg: currentWeightKg,
                targetRepsRange: currentRepsRange,
                rationale: "First session — we'll calibrate from today's numbers."
            )
        }

        let minTargetReps = parseMinReps(from: currentRepsRange)
        let hitAll = latest.allSatisfy { log in
            log.reps >= minTargetReps && (log.rpe ?? 7) <= 8
        }
        let missed = latest.contains { log in
            log.reps < minTargetReps || (log.rpe ?? 6) >= 9
        }

        if hitAll {
            if let w = currentWeightKg {
                let bump = exercise.category == .strength ? 2.5 : 1.0
                return Prescription(
                    targetWeightKg: w + bump,
                    targetRepsRange: currentRepsRange,
                    rationale: "Cleared all sets below RPE 8 — bumping weight by \(bump) kg."
                )
            } else {
                return Prescription(
                    targetWeightKg: nil,
                    targetRepsRange: addOneRep(to: currentRepsRange),
                    rationale: "Bodyweight — adding a rep to the top of the range."
                )
            }
        }

        if missed, let w = currentWeightKg {
            let drop = (w * 0.05 * 10).rounded() / 10
            return Prescription(
                targetWeightKg: max(0, w - drop),
                targetRepsRange: currentRepsRange,
                rationale: "Last session grinded — backing off \(drop) kg to rebuild."
            )
        }

        return Prescription(
            targetWeightKg: currentWeightKg,
            targetRepsRange: currentRepsRange,
            rationale: "Holding — cleanup another session here."
        )
    }

    static func parseMinReps(from range: String) -> Int {
        // Accepts "8", "8-10", "8–10", "AMRAP". Anything unparseable → 1.
        let trimmed = range.trimmingCharacters(in: .whitespaces)
        if trimmed.caseInsensitiveCompare("AMRAP") == .orderedSame { return 1 }
        let seps = CharacterSet(charactersIn: "-–—")
        let head = trimmed.components(separatedBy: seps).first ?? trimmed
        return Int(head) ?? 1
    }

    static func addOneRep(to range: String) -> String {
        let seps = CharacterSet(charactersIn: "-–—")
        let parts = range.components(separatedBy: seps)
        if parts.count == 2, let lo = Int(parts[0]), let hi = Int(parts[1]) {
            return "\(lo)-\(hi + 1)"
        }
        if let single = Int(range) { return "\(single + 1)" }
        return range
    }
}
