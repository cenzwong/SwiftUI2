import Foundation
import SwiftUI2Core

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Converts `[IntentDescriptor]` into dynamic generation schemas for Apple Foundation Models.
public struct AppleSchemaBuilder: Sendable {
    public init() {}

    /// Constructs prompt instructions and dynamic JSON schema representation for registered intents.
    public func buildPrompt(
        input: String,
        context: IntentContext,
        descriptors: [IntentDescriptor]
    ) -> String {
        var prompt = "You are an on-device intent parser for an application.\n"
        prompt += "Analyze the user input and extract intent proposals according to the registered schemas.\n"
        prompt += "Current Locale: \(context.localeIdentifier)\n"
        prompt += "Current Date/Time: \(context.timestamp)\n"

        if !context.payload.isEmpty {
            prompt += "Application Context:\n"
            for (k, v) in context.payload {
                prompt += "- \(k): \(v)\n"
            }
        }

        prompt += "\nRegistered Intents:\n"
        for desc in descriptors {
            prompt += "Intent ID: '\(desc.intentID)' - \(desc.summary)\n"
            prompt += "Parameters:\n"
            for param in desc.parameterDescriptors {
                prompt += "  * \(param.name) (\(param.type.rawValue)): \(param.description) [Required: \(param.isRequired)]\n"
            }
        }

        prompt += "\nUser Input: \"\(input)\"\n"
        prompt += "Output valid JSON matching extracted intents. If no intents match or input is ambiguous, return empty intents array."
        return prompt
    }

    #if canImport(FoundationModels)
    @available(iOS 18.2, macOS 15.2, visionOS 2.2, *)
    public func buildGenerationSchema(descriptors: [IntentDescriptor]) throws -> GenerationSchema {
        var intentSchemas: [DynamicGenerationSchema] = []

        for desc in descriptors {
            var props: [DynamicGenerationSchema.Property] = []
            for param in desc.parameterDescriptors {
                let pSchema: DynamicGenerationSchema
                switch param.type {
                case .integer:
                    pSchema = DynamicGenerationSchema(type: Int.self)
                case .double:
                    pSchema = DynamicGenerationSchema(type: Double.self)
                case .boolean:
                    pSchema = DynamicGenerationSchema(type: Bool.self)
                case .string, .dateExpression:
                    pSchema = DynamicGenerationSchema(type: String.self)
                }

                let finalSchema: DynamicGenerationSchema
                if param.isRequired {
                    finalSchema = pSchema
                } else {
                    finalSchema = DynamicGenerationSchema(name: "\(param.name)_nullable", anyOf: [pSchema, .null])
                }

                props.append(DynamicGenerationSchema.Property(name: param.name, schema: finalSchema))
            }

            let intentObject = DynamicGenerationSchema(
                name: desc.intentID.replacingOccurrences(of: ".", with: "_"),
                properties: [
                    DynamicGenerationSchema.Property(name: "intentID", schema: DynamicGenerationSchema(type: String.self)),
                    DynamicGenerationSchema.Property(name: "parameters", schema: DynamicGenerationSchema(name: "params", properties: props))
                ]
            )
            intentSchemas.append(intentObject)
        }

        let containerSchema = DynamicGenerationSchema(
            name: "IntentContainer",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "intents",
                    schema: DynamicGenerationSchema(
                        name: "IntentList",
                        arrayOf: DynamicGenerationSchema(name: "IntentProposalAny", anyOf: intentSchemas)
                    )
                )
            ]
        )

        return try GenerationSchema(root: containerSchema, dependencies: [])
    }
    #endif
}
