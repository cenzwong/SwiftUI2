import Foundation

/// Protocol for inference providers that translate natural language into structured intent proposals.
public protocol IntentModel: Sendable {
    /// Analyzes natural language input in the given application context and returns zero or more structured proposals.
    /// - Parameters:
    ///   - input: The raw text typed by the user.
    ///   - context: Bounded application snapshot with revision metadata.
    ///   - descriptors: Registered intent definitions available for matching.
    /// - Returns: A list of proposed intents with extracted arguments.
    func identify(
        input: String,
        context: IntentContext,
        descriptors: [IntentDescriptor]
    ) async throws -> [IntentProposal]
}
