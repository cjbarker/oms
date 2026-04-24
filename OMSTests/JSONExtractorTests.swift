import XCTest
@testable import OMS

final class JSONExtractorTests: XCTestCase {
    func test_stripsFencesAroundObject() {
        let raw = """
        Here you go:
        ```json
        {"focus":"upper","items":[]}
        ```
        """
        let out = JSONExtractor.extract(raw)
        let data = out.data(using: .utf8)!
        _ = try? JSONSerialization.jsonObject(with: data)
        XCTAssertTrue(out.hasPrefix("{"))
        XCTAssertTrue(out.hasSuffix("}"))
    }

    func test_stripsFencesAroundArray() {
        let raw = "```\n[1,2,3]\n```"
        XCTAssertEqual(JSONExtractor.extract(raw), "[1,2,3]")
    }

    func test_passesThroughBareJSON() {
        let raw = "{\"a\":1}"
        XCTAssertEqual(JSONExtractor.extract(raw), raw)
    }
}
