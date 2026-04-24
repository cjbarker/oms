import XCTest
@testable import OMS

final class ExerciseCatalogTests: XCTestCase {
    func test_catalogLoads() {
        let svc = ExerciseCatalogService(bundle: .main)
        XCTAssertFalse(svc.exercises.isEmpty, "ExerciseCatalog.json should be bundled and non-empty.")
    }

    func test_allIdsAreUnique() {
        let ids = ExerciseCatalogService(bundle: .main).exercises.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "Catalog entries must have unique ids.")
    }

    func test_bodyweightFilter() {
        let svc = ExerciseCatalogService(bundle: .main)
        let bwOnly = svc.all(owned: [])
        XCTAssertTrue(bwOnly.allSatisfy { $0.bodyweight || $0.equipment.isEmpty },
                      "With no equipment, every available exercise should be bodyweight or require no gear.")
    }

    func test_availableIdsMatchEquipment() {
        let svc = ExerciseCatalogService(bundle: .main)
        let owned: Set<EquipmentType> = [.dumbbells, .bench]
        let ids = svc.availableIds(owned: owned)
        XCTAssertTrue(ids.contains("db_row"), "Dumbbell row should appear when dumbbells + bench are owned.")
    }
}
