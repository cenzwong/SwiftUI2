import Foundation

/// Thread-safe registry holding registered intent definitions.
public actor IntentRegistry {
    private var definitions: [String: IntentDefinition] = [:]

    public init() {}

    /// Registers a new intent definition.
    public func register(_ definition: IntentDefinition) {
        definitions[definition.descriptor.intentID] = definition
    }

    /// Unregisters an intent definition by ID.
    public func unregister(_ intentID: String) {
        definitions.removeValue(forKey: intentID)
    }

    /// Retrieves an intent definition by ID.
    public func definition(for intentID: String) -> IntentDefinition? {
        definitions[intentID]
    }

    /// Returns descriptors for all currently registered intents.
    public var descriptors: [IntentDescriptor] {
        Array(definitions.values.map(\.descriptor))
    }

    /// Returns all registered intent IDs.
    public var registeredIntentIDs: [String] {
        Array(definitions.keys)
    }
}
