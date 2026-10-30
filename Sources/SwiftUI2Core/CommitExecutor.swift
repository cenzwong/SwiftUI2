import Foundation

/// Orchestrates safety checks and execution of confirmed application operations.
public struct CommitExecutor: Sendable {
    public init() {}

    /// Validates and executes proposals against current context and registry definitions.
    /// First performs complete pre-validation of the entire batch so that unprocessable batches fail before any mutation.
    /// As handlers succeed, consumed proposals are removed from the `PreviewStore` to prevent replaying completed mutations on retry.
    /// - Parameters:
    ///   - proposals: The proposals to execute.
    ///   - currentContext: Current application context snapshot.
    ///   - registry: The intent registry.
    ///   - previewStore: Optional store to consume proposals from as they execute.
    public func commit(
        proposals: [IntentProposal],
        currentContext: IntentContext,
        registry: IntentRegistry,
        previewStore: PreviewStore? = nil
    ) async throws {
        guard !proposals.isEmpty else {
            throw IntentError.commitFailed(reason: "No active proposals to commit")
        }

        // --- Phase 1: Pre-validation of entire batch ---
        // Validate all context revisions and verify that definitions exist for all proposals BEFORE executing any handler.
        var validatedDefinitions: [(proposal: IntentProposal, definition: IntentDefinition)] = []
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

            validatedDefinitions.append((proposal, definition))
        }

        // --- Phase 2: Sequential Execution with Consumption ---
        for (proposal, definition) in validatedDefinitions {
            do {
                try await definition.commitHandler(proposal.arguments, currentContext)
                // Consume proposal immediately on success so retrying cannot replay completed mutations
                if let previewStore = previewStore {
                    await previewStore.removeProposals(withIDs: [proposal.id])
                }
            } catch {
                throw error
            }
        }
    }
}
