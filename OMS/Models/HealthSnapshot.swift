import Foundation

/// In-memory snapshot of recent Apple Health signals used to shape today's routine.
struct HealthSnapshot: Codable, Equatable {
    var lastNightSleepHours: Double?
    var hrvMs: Double?
    var restingHeartRate: Double?
    var yesterdayActiveEnergyKcal: Double?
    var sevenDayWorkoutMinutes: Double?
    var lastWorkoutSummary: String?
    var capturedAt: Date

    static let unavailable = HealthSnapshot(capturedAt: Date())

    /// Qualitative readiness bucket derived heuristically from the snapshot.
    var readiness: Readiness {
        // Poor sleep is the strongest single signal.
        if let sleep = lastNightSleepHours, sleep < 5 { return .low }
        // HRV suppression is a decent recovery proxy when present.
        if let hrv = hrvMs, hrv < 30 { return .low }
        if let sleep = lastNightSleepHours, sleep < 6.5 { return .moderate }
        if let hrv = hrvMs, hrv < 45 { return .moderate }
        return .good
    }

    enum Readiness: String, Codable {
        case low, moderate, good
        var label: String {
            switch self {
            case .low:      return "Low — lean into mobility and light cardio today."
            case .moderate: return "Moderate — we'll keep volume sensible."
            case .good:     return "Good — time to push."
            }
        }
    }
}
