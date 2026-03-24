# Implementation Plan: Exercise Library Review & Reorganization

**Branch**: `002-exercise-review` | **Date**: 2026-03-24 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/002-exercise-review/spec.md`

## Summary

Replace the Kegels dashboard tile with a new Balance category, move all kegel exercises into Stretching, and add 14 new exercises across all four categories (3 stretching, 2 breathing, 3 bodyweight, 6 balance). Balance exercises include safety-conscious instructions advising users to keep a chair nearby for support — especially important for elderly users. A data migration ensures existing users' kegel exercises are re-categorized and new exercises are inserted on app update.

## Technical Context

**Language/Version**: Swift 5.9+ (project created with Xcode 26.2 / toolchain 2630)
**Primary Dependencies**: SwiftUI, SwiftData, AVFoundation, UserNotifications, PhotosUI (all system frameworks, zero third-party)
**Storage**: SwiftData — local on-device SQLite; `UserDefaults` via `@AppStorage` for lightweight preferences
**Testing**: Manual verification (no automated tests currently)
**Target Platform**: iOS 17+
**Project Type**: Single-target iOS mobile app
**Performance Goals**: 60 fps UI; no performance concerns for seed data changes
**Constraints**: Offline-first; zero third-party packages; no network access for core features

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. SwiftUI-First | ✅ Pass | No new views required. Changes are limited to data model (enum + seed data) and one line in the dashboard category list. No UIKit additions. |
| II. SwiftData for Persistence | ✅ Pass | Exercise `@Model` entity unchanged. No new `@Model` types. Migration uses existing SwiftData context to update stored exercises. No `SchemaMigrationPlan` needed — the schema shape is identical; only stored enum raw values change. |
| III. Offline-First | ✅ Pass | All new exercise content is bundled in the app. Migration runs locally. Zero network access. |
| IV. Personalization Without Gatekeeping | ✅ Pass | All 14 new exercises are gender-neutral (`genderFocus: nil`). Existing gender-focused kegel exercises retain their focus when moved to Stretching. No gendered exercise is the sole option in any category. |
| V. Simplicity & No Premature Abstraction | ✅ Pass | Minimal changes — enum value addition, seed data expansion, one-time migration function. No new patterns, abstractions, or architectural changes. |

**All gates pass. No Complexity Tracking entries required.**

## Project Structure

### Documentation (this feature)

```text
specs/002-exercise-review/
├── plan.md              ← this file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
└── tasks.md             ← Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
daily/                            ← iOS app source (all .swift files compiled via
│                                   PBXFileSystemSynchronizedRootGroup)
├── Models.swift                  # MODIFY: Add .balance enum case, add icon, update
│                                 #   kegelExercises() → category .stretching,
│                                 #   add balanceExercises(), add new exercises to
│                                 #   existing methods, add migrateData(), update
│                                 #   seedInitialData() to call migration + include
│                                 #   balance exercises
├── ContentView.swift             # MODIFY: Replace ExerciseCategory.allCases with
│                                 #   ExerciseCategory.displayCategories (filtered list
│                                 #   excluding .kegels, including .balance)
├── dailyApp.swift                # unchanged
├── ExerciseListView.swift        # unchanged — category filter works with any category
├── ProfileView.swift             # unchanged
├── NotificationManager.swift     # unchanged
├── OnboardingView.swift          # unchanged
├── RoutineDetailView.swift       # unchanged
├── BreathingView.swift           # unchanged (dead code)
└── TTSManager.swift              # unchanged
```

**Structure Decision**: Single iOS target. Two files modified (`Models.swift`, `ContentView.swift`). No new files created.

## Phase 0: Research

See [research.md](research.md).

## Phase 1: Design

See [data-model.md](data-model.md) and [quickstart.md](quickstart.md).

No contracts directory: this is a self-contained iOS app with no external interfaces.

## Complexity Tracking

> No constitution violations found — table left empty.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| — | — | — |
