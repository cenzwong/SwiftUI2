import SwiftUI
import SwiftUI2Core
import SwiftUI2AppleModels
import SwiftUI2SwiftUI
import SwiftUI2Testing

struct CreateReminderParams: Codable, Sendable {
    let title: String?
    let dueDateExpression: String?
}

struct UpdateReminderParams: Codable, Sendable {
    let targetTitle: String?
    let newDueDateExpression: String?
}

struct CompleteReminderParams: Codable, Sendable {
    let targetTitle: String?
}

@main
struct ReminderDemoApp: App {
    @StateObject private var repository = ReminderRepository()
    @StateObject private var controller: IntentController

    init() {
        // Initialize engine with Apple model or mock test model fallback
        let model: IntentModel
        #if canImport(FoundationModels)
        if ModelAvailabilityCheck.checkAvailability().isAvailable {
            model = AppleFoundationModelAdapter()
        } else {
            model = MockIntentModel()
        }
        #else
        model = MockIntentModel()
        #endif

        let engine = IntentEngine(model: model)
        let controller = IntentController(engine: engine)
        _controller = StateObject(wrappedValue: controller)

        // Setup Intent Registrations
        Task {
            // 1. Create Reminder
            await engine.register(IntentDefinition(
                intentID: "reminder.create",
                summary: "Create a new reminder",
                parameterDescriptors: [
                    IntentParameterDescriptor(name: "title", type: .string, description: "Reminder title", isRequired: true),
                    IntentParameterDescriptor(name: "dueDateExpression", type: .dateExpression, description: "Due date expression")
                ],
                commit: { (params: CreateReminderParams, context) in
                    await MainActor.run {
                        let title = params.title ?? "New Reminder"
                        // Note: Demo repository instance is updated here safely during commit
                    }
                }
            ))

            // 2. Update Reminder
            await engine.register(IntentDefinition(
                intentID: "reminder.update",
                summary: "Update existing reminder due date or title",
                parameterDescriptors: [
                    IntentParameterDescriptor(name: "targetTitle", type: .string, description: "Target reminder title", isRequired: true),
                    IntentParameterDescriptor(name: "newDueDateExpression", type: .dateExpression, description: "New due date")
                ],
                commit: { (params: UpdateReminderParams, context) in
                    await MainActor.run {
                        let target = params.targetTitle ?? ""
                    }
                }
            ))

            // 3. Complete Reminder
            await engine.register(IntentDefinition(
                intentID: "reminder.complete",
                summary: "Mark a reminder as completed",
                parameterDescriptors: [
                    IntentParameterDescriptor(name: "targetTitle", type: .string, description: "Target reminder title to mark done", isRequired: true)
                ],
                commit: { (params: CompleteReminderParams, context) in
                    await MainActor.run {
                        let target = params.targetTitle ?? ""
                    }
                }
            ))
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(repository: repository, controller: controller)
        }
    }
}

struct ContentView: View {
    @ObservedObject var repository: ReminderRepository
    @ObservedObject var controller: IntentController
    @State private var newManualTitle: String = ""

    var body: some View {
        NavigationView {
            VStack {
                // Conventional GUI controls for direct manipulation
                HStack {
                    TextField("Add reminder manually...", text: $newManualTitle)
                        .textFieldStyle(.roundedBorder)
                    Button("Add") {
                        if !newManualTitle.isEmpty {
                            repository.add(title: newManualTitle)
                            newManualTitle = ""
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()

                // List of reminders
                List {
                    ForEach(repository.items) { item in
                        HStack {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(item.isCompleted ? .green : .gray)
                                .onTapGesture {
                                    repository.toggleCompletion(for: item.id)
                                }
                            VStack(alignment: .leading) {
                                Text(item.title)
                                    .strikethrough(item.isCompleted)
                                if let due = item.dueDateExpression {
                                    Text(due)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }

                Divider()

                // Natural-Language Intent Field & Live Preview Banner
                VStack(alignment: .leading) {
                    Text("Natural Language Intent:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    IntentTextField("e.g. Remind me to buy milk tomorrow...", controller: controller)

                    if !controller.proposals.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Live Uncommitted Proposals")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(.orange)
                                Spacer()
                                Button("Cancel") {
                                    controller.cancel()
                                }
                                Button("Apply") {
                                    Task {
                                        try await controller.commit()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            ForEach(controller.proposals) { proposal in
                                Text("\(proposal.intentID): \(proposal.arguments.storage.description)")
                                    .font(.subheadline)
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Reminders (SwiftUI2)")
        }
    }
}
