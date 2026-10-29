# Intent State Machine & Lifecycle

```
idle
  │
  ▼
inputChanged
  │
  ▼
debouncing
  │
  ▼
identifying (Inference)
  │
  ├──► partialPreview / proposals
  │
  ▼
ready for commit
  │
  ├──► cancelled / inputChanged (discard)
  └──► committing (Validate context revision & Execute commit handler)
```

## Concurrency Guarantees

- **Scenario A**: Monotonically increasing revision numbers ensure superseded input results are safely ignored.
- **Scenario B**: Commit attempts during pending inference re-validate available proposals.
- **Scenario C**: Stale application context triggers `IntentError.contextStale` during commit validation.
- **Scenario D**: Sequential request queueing prevents concurrent calls to a single `LanguageModelSession`.
