import Foundation
import SwiftUI2Core

/// Deterministic mock implementation of `IntentModel` for testing, previews, and CI without Apple Intelligence hardware.
public final class MockIntentModel: IntentModel, @unchecked Sendable {
    private var cannedResponses: [String: [IntentProposal]] = [:]
    private var scriptHandler: (@Sendable (String, IntentContext, [IntentDescriptor]) async throws -> [IntentProposal])?
    public var delayDuration: Duration?
    public var shouldThrowError: IntentError?

    public init() {}

    /// Registers a fixed list of proposals to return when input matches `input`.
    public func setCannedResponse(for input: String, proposals: [IntentProposal]) {
        cannedResponses[input] = proposals
    }

    /// Sets a custom closure to generate dynamic responses during tests.
    public func setScriptHandler(
        _ handler: @escaping @Sendable (String, IntentContext, [IntentDescriptor]) async throws -> [IntentProposal]
    ) {
        self.scriptHandler = handler
    }

    public func identify(
        input: String,
        context: IntentContext,
        descriptors: [IntentDescriptor]
    ) async throws -> [IntentProposal] {
        if let delay = delayDuration {
            try await Task.sleep(for: delay)
        }

        if let error = shouldThrowError {
            throw error
        }

        if let handler = scriptHandler {
            return try await handler(input, context, descriptors)
        }

        if let exactMatch = cannedResponses[input] {
            return exactMatch
        }

        // Rule-based heuristic default mock behavior for common reminder commands
        var proposals: [IntentProposal] = []
        let lower = input.lowercased()

        if lower.contains("remind me to") || lower.contains("create") || lower.contains("buy milk") || lower.contains("call john") {
            if descriptors.contains(where: { $0.intentID == "reminder.create" }) {
                var args = IntentArguments()
                if lower.contains("buy milk") {
                    args["title"] = "Buy milk"
                } else if lower.contains("call john") {
                    args["title"] = "Call John"
                } else {
                    let titlePart = input.replacingOccurrences(of: "Remind me to ", with: "", options: .caseInsensitive)
                    args["title"] = titlePart.isEmpty ? "New Reminder" : titlePart
                }

                if lower.contains("tomorrow") {
                    args["dueDateExpression"] = "tomorrow"
                } else if lower.contains("friday") {
                    args["dueDateExpression"] = "friday"
                }

                proposals.append(IntentProposal(
                    intentID: "reminder.create",
                    inputRevision: 1,
                    contextRevision: context.revision,
                    arguments: args
                ))
            }
        }

        if lower.contains("move") || lower.contains("update") || lower.contains("reschedule") {
            if descriptors.contains(where: { $0.intentID == "reminder.update" }) {
                var args = IntentArguments()
                args["targetTitle"] = lower.contains("meeting") ? "Meeting with John" : "Buy milk"
                if lower.contains("friday") {
                    args["newDueDateExpression"] = "Friday at 4pm"
                }
                proposals.append(IntentProposal(
                    intentID: "reminder.update",
                    inputRevision: 1,
                    contextRevision: context.revision,
                    arguments: args
                ))
            }
        }

        if lower.contains("mark") || lower.contains("complete") || lower.contains("done") {
            if descriptors.contains(where: { $0.intentID == "reminder.complete" }) {
                var args = IntentArguments()
                args["targetTitle"] = lower.contains("milk") ? "Buy milk" : "Task"
                proposals.append(IntentProposal(
                    intentID: "reminder.complete",
                    inputRevision: 1,
                    contextRevision: context.revision,
                    arguments: args
                ))
            }
        }

        return proposals
    }
}
