import Foundation
import SwiftUI2Core

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Production adapter connecting `SwiftUI2Core` to Apple's Foundation Models on supported Apple Intelligence hardware.
public final class AppleFoundationModelAdapter: IntentModel, @unchecked Sendable {
    private let schemaBuilder = AppleSchemaBuilder()
    private let sessionManager = SessionManager()

    public init() {}

    public func identify(
        input: String,
        context: IntentContext,
        descriptors: [IntentDescriptor]
    ) async throws -> [IntentProposal] {
        let availability = ModelAvailabilityCheck.checkAvailability()
        guard availability.isAvailable else {
            throw IntentError.modelUnavailable(reason: availability.description)
        }

        #if canImport(FoundationModels)
        if #available(iOS 18.2, macOS 15.2, visionOS 2.2, *) {
            let prompt = schemaBuilder.buildPrompt(input: input, context: context, descriptors: descriptors)
            let generationSchema = try? schemaBuilder.buildGenerationSchema(descriptors: descriptors)

            return try await sessionManager.executeRequest(revision: context.revision) {
                let session = LanguageModelSession()
                let response: LanguageModelSession.Response
                if let schema = generationSchema {
                    response = try await session.respond(to: prompt, schema: schema)
                } else {
                    response = try await session.respond(to: prompt)
                }

                // Parse generated response into intent proposals
                return self.parseResponse(response.text, context: context)
            }
        } else {
            throw IntentError.modelUnavailable(reason: "OS version unsupported")
        }
        #else
        throw IntentError.modelUnavailable(reason: "FoundationModels not available in compilation environment")
        #endif
    }

    /// Internal response parser converting model JSON or structured text into `[IntentProposal]`.
    public func parseResponse(_ text: String, context: IntentContext) -> [IntentProposal] {
        // Fallback robust JSON extraction logic for structured proposals
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let intentArray = json["intents"] as? [[String: Any]] else {
            return []
        }

        var proposals: [IntentProposal] = []
        for item in intentArray {
            guard let intentID = item["intentID"] as? String else { continue }
            var args = IntentArguments()
            if let params = item["parameters"] as? [String: Any] {
                for (k, v) in params {
                    // Skip JSON null values (NSNull) so optional parameters remain absent/nil rather than stringifying as "<null>"
                    if v is NSNull {
                        continue
                    }
                    // Use CFBoolean check alone to distinguish true JSON booleans from NSNumbers representing 0 and 1
                    if let number = v as? NSNumber, CFBooleanGetTypeID() == CFGetTypeID(number) {
                        args[k] = number.boolValue ? "true" : "false"
                    } else {
                        args[k] = "\(v)"
                    }
                }
            }
            proposals.append(IntentProposal(
                intentID: intentID,
                inputRevision: 1,
                contextRevision: context.revision,
                arguments: args
            ))
        }
        return proposals
    }
}
