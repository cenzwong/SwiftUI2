import Foundation

/// Orchestrates safety checks and execution of confirmed application operations.
public struct CommitExecutor: Sendable {
    public init() {}

    /// Validates and executes proposals against current context and registry definitions.
    /// - Parameters:
    ///   - proposals: The proposals to execute.
    ///   - currentContext: Current application context snapshot.
    ///   - registry: The intent registry.
    public func commit(
        proposals: [IntentProposal],
        currentContext: IntentContext,
        registry: IntentRegistry
    ) async throws {
        guard !proposals.isEmpty else {
            throw IntentError.commitFailed(reason: "No active proposals to commit")
        }

        // Invariant 4 & Concurrency Scenario C: Validate that proposals match current context revision
        for proposal in proposals {
            guard proposal.contextRevision == currentContext.revision else {
                throw IntentError.contextStale(
                    expectedRevision: currentContext.revision,
                    actualRevision: proposal.contextRevision
                )
            }

            guard let definition = await registry.definition(for: proposal.intentID) else {
                throw IntentError.intentNotFound(proposal.intentID)
            }

            // Invariant 1: Execution happens exclusively during commit phase
            try await definition.commitHandler(proposal.arguments, currentContext)
        }
    }
}
