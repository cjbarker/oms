import XCTest
@testable import OMS

final class LLMRouterTests: XCTestCase {
    func test_remoteBackendReportsVisionSupported() {
        let r = RemoteLLMClient(apiKeyProvider: { "sk-test" })
        XCTAssertTrue(r.visionSupported)
    }

    func test_localBackendReportsVisionUnsupported() {
        let l = LocalLLMClient()
        XCTAssertFalse(l.visionSupported)
    }

    func test_localBackendThrowsWhenModelMissing() async {
        let l = LocalLLMClient()
        do {
            _ = try await l.generate(LLMRequest(messages: [.user("hi")]))
            XCTFail("Expected throw when no model file is present.")
        } catch {
            // pass
        }
    }

    func test_gemmaPromptWraps() {
        let p = LocalLLMClient.buildGemmaPrompt(
            system: "be brief",
            messages: [.user("hello"), .assistant("hi there"), .user("again")]
        )
        XCTAssertTrue(p.contains("<start_of_turn>system"))
        XCTAssertTrue(p.contains("<start_of_turn>user\nhello"))
        XCTAssertTrue(p.contains("<start_of_turn>model\nhi there"))
        XCTAssertTrue(p.hasSuffix("<start_of_turn>model\n"))
    }
}
