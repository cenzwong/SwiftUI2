import XCTest
@testable import SwiftUI2Core
@testable import SwiftUI2AppleModels
@testable import SwiftUI2Testing

struct SampleBoolParams: Codable, Sendable {
    let title: String
    let isCompleted: Bool
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
}
