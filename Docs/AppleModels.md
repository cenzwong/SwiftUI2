# Apple Foundation Models Integration

`SwiftUI2AppleModels` provides the link between `SwiftUI2Core` and Apple's Foundation Models framework (`iOS 18.2+`, `macOS 15.2+`, `iOS 26+`).

## Schema Generation

Translates runtime `[IntentDescriptor]` instances into `DynamicGenerationSchema` and `GenerationSchema` instances passed directly to `LanguageModelSession.respond(to:schema:)`.

## Availability State

Provides `ModelAvailabilityCheck.checkAvailability()` to detect whether Apple Intelligence is enabled, model assets are ready, or if mock fallbacks are required.
