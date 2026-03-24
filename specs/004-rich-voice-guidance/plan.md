# Implementation Plan: Rich Voice Guidance

**Branch**: `004-rich-voice-guidance` | **Date**: 2026-03-24 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/004-rich-voice-guidance/spec.md`

## Summary

Expand every exercise's `audioCues` dictionary in `Models.swift` from sparse 1–2 cues to a full, structured coaching script. The 61 exercises currently have ~110 cues total; the target is ~290 cues (~180 net new). No schema changes, no new model types, no migration — purely content edits to existing `audioCues: [Int: String]` fields in the seed data.

## Technical Context

**Language/Version**: Swift 5.9+ (Xcode 26.2 toolchain)
**Primary Dependencies**: AVFoundation / `TTSManager` (existing) — no new dependencies
**Storage**: SwiftData (`Exercise.audioCues: [Int: String]`) — schema unchanged
**Testing**: XCTest — manual blind walkthrough for SC-004; inspection for SC-001–SC-003, SC-005
**Target Platform**: iOS 17.0+
**Project Type**: Mobile app (iOS)
**Performance Goals**: TTS fires within ±1 second of the cue's elapsed-second key — existing timer behaviour, no change
**Constraints**: ≤8 words per cue value (TTS ≈ 2.5 words/second → ≤3 seconds of speech per cue); all cue keys must be unique within an exercise
**Scale/Scope**: 61 exercises, ~180 new cues to write, one source file modified (`daily/Models.swift`)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. SwiftUI-First | ✅ PASS | No new UI views; feature is data-only |
| II. SwiftData for Persistence | ✅ PASS | No new `@Model` types; no schema changes; `audioCues` field already exists on `Exercise`; seed delivered via existing `Exercise.seedInitialData` |
| III. Offline-First | ✅ PASS | All cues bundled in seed data at compile time; no network access required |
| IV. Personalization Without Gatekeeping | ✅ PASS | No change to gender-focus logic; cue content is exercise-specific, not gender-gated |
| V. Simplicity | ✅ PASS | Direct edits to `audioCues` dictionaries in `Models.swift`; no abstraction, no new files, no helpers required |

**Post-design re-check**: All five principles still pass. No complexity violations to declare.

## Project Structure

### Documentation (this feature)

```text
specs/004-rich-voice-guidance/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output — cue audit + contract
├── quickstart.md        # Phase 1 output — integration scenarios
├── checklists/
│   └── requirements.md  # Spec quality gate (all pass)
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
daily/
└── Models.swift         # ONLY FILE MODIFIED — audioCues dictionaries updated
                         # for all 61 exercises across 5 categories
```

No new files. No new directories. No new Swift types. No Xcode project changes.

**Structure Decision**: Single-file edit. All 61 exercise definitions live in `Models.swift` inside category-specific factory functions (`originalStretchingExercises()`, `originalBreathingExercises()`, `originalBodyweightExercises()`, `originalBalanceExercises()`, and the pelvic-floor exercises). Edits are targeted replacements of the `audioCues` dictionary literal for each exercise.

## Complexity Tracking

> No Constitution Check violations. Table left blank intentionally.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
