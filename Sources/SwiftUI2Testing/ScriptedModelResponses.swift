import Foundation
import SwiftUI2Core

/// Pre-configured dataset of natural language inputs and expected proposals for model verification tests.
public enum ScriptedModelResponses {
    public static let sampleDescriptors: [IntentDescriptor] = [
        IntentDescriptor(
            intentID: "reminder.create",
            summary: "Create a new reminder",
            parameterDescriptors: [
                IntentParameterDescriptor(name: "title", type: .string, description: "Reminder title", isRequired: true),
                IntentParameterDescriptor(name: "dueDateExpression", type: .dateExpression, description: "Due date expression")
            ]
        ),
        IntentDescriptor(
            intentID: "reminder.update",
            summary: "Update an existing reminder",
            parameterDescriptors: [
                IntentParameterDescriptor(name: "targetTitle", type: .string, description: "Existing reminder title", isRequired: true),
                IntentParameterDescriptor(name: "newDueDateExpression", type: .dateExpression, description: "New due date expression")
            ]
        ),
        IntentDescriptor(
            intentID: "reminder.complete",
            summary: "Mark a reminder as completed",
            parameterDescriptors: [
                IntentParameterDescriptor(name: "targetTitle", type: .string, description: "Reminder to mark complete", isRequired: true)
            ]
        )
    ]

    public static let testCases: [(input: String, expectedIntentIDs: [String])] = [
        ("Remind me to buy milk tomorrow", ["reminder.create"]),
        ("Move my meeting with John to Friday at 4pm", ["reminder.update"]),
        ("Mark buying milk as completed", ["reminder.complete"]),
        ("Remind me to call John tomorrow at 9, and buy milk after work", ["reminder.create", "reminder.create"]),
        ("What is the capital of France?", []) // Unknown / unsupported operation
    ]
}
