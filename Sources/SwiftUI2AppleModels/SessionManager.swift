import Foundation
import SwiftUI2Core

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Actor managing the lifecycle of Apple `LanguageModelSession` instances.
/// Enforces Section 4.5 requirement: Never send concurrent requests to a single session.
public actor SessionManager {
    private var isSessionActive: Bool = false
    private var activeRequestRevision: UInt64 = 0

    public init() {}

    /// Executes an inference closure on the language model session while guaranteeing request isolation and cancellation handling.
    public func executeRequest<T: Sendable>(
        revision: UInt64,
        block: @Sendable () async throws -> T
    ) async throws -> T {
        // Guarantee no concurrent requests on single session
        while isSessionActive {
            try await Task.sleep(for: .milliseconds(20))
        }

        isSessionActive = true
        activeRequestRevision = revision

        defer {
            isSessionActive = false
        }

        guard !Task.isCancelled else {
            throw IntentError.cancelled
        }

        return try await block()
    }
}
