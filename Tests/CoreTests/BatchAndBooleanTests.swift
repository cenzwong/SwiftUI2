import XCTest
@testable import SwiftUI2Core
@testable import SwiftUI2AppleModels
@testable import SwiftUI2SwiftUI
@testable import SwiftUI2Testing

struct SampleBoolParams: Codable, Sendable {
    let title: String
    let isCompleted: Bool
}

struct SampleNumericParams: Codable, Sendable {
    let priority: Int
    let count: Int
    let ratio: Double
}

struct SampleOptionalParams: Codable, Sendable {
    let title: String
    let dueDateExpression: String?
}

final class BatchAndBooleanTests: XCTestCase {
    func testBatchCommitPreValidationFailurePreventsPartialExecution() async throws {
        let registry = IntentRegistry()
        var executedCount = 0

        // Register valid intent 1
        await registry.register(IntentDefinition(
            intentID: "intent1",
            summary: "Intent 1",
            parameterDescriptors: [],
            commit: { _, _ in
                executedCount += 1
            }
        ))

        let context = IntentContext(revision: 1)
        let proposals = [
            IntentProposal(intentID: "intent1", inputRevision: 1, contextRevision: 1, arguments: IntentArguments()),
            IntentProposal(intentID: "missing_intent", inputRevision: 1, contextRevision: 1, arguments: IntentArguments())
        ]

        let executor = CommitExecutor()
        do {
            try await executor.commit(proposals: proposals, currentContext: context, registry: registry)
            XCTFail("Expected intentNotFound error")
        } catch IntentError.intentNotFound(let missingID) {
            XCTAssertEqual(missingID, "missing_intent")
            // Crucial: no commit handler should have executed during pre-validation phase
            XCTAssertEqual(executedCount, 0)
        }
    }

    func testBatchCommitConsumesProposalsOnPartialThrowToPreventReplay() async throws {
        let registry = IntentRegistry()
        let previewStore = PreviewStore()
        var executionCounts: [String: Int] = ["intent1": 0, "intent2": 0]

        await registry.register(IntentDefinition(
            intentID: "intent1",
            summary: "Intent 1",
            parameterDescriptors: [],
            commit: { _, _ in
                executionCounts["intent1", default: 0] += 1
            }
        ))

        await registry.register(IntentDefinition(
            intentID: "intent2",
            summary: "Intent 2",
            parameterDescriptors: [],
            commit: { _, _ in
                executionCounts["intent2", default: 0] += 1
                throw IntentError.commitFailed(reason: "Execution error in intent2")
            }
        ))

        let context = IntentContext(revision: 1)
        let p1 = IntentProposal(id: UUID(), intentID: "intent1", inputRevision: 1, contextRevision: 1, arguments: IntentArguments())
        let p2 = IntentProposal(id: UUID(), intentID: "intent2", inputRevision: 1, contextRevision: 1, arguments: IntentArguments())

        await previewStore.updateProposals([p1, p2], inputRevision: 1, contextRevision: 1)

        let executor = CommitExecutor()
        do {
            try await executor.commit(proposals: [p1, p2], currentContext: context, registry: registry, previewStore: previewStore)
            XCTFail("Expected throw from intent2")
        } catch {
            // Check execution counts after first attempt
            XCTAssertEqual(executionCounts["intent1"], 1)
            XCTAssertEqual(executionCounts["intent2"], 1)

            // Verify that proposal p1 was consumed from previewStore so retry cannot replay it
            let state = await previewStore.state()
            XCTAssertEqual(state.proposals.count, 1)
            XCTAssertEqual(state.proposals.first?.id, p2.id)
        }
    }

    func testCommitPreservesNewerProposalsArrivingDuringAsyncExecution() async throws {
        let mockModel = MockIntentModel()
        let engine = IntentEngine(model: mockModel)

        let newProposalID = UUID()

        await engine.register(IntentDefinition(
            intentID: "intent.slow",
            summary: "Slow Intent",
            parameterDescriptors: [],
            commit: { _, _ in
                // Simulate slow async commit handler during which user types new input
                try await Task.sleep(for: .milliseconds(100))
                // Inject new proposal representing new user command arriving while commit is in-flight
                let newProposal = IntentProposal(
                    id: newProposalID,
                    intentID: "intent.new",
                    inputRevision: 2,
                    contextRevision: 1,
                    arguments: IntentArguments()
                )
                await engine.previewStore.updateProposals([newProposal], inputRevision: 2, contextRevision: 1)
            }
        ))

        let context = IntentContext(revision: 1)
        let slowProposal = IntentProposal(intentID: "intent.slow", inputRevision: 1, contextRevision: 1, arguments: IntentArguments())
        await engine.previewStore.updateProposals([slowProposal], inputRevision: 1, contextRevision: 1)

        // Perform commit of slowProposal
        try await engine.commit(currentContext: context)

        // Verify that the new proposal (newProposal) injected during commit execution is preserved and NOT deleted
        let state = await engine.previewStore.state()
        XCTAssertEqual(state.proposals.count, 1)
        XCTAssertEqual(state.proposals.first?.id, newProposalID)
    }

    @MainActor
    func testControllerCommitPreservesNewerInputTextAndProposals() async throws {
        let mockModel = MockIntentModel()
        let engine = IntentEngine(model: mockModel)

        let newProposal = IntentProposal(
            id: UUID(),
            intentID: "reminder.new",
            inputRevision: 2,
            contextRevision: 1,
            arguments: IntentArguments()
        )

        await engine.register(IntentDefinition(
            intentID: "reminder.create",
            summary: "Create reminder",
            parameterDescriptors: [],
            commit: { _, _ in
                try await Task.sleep(for: .milliseconds(50))
            }
        ))

        let controller = IntentController(engine: engine)
        let oldProposal = IntentProposal(intentID: "reminder.create", inputRevision: 1, contextRevision: 1, arguments: IntentArguments())

        await engine.previewStore.updateProposals([oldProposal], inputRevision: 1, contextRevision: 1)

        controller.inputText = "Old Command"
        // Simulate controller state having oldProposal and newProposal
        Task { @MainActor in
            // User types new text while commit is running
            try? await Task.sleep(for: .milliseconds(20))
            controller.inputText = "New Command"
        }

        try await controller.commit()

        // Verify that inputText was NOT cleared back to "" since user edited it during commit
        XCTAssertEqual(controller.inputText, "New Command")
    }

    func testJSONNullParametersAreIgnoredAndDecodeAsNil() throws {
        let adapter = AppleFoundationModelAdapter()
        let jsonResponse = """
        {
          "intents": [
            {
              "intentID": "reminder.create",
              "parameters": {
                "title": "Buy milk",
                "dueDateExpression": null
              }
            }
          ]
        }
        """

        let context = IntentContext(revision: 1)
        let proposals = adapter.parseResponse(jsonResponse, context: context)

        XCTAssertEqual(proposals.count, 1)
        let proposal = proposals[0]
        XCTAssertEqual(proposal.arguments.string(for: "title"), "Buy milk")
        XCTAssertNil(proposal.arguments.string(for: "dueDateExpression"))

        let decoded = try proposal.arguments.decode(SampleOptionalParams.self)
        XCTAssertEqual(decoded.title, "Buy milk")
        XCTAssertNil(decoded.dueDateExpression)
    }

    func testJSONBooleanParsingAndTypedDecoding() throws {
        let adapter = AppleFoundationModelAdapter()
        let jsonResponse = """
        {
          "intents": [
            {
              "intentID": "reminder.complete",
              "parameters": {
                "title": "Buy milk",
                "isCompleted": true
              }
            }
          ]
        }
        """

        let context = IntentContext(revision: 1)
        let proposals = adapter.parseResponse(jsonResponse, context: context)

        XCTAssertEqual(proposals.count, 1)
        let proposal = proposals[0]
        XCTAssertEqual(proposal.arguments.string(for: "isCompleted"), "true")
        XCTAssertEqual(proposal.arguments.bool(for: "isCompleted"), true)

        let decoded = try proposal.arguments.decode(SampleBoolParams.self)
        XCTAssertEqual(decoded.title, "Buy milk")
        XCTAssertEqual(decoded.isCompleted, true)
    }

    func testJSONNumericZeroAndOneParsingAndTypedDecoding() throws {
        let adapter = AppleFoundationModelAdapter()
        let jsonResponse = """
        {
          "intents": [
            {
              "intentID": "reminder.update",
              "parameters": {
                "priority": 0,
                "count": 1,
                "ratio": 0.0
              }
            }
          ]
        }
        """

        let context = IntentContext(revision: 1)
        let proposals = adapter.parseResponse(jsonResponse, context: context)

        XCTAssertEqual(proposals.count, 1)
        let proposal = proposals[0]
        XCTAssertEqual(proposal.arguments.string(for: "priority"), "0")
        XCTAssertEqual(proposal.arguments.int(for: "priority"), 0)
        XCTAssertEqual(proposal.arguments.string(for: "count"), "1")
        XCTAssertEqual(proposal.arguments.int(for: "count"), 1)

        let decoded = try proposal.arguments.decode(SampleNumericParams.self)
        XCTAssertEqual(decoded.priority, 0)
        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded.ratio, 0.0)
    }
}
