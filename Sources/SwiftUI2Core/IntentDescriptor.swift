import Foundation

/// Defines primitive parameter types supported by the intent engine's dynamic schemas.
public enum IntentParameterType: String, Codable, Sendable, Hashable {
    case string
    case integer
    case double
    case boolean
    case dateExpression // Unresolved date expressions like "tomorrow at 9"
}

/// Metadata describing a single parameter of an intent.
public struct IntentParameterDescriptor: Codable, Sendable, Hashable, Identifiable {
    public var id: String { name }
    public let name: String
    public let type: IntentParameterType
    public let description: String
    public let isRequired: Bool

    public init(name: String, type: IntentParameterType, description: String, isRequired: Bool = false) {
        self.name = name
        self.type = type
        self.description = description
        self.isRequired = isRequired
    }
}

/// Metadata describing an intent that can be detected from natural language.
public struct IntentDescriptor: Codable, Sendable, Hashable, Identifiable {
    public var id: String { intentID }
    public let intentID: String
    public let summary: String
    public let parameterDescriptors: [IntentParameterDescriptor]

    public init(intentID: String, summary: String, parameterDescriptors: [IntentParameterDescriptor]) {
        self.intentID = intentID
        self.summary = summary
        self.parameterDescriptors = parameterDescriptors
    }
}
