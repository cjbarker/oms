import XCTest
@testable import OMS

final class ProgressionEngineTests: XCTestCase {
    private var exercise: Exercise {
        Exercise(id: "db_row", name: "DB row", category: .strength, pattern: .horizontalPull,
                 bodyweight: false, equipment: [.dumbbells],
                 primaryMuscles: ["lats"], cues: [],
                 youtubeSearch: "db row", youtubeId: nil)
    }

    func test_bumpsWeightWhenAllSetsHitBelowRPE8() {
        let logs = [
            SetLog(setIndex: 1, weightKg: 20, reps: 10, rpe: 7),
            SetLog(setIndex: 2, weightKg: 20, reps: 10, rpe: 7),
            SetLog(setIndex: 3, weightKg: 20, reps: 10, rpe: 8)
        ]
        let rx = ProgressionEngine.nextPrescription(
            for: exercise, recent: [logs],
            currentRepsRange: "8-10", currentWeightKg: 20
        )
        XCTAssertEqual(rx.targetWeightKg, 22.5)
        XCTAssertEqual(rx.targetRepsRange, "8-10")
    }

    func test_backsOffAfterGrindyMissedSet() {
        let logs = [
            SetLog(setIndex: 1, weightKg: 40, reps: 7, rpe: 9),
            SetLog(setIndex: 2, weightKg: 40, reps: 6, rpe: 10)
        ]
        let rx = ProgressionEngine.nextPrescription(
            for: exercise, recent: [logs],
            currentRepsRange: "8-10", currentWeightKg: 40
        )
        XCTAssertNotNil(rx.targetWeightKg)
        XCTAssertLessThan(rx.targetWeightKg ?? 0, 40)
    }

    func test_bodyweightAddsRep() {
        let bw = Exercise(id: "pushup", name: "Push-up", category: .strength, pattern: .horizontalPush,
                          bodyweight: true, equipment: [], primaryMuscles: [], cues: [],
                          youtubeSearch: "", youtubeId: nil)
        let logs = [
            SetLog(setIndex: 1, reps: 12, rpe: 7),
            SetLog(setIndex: 2, reps: 12, rpe: 7),
            SetLog(setIndex: 3, reps: 12, rpe: 8)
        ]
        let rx = ProgressionEngine.nextPrescription(
            for: bw, recent: [logs],
            currentRepsRange: "10-12", currentWeightKg: nil
        )
        XCTAssertEqual(rx.targetRepsRange, "10-13")
    }

    func test_holdsWhenNoHistory() {
        let rx = ProgressionEngine.nextPrescription(
            for: exercise, recent: [],
            currentRepsRange: "8-10", currentWeightKg: 20
        )
        XCTAssertEqual(rx.targetWeightKg, 20)
    }

    func test_parseMinReps() {
        XCTAssertEqual(ProgressionEngine.parseMinReps(from: "8-10"), 8)
        XCTAssertEqual(ProgressionEngine.parseMinReps(from: "8–10"), 8)
        XCTAssertEqual(ProgressionEngine.parseMinReps(from: "6"), 6)
        XCTAssertEqual(ProgressionEngine.parseMinReps(from: "AMRAP"), 1)
    }
}
