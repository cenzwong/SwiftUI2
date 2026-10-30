import Foundation

/// Engine configuration options.
public struct IntentEngineConfiguration: Sendable {
    public var debounceDuration: Duration

    public init(debounceDuration: Duration = .milliseconds(300)) {
        self.debounceDuration = debounceDuration
    }
}

/// Central coordinator for intent registration, input lifecycle, inference, previews, and commits.
public final class IntentEngine: Sendable {
    public let registry: IntentRegistry
    public let model: IntentModel
    public let previewStore: PreviewStore
    public let scheduler: IntentScheduler
    public let commitExecutor: CommitExecutor
    public let configuration: IntentEngineConfiguration

    public init(
        model: IntentModel,
        configuration: IntentEngineConfiguration = .init()
    ) {
        self.model = model
        self.configuration = configuration
        self.registry = IntentRegistry()
        self.previewStore = PreviewStore()
        self.scheduler = IntentScheduler(debounceDuration: configuration.debounceDuration)
        self.commitExecutor = CommitExecutor()
    }

    /// Registers an intent definition with the engine.
    public func register(_ definition: IntentDefinition) async {
        await registry.register(definition)
    }

    /// Unregisters an intent definition by ID.
    public func unregister(_ intentID: String) async {
        await registry.unregister(intentID)
    }

    /// Process updated input text and context snapshot.
    public func processInput(
        _ input: String,
        context: IntentContext,
        onProposalsUpdated: (@Sendable ([IntentProposal]) -> Void)? = nil
    ) async -> UInt64 {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            await scheduler.cancel()
            await previewStore.clear()
            return await scheduler.inputRevision
        }

        return await scheduler.schedule(
            input: trimmed,
            context: context,
            registry: registry,
            model: model,
            previewStore: previewStore,
            onProposalsUpdated: onProposalsUpdated
        )
    }

    /// Explicitly commits current active preview proposals against current application context.
    public func commit(currentContext: IntentContext) async throws {
        let state = await previewStore.state()
        guard !state.proposals.isEmpty else {
            throw IntentError.commitFailed(reason: "No proposals available to commit")
        }

        // Concurrency Scenario B & C: Validate non-stale input and context
        // Passes previewStore to remove consumed proposals immediately as they succeed
        try await commitExecutor.commit(
            proposals: state.proposals,
            currentContext: currentContext,
            registry: registry,
            previewStore: previewStore
        )

        // Clear preview after successful batch commit
        await previewStore.clear()
    }

    /// Clears active proposals and cancels pending requests.
    public func clear() async {
        await scheduler.cancel()
        await previewStore.clear()
    }
}
