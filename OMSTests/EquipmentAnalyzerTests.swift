import XCTest
@testable import OMS

final class EquipmentAnalyzerTests: XCTestCase {
    func test_parsesFencedJSONWithKnownTypes() throws {
        let raw = """
        ```json
        {"detected":["dumbbells","bench","unknownThing"],"notes":"decent light"}
        ```
        """
        let result = try EquipmentAnalyzer.parse(raw)
        XCTAssertEqual(result, [.dumbbells, .bench])
    }

    func test_throwsOnMalformedJSON() {
        XCTAssertThrowsError(try EquipmentAnalyzer.parse("not json at all"))
    }
}
