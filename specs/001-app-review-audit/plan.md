# Implementation Plan: App Review & Bug Fix Audit

**Branch**: `001-app-review-audit` | **Date**: 2026-03-24 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-app-review-audit/spec.md`

## Summary

Five bugs found across the app during a full source review. All are targeted
fixes — no new architecture, no new dependencies. The fixes address: (1) an
old completion-logic extension that shadows the correct implementation and
causes broken streak/XP behaviour; (2) an exercise timer that fires completion
feedback on every tick after it reaches zero; (3) a ProfileView wrapped in a
redundant NavigationView with editable Level/XP steppers; and (4+5) a more
complete ProfileView implementation sitting in the wrong directory, plus an
API signature mismatch in NotificationManager that prevents it compiling.

## Technical Context

**Language/Version**: Swift 5.9+ (project created with Xcode 26.2 / toolchain 2630)
**Primary Dependencies**: SwiftUI, SwiftData, AVFoundation, UserNotifications, PhotosUI (all system frameworks, zero third-party)
**Storage**: SwiftData — local on-device SQLite; `UserDefaults` via `@AppStorage` for lightweight preferences (reminder toggle/time)
**Testing**: XCTest (manual verification for this fix set; no automated UI tests currently)
**Target Platform**: iOS 17+ (required by SwiftData)
**Project Type**: Single-target iOS mobile app
**Performance Goals**: 60 fps UI; no performance concerns for targeted bug fixes
**Constraints**: Offline-first; zero third-party packages; no network access for core features

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. SwiftUI-First | ✅ Pass | All fixes are within existing SwiftUI views; no UIKit additions beyond the existing `UIImpactFeedbackGenerator` and `PHPickerViewController` wrappers already in the codebase |
| II. SwiftData for Persistence | ✅ Pass | No persistence layer changes; `UserProfile` model is correct as-is |
| III. Offline-First | ✅ Pass | All fixes operate entirely on-device |
| IV. Personalization Without Gatekeeping | ✅ Pass | No changes to exercise filtering or gender-focus logic |
| V. Simplicity & No Premature Abstraction | ✅ Pass | Each fix is the minimum targeted change; no new patterns or abstractions introduced |

**All gates pass. No Complexity Tracking entries required.**

## Project Structure

### Documentation (this feature)

```text
specs/001-app-review-audit/
├── plan.md              ← this file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
└── tasks.md             ← Phase 2 output (/speckit.tasks — not created here)
```

### Source Code (repository root)

```text
daily/                            ← iOS app source (all Swift files compiled via
│                                   PBXFileSystemSynchronizedRootGroup)
├── dailyApp.swift                # unchanged
├── Models.swift                  # unchanged — correct completeRoutine(baseXP:) lives here
├── ContentView.swift             # FIX 1: remove duplicate completeRoutine() extension
├── ExerciseListView.swift        # FIX 2: add timerCompleted flag; move .buttonStyle() to Button
├── ProfileView.swift             # FIX 3+4: replace with improved version from wrong directory
├── NotificationManager.swift     # FIX 5: add scheduleDailyReminder(at:) string convenience overload
├── OnboardingView.swift          # unchanged
├── RoutineDetailView.swift       # unchanged
├── BreathingView.swift           # DEAD CODE — no action required for this fix set
└── TTSManager.swift              # unchanged

daily.xcodeproj/
└── ProfileView.swift             # SOURCE for FIX 3+4 — move contents to daily/ProfileView.swift
                                  # (file in .xcodeproj is not compiled; it is the better version)
```

**Structure Decision**: Single iOS target. All fixes touch existing files only.
No new files created. The improved ProfileView content moves from the accidental
`.xcodeproj/` location into the `daily/` source directory, replacing the current
`daily/ProfileView.swift`.

## Phase 0: Research

See [research.md](research.md).

## Phase 1: Design

See [data-model.md](data-model.md) and [quickstart.md](quickstart.md).

No contracts directory: this is a self-contained iOS app with no external
interfaces (no public APIs, no CLI, no inter-process communication).

## Complexity Tracking

> No constitution violations found — table left empty.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
