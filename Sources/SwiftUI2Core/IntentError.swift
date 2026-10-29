import Foundation

/// Framework errors that can occur during intent registration, inference, validation, or execution.
public enum IntentError: Error, CustomStringConvertible, Sendable, Equatable {
    case modelUnavailable(reason: String)
    case intentNotFound(String)
    case invalidParameters(intentID: String, reason: String)
    case contextStale(expectedRevision: UInt64, actualRevision: UInt64)
    case inputStale(expectedRevision: UInt64, actualRevision: UInt64)
    case validationFailed(String)
    case commitFailed(reason: String)
    case cancelled
    case unknown(String)

    public var description: String {
        switch self {
        case .modelUnavailable(let reason):
            return "Model unavailable: \(reason)"
        case .intentNotFound(let id):
            return "Intent not found: '\(id)'"
        case .invalidParameters(let id, let reason):
            return "Invalid parameters for intent '\(id)': \(reason)"
        case .contextStale(let expected, let actual):
            return "Context revision stale (expected \(expected), got \(actual))"
        case .inputStale(let expected, let actual):
            return "Input revision stale (expected \(expected), got \(actual))"
        case .validationFailed(let reason):
            return "Validation failed: \(reason)"
        case .commitFailed(let reason):
            return "Commit failed: \(reason)"
        case .cancelled:
            return "Operation cancelled"
        case .unknown(let msg):
            return "Unknown intent error: \(msg)"
        }
    }
}
