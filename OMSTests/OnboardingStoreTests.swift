import XCTest
@testable import OMS

final class OnboardingStoreTests: XCTestCase {
    func test_requiresNameInBasics() {
        let store = OnboardingStore()
        XCTAssertNotNil(store.validate(section: .basics))
        store.name = "Tom"
        XCTAssertNil(store.validate(section: .basics))
    }

    func test_requiresAtLeastOnePrimaryGoal() {
        let store = OnboardingStore()
        XCTAssertNotNil(store.validate(section: .goals))
        store.primaryGoals = [.strength]
        XCTAssertNil(store.validate(section: .goals))
    }

    func test_startingEquipmentSetMapsToEquipment() {
        XCTAssertFalse(OnboardingStore.StartingEquipmentSet.gym.defaultItems.isEmpty)
        XCTAssertTrue(OnboardingStore.StartingEquipmentSet.none.defaultItems.isEmpty)
    }
}
