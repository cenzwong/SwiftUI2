# SwiftUI2 — Native On-Device Intent Interface Framework

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-iOS_26%2B_%7C_macOS_15.2%2B-lightgrey.svg)]()
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)]()

> **Autocomplete for actions, not just words.**

SwiftUI2 is an open-source, Swift-native framework for integrating natural-language intent detection, instant previews, and controlled action execution into iOS, iPadOS, and macOS applications.

Inspired by Evan Zhou's [Unified Intent Interface (UI2)](https://github.com/EvanZhouDev/ui2).

---

## Key Features

- 🧠 **On-Device Inference**: Powered by Apple Foundation Models framework and Apple Intelligence.
- ⚡ **Instant Preview**: Real-time temporary UI preview updates as the user types without mutating application state.
- 🛡️ **Safe Execution**: Strict separation between intent detection/preview and application action commit.
- 🔄 **Actor-Isolated Scheduler**: Guarantees latest-revision state reconciliation and prevents concurrent session conflicts.
- 🛠️ **UI-Agnostic Core**: Modular design allowing engine usage in SwiftUI, AppKit, UIKit, or CLI scripts.
- 🧪 **Hardware-Free Testing**: Includes `MockIntentModel` for deterministic unit testing without Apple Intelligence hardware.

---

## Fundamental Principle

$$\text{Intent Input} \longrightarrow \text{Structured Proposal} \longrightarrow \text{Live Temporary Preview} \longrightarrow \text{User Commit} \longrightarrow \text{Action Execution}$$

1. The language model interprets natural-language intent.
2. The framework produces a structured proposal.
3. The application renders an uncommitted preview.
4. The user explicitly presses **Apply** or **Cancel**.
5. The model **never** mutates application state during inference or preview.

---

## Package Architecture

```
SwiftUI2/
├── Sources/
│   ├── SwiftUI2Core/          # Domain models, engine, scheduler, state machine
│   ├── SwiftUI2AppleModels/   # Apple Foundation Models adapter & schema builder
│   ├── SwiftUI2SwiftUI/       # SwiftUI controller, text fields, view modifiers
│   └── SwiftUI2Testing/       # Mock intent models & scripted dataset
├── Tests/                     # Comprehensive unit & integration tests
└── Examples/
    └── ReminderDemo/          # Full reference application
```

---

## Quick Example

```swift
import SwiftUI
import SwiftUI2Core
import SwiftUI2SwiftUI
import SwiftUI2AppleModels

@main
struct ReminderApp: App {
    @StateObject private var controller: IntentController

    init() {
        let engine = IntentEngine(model: AppleFoundationModelAdapter())
        let controller = IntentController(engine: engine)
        _controller = StateObject(wrappedValue: controller)

        Task {
            // Register Intent
            await engine.register(IntentDefinition(
                intentID: "reminder.create",
                summary: "Create a reminder",
                parameterDescriptors: [
                    IntentParameterDescriptor(name: "title", type: .string, description: "Reminder title", isRequired: true)
                ],
                commit: { (params: CreateReminderParams, context) in
                    // Execute persistent mutation
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

---

## License & Attribution

SwiftUI2 is released under the [Apache License 2.0](LICENSE).

SwiftUI2 is an independent Swift implementation inspired by Evan Zhou's [UI2](https://github.com/EvanZhouDev/ui2) design concept.
