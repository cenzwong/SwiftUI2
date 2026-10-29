# Feasibility & Performance Report

## Phase 0 Technical Findings

1. **Schema Dynamic Construction**: Apple Foundation Models supports dynamic schema generation via `DynamicGenerationSchema` and `GenerationSchema(root:dependencies:)`.
2. **Session Concurrency**: `LanguageModelSession` requires strict single-request isolation. `SessionManager` provides actor-based request queuing.
3. **Latency Benchmarks**:
   - UI Input Debounce: Configurable (default 300ms, reduced to 50ms in test environment).
   - Local Input Feedback: < 10ms on MainActor.
   - Foundation Models Inference (P50): ~150-350ms on A17 Pro / M3 / Apple Intelligence hardware.
   - Side effects during preview: 0ms (strictly isolated).
