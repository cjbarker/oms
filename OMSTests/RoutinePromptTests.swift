import XCTest
@testable import OMS

final class RoutinePromptTests: XCTestCase {
    func test_systemPromptMentionsPersonaAndGuardsIds() {
        let sys = RoutinePrompt.system(for: .drillSergeant)
        XCTAssertTrue(sys.contains("Drill sergeant"))
        XCTAssertTrue(sys.contains("Only select exercises whose `exerciseId` appears"))
        XCTAssertTrue(sys.contains("```json"))
    }

    func test_userPromptIncludesProfileAndSnapshotFields() {
        let profile = UserProfile(
            name: "Tom", heightCm: 180, weightKg: 85,
            primaryGoals: [.strength, .mobility],
            limitations: [Limitation(tag: "Lower back", note: "Mild stiffness")],
            coachPersona: .mixed
        )
        let snap = HealthSnapshot(
            lastNightSleepHours: 6.5, hrvMs: 45, restingHeartRate: 58,
            yesterdayActiveEnergyKcal: 350, sevenDayWorkoutMinutes: 180,
            lastWorkoutSummary: "Strength · 50 min", capturedAt: Date()
        )
        let input = RoutinePromptInput(
            profile: profile, snapshot: snap,
            ownedEquipment: [.dumbbells, .bench],
            recentHistory: [
                .init(daysAgo: 1, focus: "Lower", exerciseIds: ["goblet_squat"])
            ],
            persona: .mixed, todaysFocusHint: nil
        )
        let out = RoutinePrompt.user(input, availableIds: ["pushup", "db_row"])
        XCTAssertTrue(out.contains("Tom"))
        XCTAssertTrue(out.contains("Dumbbells"))
        XCTAssertTrue(out.contains("Lower back: Mild stiffness"))
        XCTAssertTrue(out.contains("1d ago"))
        XCTAssertTrue(out.contains("pushup, db_row"))
    }

    func test_parseRejectsUnknownIds() throws {
        let raw = """
        ```json
        {
          "focus": "Push",
          "rationale": "Light day.",
          "items": [
            {"exerciseId":"pushup","sets":3,"reps":"8-10","restSec":60},
            {"exerciseId":"does_not_exist","sets":3,"reps":"8-10","restSec":60}
          ]
        }
        ```
        """
        let parsed = try RoutineGenerator.parse(raw, availableIds: ["pushup", "plank"])
        XCTAssertEqual(parsed.items.count, 1)
        XCTAssertEqual(parsed.items.first?.exerciseId, "pushup")
    }

    func test_parseThrowsWhenNothingRecognisable() {
        let raw = """
        ```json
        {"focus":"x","rationale":"x","items":[{"exerciseId":"alien","sets":1,"reps":"1","restSec":0}]}
        ```
        """
        XCTAssertThrowsError(try RoutineGenerator.parse(raw, availableIds: ["pushup"]))
    }
}
