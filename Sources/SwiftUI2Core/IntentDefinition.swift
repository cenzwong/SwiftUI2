import Foundation

/// Closure type for computing dynamic temporary UI previews.
public typealias PreviewHandler = @Sendable (IntentArguments, IntentContext) async throws -> AnySendablePreview?

/// Closure type for executing committed application actions.
public typealias CommitHandler = @Sendable (IntentArguments, IntentContext) async throws -> Void

/// Wrapper to safely erased preview values across boundaries while preserving Sendable compliance.
public struct AnySendablePreview: Sendable {
    public let value: Any & Sendable

    public init<T: Sendable>(_ value: T) {
        self.value = value
    }
}

/// Dynamic, developer-defined registration for an application intent.
public struct IntentDefinition: Sendable {
    public let descriptor: IntentDescriptor
    public let previewHandler: PreviewHandler?
    public let commitHandler: CommitHandler

    public init(
        descriptor: IntentDescriptor,
        preview: PreviewHandler? = nil,
        commit: @escaping CommitHandler
    ) {
        self.descriptor = descriptor
        self.previewHandler = preview
        self.commitHandler = commit
    }

    /// Convenience initializer supporting typed Decodable parameter structs.
    public init<P: Decodable & Sendable>(
        intentID: String,
        summary: String,
        parameterDescriptors: [IntentParameterDescriptor],
        preview: (@Sendable (P, IntentContext) async throws -> AnySendablePreview?)? = nil,
        commit: @escaping @Sendable (P, IntentContext) async throws -> Void
    ) {
        self.descriptor = IntentDescriptor(
            intentID: intentID,
            summary: summary,
            parameterDescriptors: parameterDescriptors
        )
        if let preview = preview {
            self.previewHandler = { args, context in
                let typed = try args.decode(P.self)
                return try await preview(typed, context)
            }
        } else {
            self.previewHandler = nil
        }
        self.commitHandler = { args, context in
            let typed = try args.decode(P.self)
            try await commit(typed, context)
        }
    }
}
