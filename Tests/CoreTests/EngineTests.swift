import XCTest
@testable import SwiftUI2Core
@testable import SwiftUI2Testing

final class EngineTests: XCTestCase {
    var mockModel: MockIntentModel!
    var engine: IntentEngine!

    override func setUp() async throws {
        mockModel = MockIntentModel()
        engine = IntentEngine(
            model: mockModel,
            configuration: .init(debounceDuration: .milliseconds(50))
        )

        // Register reminder.create intent
        await engine.register(IntentDefinition(
            descriptor: IntentDescriptor(
                intentID: "reminder.create",
                summary: "Create reminder",
                parameterDescriptors: [
                    IntentParameterDescriptor(name: "title", type: .string, description: "Title", isRequired: true)
                ]
            ),
            commit: { args, _ in
                // Commit handler
            }
        ))
    }

    func testIntentRegistrationAndDescriptors() async {
        let descriptors = await engine.registry.descriptors
        XCTAssertEqual(descriptors.count, 1)
        XCTAssertEqual(descriptors.first?.intentID, "reminder.create")
    }

    func testProcessInputAndPreviewUpdate() async throws {
        let context = IntentContext(revision: 1)
        let rev = await engine.processInput("Remind me to buy milk", context: context)
        XCTAssertGreaterThan(rev, 0)

        // Wait for debounce and inference task
        try await Task.sleep(for: .milliseconds(150))

        let state = await engine.previewStore.state()
        XCTAssertEqual(state.proposals.count, 1)
        XCTAssertEqual(state.proposals.first?.intentID, "reminder.create")
        XCTAssertEqual(state.proposals.first?.arguments["title"], "Buy milk")
    }

    func testCommitValidationAndExecution() async throws {
        var committedTitle: String?
        await engine.register(IntentDefinition(
            descriptor: IntentDescriptor(
                intentID: "reminder.create",
                summary: "Create reminder",
                parameterDescriptors: [
                    IntentParameterDescriptor(name: "title", type: .string, description: "Title", isRequired: true)
                ]
            ),
            commit: { args, _ in
                committedTitle = args["title"]
            }
        ))

        let context = IntentContext(revision: 1)
        _ = await engine.processInput("Remind me to buy milk", context: context)
        try await Task.sleep(for: .milliseconds(150))

        // Perform commit
        try await engine.commit(currentContext: context)
        XCTAssertEqual(committedTitle, "Buy milk")

        // Store cleared after commit
        let state = await engine.previewStore.state()
        XCTAssertTrue(state.proposals.isEmpty)
    }

    func testScenarioA_LatestRevisionWins() async throws {
        mockModel.delayDuration = .milliseconds(100)

        let context = IntentContext(revision: 1)
        _ = await engine.processInput("Remind me to buy milk", context: context)

        // User changes input immediately
        try await Task.sleep(for: .milliseconds(10))
        _ = await engine.processInput("Remind me to call John", context: context)

        try await Task.sleep(for: .milliseconds(300))

        let state = await engine.previewStore.state()
        XCTAssertEqual(state.proposals.count, 1)
        XCTAssertEqual(state.proposals.first?.arguments["title"], "Call John")
    }

    func testScenarioB_CommitDuringInferenceFailsIfNoProposals() async {
        mockModel.delayDuration = .milliseconds(200)

        let context = IntentContext(revision: 1)
        _ = await engine.processInput("Remind me to buy milk", context: context)

        // Attempt commit before inference completes
        do {
            try await engine.commit(currentContext: context)
            XCTFail("Expected commit failure when no proposals ready")
        } catch {
            // Success
        }
    }

    func testScenarioC_ContextChangeRevalidatesCommit() async throws {
        let context1 = IntentContext(revision: 1)
        _ = await engine.processInput("Remind me to buy milk", context: context1)
        try await Task.sleep(for: .milliseconds(150))

        // Application context changed before commit
        let context2 = IntentContext(revision: 2)
        do {
            try await engine.commit(currentContext: context2)
            XCTFail("Expected contextStale error")
        } catch IntentError.contextStale {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testScenarioD_InferenceCancellation() async throws {
        mockModel.delayDuration = .milliseconds(150)
        let context = IntentContext(revision: 1)

        _ = await engine.processInput("Remind me to buy milk", context: context)
        try await Task.sleep(for: .milliseconds(20))

        await engine.clear()

        try await Task.sleep(for: .milliseconds(200))
        let state = await engine.previewStore.state()
        XCTAssertTrue(state.proposals.isEmpty)
    }
}
