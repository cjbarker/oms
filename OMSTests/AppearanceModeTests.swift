import XCTest
import SwiftUI
@testable import OMS

final class AppearanceModeTests: XCTestCase {
    func test_colorSchemeMapping() {
        XCTAssertNil(AppearanceMode.system.colorScheme)
        XCTAssertEqual(AppearanceMode.light.colorScheme, .light)
        XCTAssertEqual(AppearanceMode.dark.colorScheme, .dark)
    }

    func test_rawValueRoundTrip() {
        for m in AppearanceMode.allCases {
            XCTAssertEqual(AppearanceMode(rawValue: m.rawValue), m)
        }
    }
}
