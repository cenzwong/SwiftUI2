import Foundation

/// Represents a proposed application operation extracted from natural language input.
public struct IntentProposal: Sendable, Identifiable, Equatable {
    public let id: UUID
    public let intentID: String
    public let inputRevision: UInt64
    public let contextRevision: UInt64
    public let arguments: IntentArguments

    public init(
        id: UUID = UUID(),
        intentID: String,
        inputRevision: UInt64,
        contextRevision: UInt64,
        arguments: IntentArguments
    ) {
        self.id = id
        self.intentID = intentID
        self.inputRevision = inputRevision
        self.contextRevision = contextRevision
        self.arguments = arguments
    }
}
