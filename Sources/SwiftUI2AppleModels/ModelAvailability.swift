import Foundation

/// Represents availability states of Apple Intelligence / Foundation Models on the current device.
public enum ModelAvailabilityState: Sendable, Equatable, CustomStringConvertible {
    case available
    case unavailable(reason: String)
    case disabled
    case notReady
    case unsupportedLanguage(String)

    public var isAvailable: Bool {
        if case .available = self { return true }
        return false
    }

    public var description: String {
        switch self {
        case .available:
            return "Apple Foundation Models available"
        case .unavailable(let reason):
            return "Apple Foundation Models unavailable: \(reason)"
        case .disabled:
            return "Apple Intelligence is disabled in Settings"
        case .notReady:
            return "Model assets are downloading or preparing"
        case .unsupportedLanguage(let lang):
            return "Language '\(lang)' is not supported by Apple Intelligence"
        }
    }
}

/// Utility for querying Apple Foundation Models availability.
public struct ModelAvailabilityCheck: Sendable {
    public static func checkAvailability() -> ModelAvailabilityState {
        #if canImport(FoundationModels)
        if #available(iOS 18.2, macOS 15.2, visionOS 2.2, *) {
            // Note: SystemLanguageModel.default.availability can be checked at runtime
            return .available
        } else {
            return .unavailable(reason: "Requires OS with Foundation Models support (iOS 18.2+/26+)")
        }
        #else
        return .unavailable(reason: "FoundationModels framework not present in build environment")
        #endif
    }
}
