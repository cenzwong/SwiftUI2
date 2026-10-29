# Getting Started with SwiftUI2

## Installation

Add SwiftUI2 to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/SwiftUI2.git", from: "0.1.0")
]
```

## Quick Example

```swift
import SwiftUI
import SwiftUI2Core
import SwiftUI2SwiftUI
import SwiftUI2AppleModels

@main
struct MyApp: App {
    @StateObject private var controller: IntentController

    init() {
        let engine = IntentEngine(model: AppleFoundationModelAdapter())
        let controller = IntentController(engine: engine)
        _controller = StateObject(wrappedValue: controller)

        Task {
            await engine.register(IntentDefinition(
                intentID: "reminder.create",
                summary: "Create a reminder",
                parameterDescriptors: [
                    IntentParameterDescriptor(name: "title", type: .string, description: "Title", isRequired: true)
                ],
                commit: { (params: CreateReminderParams, context) in
                    // Persist change
                }
            ))
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(controller: controller)
        }
    }
}
```
