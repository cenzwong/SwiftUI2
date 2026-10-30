import Foundation

/// Active proposals and generated UI previews held in memory.
public struct PreviewState: Sendable, Equatable {
    public let proposals: [IntentProposal]
    public let inputRevision: UInt64
    public let contextRevision: UInt64
    public let isPending: Bool

    public init(
        proposals: [IntentProposal] = [],
        inputRevision: UInt64 = 0,
        contextRevision: UInt64 = 0,
        isPending: Bool = false
    ) {
        self.proposals = proposals
        self.inputRevision = inputRevision
        self.contextRevision = contextRevision
        self.isPending = isPending
    }

    public static let empty = PreviewState()
}

/// Actor managing thread-safe preview state transitions.
public actor PreviewStore {
    private(set) public var state: PreviewState = .empty

    public init() {}

    /// Updates preview proposals only if input and context revisions match or exceed current active revisions.
    @discardableResult
    public func updateProposals(
        _ proposals: [IntentProposal],
        inputRevision: UInt64,
        contextRevision: UInt64
    ) -> Bool {
        guard inputRevision >= state.inputRevision else {
            return false // Discard stale revision
        }
        state = PreviewState(
            proposals: proposals,
            inputRevision: inputRevision,
            contextRevision: contextRevision,
            isPending: false
        )
        return true
    }

    /// Sets the pending indicator state for debouncing/inference.
    public func setPending(_ isPending: Bool, inputRevision: UInt64) {
        guard inputRevision >= state.inputRevision else { return }
        state = PreviewState(
            proposals: state.proposals,
            inputRevision: inputRevision,
            contextRevision: state.contextRevision,
            isPending: isPending
        )
    }

    /// Removes specific proposals by ID (e.g. after successful individual commit execution).
    public func removeProposals(withIDs ids: Set<UUID>) {
        let remaining = state.proposals.filter { !ids.contains($0.id) }
        state = PreviewState(
            proposals: remaining,
            inputRevision: state.inputRevision,
            contextRevision: state.contextRevision,
            isPending: state.isPending
        )
    }

    /// Clears active proposals.
    public func clear() {
        state = .empty
    }
}
