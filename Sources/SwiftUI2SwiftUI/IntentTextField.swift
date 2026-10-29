import Foundation
import SwiftUI2Core

#if canImport(SwiftUI)
import SwiftUI

/// Custom SwiftUI input component automatically tied to an `IntentController`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct IntentTextField: View {
    private let title: String
    @ObservedObject private var controller: IntentController

    public init(_ title: String, controller: IntentController) {
        self.title = title
        self.controller = controller
    }

    public var body: some View {
        HStack {
            TextField(title, text: Binding(
                get: { controller.inputText },
                set: { controller.updateInput($0) }
            ))
            .textFieldStyle(.roundedBorder)

            if controller.isPending {
                ProgressView()
                    .padding(.leading, 4)
            }
        }
    }
}

/// SwiftUI View Modifier to attach intent engine state to any view container.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct IntentPreviewModifier: ViewModifier {
    @ObservedObject public var controller: IntentController

    public func body(content: Content) -> some View {
        VStack(spacing: 0) {
            content

            if !controller.proposals.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Live Intent Proposals (\(controller.proposals.count))")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Cancel") {
                            controller.cancel()
                        }
                        .font(.caption)
                        Button("Apply") {
                            Task {
                                try? await controller.commit()
                            }
                        }
                        .font(.caption)
                        .buttonStyle(.borderedProminent)
                        .disabled(!controller.canCommit)
                    }

                    ForEach(controller.proposals) { proposal in
                        HStack {
                            Text(proposal.intentID)
                                .font(.subheadline)
                                .bold()
                            Spacer()
                            Text(proposal.arguments.storage.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding()
            }
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public extension View {
    func intentPreviewOverlay(controller: IntentController) -> some View {
        self.modifier(IntentPreviewModifier(controller: controller))
    }
}
#endif
