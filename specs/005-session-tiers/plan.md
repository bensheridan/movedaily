# Implementation Plan: Session Duration Tiers

**Branch**: `005-session-tiers` | **Date**: 2026-03-24 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/005-session-tiers/spec.md`

## Summary

Add three session duration tiers (10-12 min / 15-20 min / 20-30 min) locked behind experience levels (Beginner / Intermediate / Advanced). Calibrate the existing XP + level system so a user completing one routine per day reaches Intermediate in ≈30 days and Advanced in ≈90 days. Add a level-up celebration that announces the newly unlocked tier. Extend seed data to support longer sessions. All changes are within `daily/Models.swift`, `daily/ContentView.swift`, and optionally `daily/ProfileView.swift` — no new dependencies, no schema migration required.

## Technical Context

**Language/Version**: Swift 5.9+ (Xcode 26.2 toolchain)
**Primary Dependencies**: SwiftUI, SwiftData, `@AppStorage` — all system frameworks, zero third-party
**Storage**: SwiftData for model-level data (`UserProfile`, `Routine`, `Exercise`); `@AppStorage` for the lightweight `preferredSessionTier` preference
**Testing**: XCTest (manual device/Simulator verification; no automated test target in current project)
**Target Platform**: iOS 17.0+
**Project Type**: Mobile app (SwiftUI + SwiftData, offline-first)
**Performance Goals**: Session generation completes in < 50 ms on any supported device (trivial list filter + sort over ≤61 exercises)
**Constraints**: Offline-only; zero network requests; no schema migration (all changes additive or preference-level); `preferredSessionTier` stored in `UserDefaults` via `@AppStorage` (not a SwiftData field)
**Scale/Scope**: 1 user profile, 61 exercises, ≤10 seeded routines → extends to ≤20 routines

## Constitution Check

*GATE: Must pass before implementation begins.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. SwiftUI-First | ✅ PASS | All new UI (tier picker, level-up banner) uses SwiftUI components; every new View has a `#Preview` block |
| II. SwiftData for Persistence | ✅ PASS | `ExperienceTier` is a computed property on `UserProfile`; `preferredSessionTier` is a lightweight preference stored via `@AppStorage` (explicitly permitted by constitution Principle II) |
| III. Offline-First | ✅ PASS | All logic is on-device; longer routines are seeded via `Exercise.seedInitialData`; no network calls added |
| IV. Personalization Without Gatekeeping | ✅ PASS | Session tiers are time-based, not gender-gated; gender-neutral exercises remain available at all tiers |
| V. Simplicity & No Premature Abstraction | ✅ PASS | `ExperienceTier` is a simple enum; session generation is a single static function; no View Models or custom DI introduced |

**Gate Result**: All 5 principles pass — implementation may proceed.

## Project Structure

### Documentation (this feature)

```text
specs/005-session-tiers/
├── plan.md              ← This file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
├── checklists/
│   └── requirements.md
└── tasks.md             ← Phase 2 output (/speckit.tasks)
```

### Source Code (modified files only)

```text
daily/
├── Models.swift          ← ExperienceTier enum + UserProfile extensions + longer seed routines
├── ContentView.swift     ← SessionTierPicker, LevelUpBanner, DashboardView wiring
└── ProfileView.swift     ← Show current tier badge next to level (minor addition)
```

No new Swift files are required for this feature — all additions fit naturally into existing files. If `ContentView.swift` grows beyond ~350 lines from additions, the tier picker may be extracted to a dedicated `SessionTierPickerView.swift`, but that decision is deferred until implementation.

## Complexity Tracking

> No constitution violations — table is empty.

