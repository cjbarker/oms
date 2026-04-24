import Foundation
import HealthKit

@MainActor
final class HealthKitService: ObservableObject {
    static let shared = HealthKitService()

    @Published private(set) var latestSnapshot: HealthSnapshot = .unavailable
    @Published private(set) var isAuthorized: Bool = false

    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    var readTypes: Set<HKObjectType> {
        var set: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        set.insert(HKObjectType.workoutType())
        return set
    }

    func requestAuthorization() async {
        guard isAvailable else { return }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
        } catch {
            isAuthorized = false
        }
    }

    /// Fetch and publish the latest snapshot. Missing permissions → nil fields; never throws.
    func refreshSnapshot() async {
        guard isAvailable else {
            latestSnapshot = .unavailable
            return
        }
        async let sleep = fetchLastNightSleepHours()
        async let hrv = fetchLatestHRV()
        async let rhr = fetchRestingHR()
        async let kcal = fetchYesterdayActiveEnergy()
        async let minutes = fetchSevenDayWorkoutMinutes()
        async let lastSummary = fetchLastWorkoutSummary()

        let snapshot = HealthSnapshot(
            lastNightSleepHours: await sleep,
            hrvMs: await hrv,
            restingHeartRate: await rhr,
            yesterdayActiveEnergyKcal: await kcal,
            sevenDayWorkoutMinutes: await minutes,
            lastWorkoutSummary: await lastSummary,
            capturedAt: Date()
        )
        latestSnapshot = snapshot
    }

    // MARK: - Individual queries

    private func fetchLastNightSleepHours() async -> Double? {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        let end = Date()
        let start = Calendar.current.date(byAdding: .hour, value: -20, to: end) ?? end.addingTimeInterval(-72000)
        return await runCategoryQuery(type: type, start: start, end: end) { samples in
            let asleepValues: Set<Int> = [
                HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
            ]
            let total = samples.reduce(0.0) { acc, s in
                guard asleepValues.contains(s.value) else { return acc }
                return acc + s.endDate.timeIntervalSince(s.startDate)
            }
            return total > 0 ? total / 3600.0 : nil
        }
    }

    private func fetchLatestHRV() async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return nil }
        return await runLatestQuantity(type: type, unit: HKUnit(from: "ms"))
    }

    private func fetchRestingHR() async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else { return nil }
        return await runLatestQuantity(type: type, unit: HKUnit(from: "count/min"))
    }

    private func fetchYesterdayActiveEnergy() async -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else { return nil }
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: Date())
        guard let yesterday = cal.date(byAdding: .day, value: -1, to: startOfToday) else { return nil }
        return await sumQuantity(type: type, unit: .kilocalorie(), start: yesterday, end: startOfToday)
    }

    private func fetchSevenDayWorkoutMinutes() async -> Double? {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date().addingTimeInterval(-86400 * 7)
        return await withCheckedContinuation { cont in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
            let q = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let workouts = samples as? [HKWorkout] ?? []
                let total = workouts.reduce(0.0) { $0 + $1.duration / 60.0 }
                cont.resume(returning: total > 0 ? total : nil)
            }
            store.execute(q)
        }
    }

    private func fetchLastWorkoutSummary() async -> String? {
        await withCheckedContinuation { cont in
            let sort = [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            let q = HKSampleQuery(sampleType: .workoutType(), predicate: nil, limit: 1, sortDescriptors: sort) { _, samples, _ in
                guard let w = (samples as? [HKWorkout])?.first else { cont.resume(returning: nil); return }
                let mins = Int(w.duration / 60)
                let fmt = DateFormatter()
                fmt.dateStyle = .medium
                cont.resume(returning: "\(w.workoutActivityType.displayName) · \(mins) min · \(fmt.string(from: w.endDate))")
            }
            store.execute(q)
        }
    }

    // MARK: - Query helpers

    private func runLatestQuantity(type: HKQuantityType, unit: HKUnit) async -> Double? {
        await withCheckedContinuation { cont in
            let sort = [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            let q = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: sort) { _, samples, _ in
                guard let q = (samples as? [HKQuantitySample])?.first else { cont.resume(returning: nil); return }
                cont.resume(returning: q.quantity.doubleValue(for: unit))
            }
            store.execute(q)
        }
    }

    private func sumQuantity(type: HKQuantityType, unit: HKUnit, start: Date, end: Date) async -> Double? {
        await withCheckedContinuation { cont in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
            let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                cont.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit))
            }
            store.execute(q)
        }
    }

    private func runCategoryQuery(type: HKCategoryType, start: Date, end: Date,
                                  reduce: @escaping ([HKCategorySample]) -> Double?) async -> Double? {
        await withCheckedContinuation { cont in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictEndDate)
            let q = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let cat = samples as? [HKCategorySample] ?? []
                cont.resume(returning: reduce(cat))
            }
            store.execute(q)
        }
    }
}

private extension HKWorkoutActivityType {
    var displayName: String {
        switch self {
        case .running: return "Run"
        case .walking: return "Walk"
        case .cycling: return "Cycle"
        case .traditionalStrengthTraining, .functionalStrengthTraining: return "Strength"
        case .highIntensityIntervalTraining: return "HIIT"
        case .yoga: return "Yoga"
        case .swimming: return "Swim"
        default: return "Workout"
        }
    }
}
