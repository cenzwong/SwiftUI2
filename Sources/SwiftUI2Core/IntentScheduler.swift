import Foundation

/// Manages debouncing, input revisions, and sequential execution of inference tasks.
public actor IntentScheduler {
    private var currentInputRevision: UInt64 = 0
    private var currentContextRevision: UInt64 = 0
    private var debounceTask: Task<Void, Never>?
    private var activeInferenceTask: Task<Void, Never>?
    private let debounceDuration: Duration

    public init(debounceDuration: Duration = .milliseconds(300)) {
        self.debounceDuration = debounceDuration
    }

    /// Advances the monotonically increasing input revision.
    public func advanceInputRevision() -> UInt64 {
        currentInputRevision += 1
        return currentInputRevision
    }

    /// Increments or sets the active context revision.
    public func updateContextRevision(_ revision: UInt64) -> UInt64 {
        currentContextRevision = revision
        return currentContextRevision
    }

    public var inputRevision: UInt64 { currentInputRevision }
    public var contextRevision: UInt64 { currentContextRevision }

    /// Schedules a debounced inference request, ensuring older pending/active requests are superseded and cancelled.
    public func schedule(
        input: String,
        context: IntentContext,
        registry: IntentRegistry,
        model: IntentModel,
        previewStore: PreviewStore,
        onProposalsUpdated: (@Sendable ([IntentProposal]) -> Void)? = nil
    ) -> UInt64 {
        currentInputRevision += 1
        let revision = currentInputRevision
        currentContextRevision = context.revision

        // Cancel previous pending debounce or in-flight inference task
        debounceTask?.cancel()
        activeInferenceTask?.cancel()

        debounceTask = Task {
            // Debounce delay
            try? await Task.sleep(for: debounceDuration)
            guard !Task.isCancelled else { return }

            await previewStore.setPending(true, inputRevision: revision)

            let descriptors = await registry.descriptors
            guard !descriptors.isEmpty else {
                await previewStore.updateProposals([], inputRevision: revision, contextRevision: context.revision)
                return
            }

            // Perform inference
            do {
                let proposals = try await model.identify(
                    input: input,
                    context: context,
                    descriptors: descriptors
                )
                guard !Task.isCancelled else { return }

                // Invariant 2 & Concurrency Scenario A: Discard if input revision changed in the meantime
                let updated = await previewStore.updateProposals(
                    proposals,
                    inputRevision: revision,
                    contextRevision: context.revision
                )
                if updated {
                    onProposalsUpdated?(proposals)
                }
            } catch {
                if !Task.isCancelled {
                    await previewStore.updateProposals([], inputRevision: revision, contextRevision: context.revision)
                }
            }
        }

        return revision
    }

    /// Cancels all pending and in-flight inference tasks.
    public func cancel() {
        debounceTask?.cancel()
        debounceTask = nil
        activeInferenceTask?.cancel()
        activeInferenceTask = nil
    }
}
