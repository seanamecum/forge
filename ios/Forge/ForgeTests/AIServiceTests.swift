import XCTest
@testable import Forge

final class AIServiceTests: XCTestCase {

    // MARK: - Config gating (no network)

    func testMockModeWhenNoKey() {
        // The test environment has no ANTHROPIC_API_KEY / Secrets.plist.
        XCTAssertTrue(ForgeConfig.anthropicAPIKey.isEmpty)
        XCTAssertEqual(ForgeConfig.aiMode, .mock)
    }

    func testReplyFallsBackToMockOffline() async {
        // With no key, reply() must return a usable mock answer — never empty.
        let msg = await AIService.reply(to: "What should I train today?")
        XCTAssertEqual(msg.role, .coach)
        XCTAssertFalse(msg.text.isEmpty)
    }

    func testDefaultModelIsOpus() {
        XCTAssertEqual(ForgeConfig.coachModel, "claude-opus-4-8")
    }

    // MARK: - System prompt carries the athlete's real data

    func testSystemPromptReferencesKeySignals() {
        let p = AIService.systemPrompt(checkInNote: nil)
        XCTAssertTrue(p.contains("Sean"))
        XCTAssertTrue(p.contains("Recovery"))
        XCTAssertTrue(p.lowercased().contains("patellar") || p.lowercased().contains("knee"))
        XCTAssertTrue(p.contains("Magnesium") || p.contains("Vitamin D"))
        XCTAssertTrue(p.contains("not medical advice"))
    }

    func testSystemPromptIncludesCheckInWhenPresent() {
        let note = "Morning check-in — sleep quality 2/5, soreness 8/10, energy 2/5, stress 4/5."
        let p = AIService.systemPrompt(checkInNote: note)
        XCTAssertTrue(p.contains("MORNING CHECK-IN"))
        XCTAssertTrue(p.contains("soreness 8/10"))
    }

    // MARK: - Mock engine routing

    func testMockRoutesToTopicalAnswers() {
        XCTAssertTrue(AIService.mockReply(to: "Should I deload?").text.lowercased().contains("deload"))
        XCTAssertTrue(AIService.mockReply(to: "How do I hit 225 bench?").text.contains("225"))
        XCTAssertTrue(AIService.mockReply(to: "What is holding me back?").text.lowercased().contains("sleep"))
        XCTAssertTrue(AIService.mockReply(to: "What will I look like in 12 weeks?").text.contains("207"))
    }

    func testQuickPromptsCoverCoreQuestions() {
        XCTAssertTrue(AIService.quickPrompts.contains("Should I deload?"))
        XCTAssertTrue(AIService.quickPrompts.contains("What is holding me back?"))
        XCTAssertGreaterThanOrEqual(AIService.quickPrompts.count, 8)
    }
}
