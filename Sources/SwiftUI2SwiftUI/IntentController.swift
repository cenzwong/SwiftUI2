import Foundation
import SwiftUI2Core

#if canImport(Combine)
import Combine
#endif

/// MainActor-isolated controller managing input state, debouncing, active proposals, and commits for SwiftUI views.
@MainActor
public final class IntentController: ObservableObject {
    @Published public var inputText: String = ""
    @Published private(set) public var proposals: [IntentProposal] = []
    @Published private(set) public var isPending: Bool = false
    @Published private(set) public var errorMessage: String?

    public let engine: IntentEngine
    public var contextProvider: (@MainActor () -> IntentContext)?

    public init(engine: IntentEngine, contextProvider: (@MainActor () -> IntentContext)? = nil) {
        self.engine = engine
        self.contextProvider = contextProvider
    }

    /// Primary entry point when input text changes in UI.
    public func updateInput(_ newInput: String) {
        self.inputText = newInput
        self.errorMessage = nil

        let context = contextProvider?() ?? IntentContext.empty

        Task { @MainActor in
            _ = await engine.processInput(newInput, context: context) { [weak self] newProposals in
                Task { @MainActor in
                    self?.proposals = newProposals
                    self?.isPending = false
                }
            }
        }
    }

    /// Indicates whether active proposals exist that can be committed by the user.
    public var canCommit: Bool {
        !proposals.isEmpty && !isPending
    }

    /// Explicitly commits current active preview proposals.
    public func commit() async throws {
        let currentContext = contextProvider?() ?? IntentContext.empty
        do {
            try await engine.commit(currentContext: currentContext)
            self.proposals = []
            self.inputText = ""
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Cancels pending inference and clears previews.
    public func cancel() {
        Task { @MainActor in
            await engine.clear()
            self.proposals = []
            self.inputText = ""
            self.errorMessage = nil
        }
    }
}
