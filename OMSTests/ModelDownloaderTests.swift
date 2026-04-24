import XCTest
import CryptoKit
@testable import OMS

/// Only exercises pure helpers — a real background-download integration test would require
/// an instrumented test host and is out of scope for CI.
final class ModelDownloaderTests: XCTestCase {
    func test_sha256IsStableAndDeterministic() throws {
        let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let data = Data("hello OMS".utf8)
        try data.write(to: tmp)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let a = try ModelDownloader.computeSHA256(at: tmp)
        let b = try ModelDownloader.computeSHA256(at: tmp)
        XCTAssertEqual(a, b)

        // Same as CryptoKit directly
        let expected = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(a, expected)
    }
}
