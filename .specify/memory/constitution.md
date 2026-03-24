<!--
SYNC IMPACT REPORT
==================
Version change: (unset / all-placeholder) → 1.0.0
Bump rationale: Initial ratification — all placeholder tokens replaced with
  project-specific values. Classified as MINOR (1.0.0) because this is first
  substantive content; no prior version existed to compare against.

Modified principles:
  (none — all are new)

Added sections:
  - Core Principles (5 principles)
  - Platform & Technical Standards
  - Development Workflow
  - Governance

Removed sections:
  (none)

Templates reviewed:
  ✅ .specify/templates/plan-template.md — "Constitution Check" section is
     generic and compatible with the five principles defined here.
  ✅ .specify/templates/spec-template.md — No principle-specific sections;
     user-story and requirements structure aligns with Principle V (simplicity /
     independent testability).
  ✅ .specify/templates/tasks-template.md — Phase structure and [P] parallel
     markers align with Principle V. No principle-driven task types need adding
     at this time.
  ✅ .specify/templates/constitution-template.md — Source template; no changes
     required.

Deferred TODOs:
  None — all fields resolved from codebase inspection.
-->

# daily Constitution

## Core Principles

### I. SwiftUI-First

All UI MUST be implemented using SwiftUI components and layout primitives.
UIKit is permitted only for system APIs that have no SwiftUI equivalent
(e.g., `UIImagePickerController`, `AVSpeechSynthesizer` wrappers via
`NSObject` subclasses). Every View MUST be independently previewable via
`#Preview` or `PreviewProvider`. Views MUST access SwiftData through the
`.modelContext` / `@Query` environment — never through manually threaded
model containers.

### II. SwiftData for Persistence

All user-generated and app-seeded data MUST be stored via SwiftData `@Model`
entities registered in `dailyApp.sharedModelContainer`. The following are
PROHIBITED:
- Direct CoreData stack usage (`NSPersistentContainer`, etc.)
- `UserDefaults` for model-level data (flags and lightweight preferences are
  acceptable)
- Ad-hoc file-based storage for content that belongs in the data model

Every new `@Model` class MUST be added to the `Schema` in `dailyApp.swift`
before use. Schema-breaking changes MUST be accompanied by a
`SchemaMigrationPlan`.

### III. Offline-First

All core features — browsing exercises, executing routines, tracking streaks
and XP, and viewing the profile — MUST function without any network
connectivity. Specifically:
- Seed content MUST be bundled within the app target and inserted once on
  first launch via `Exercise.seedInitialData(context:)`.
- No network requests are permitted for core workout or routine functionality.
- Notification scheduling and TTS audio MUST rely only on on-device system
  frameworks (`UserNotifications`, `AVFoundation`).

### IV. Personalization Without Gatekeeping

Gender-personalized content (the `genderFocus` property on `Exercise`) is an
OPTIONAL enhancement, not an access-control mechanism. The following rules
MUST hold:
- Gender-neutral exercises (where `genderFocus == nil`) MUST always be
  available to every user regardless of profile settings.
- Gendered exercises supplement the neutral set; they MUST NOT be the sole
  option in any routine or category.
- UI copy personalization (e.g., "Keep it up!" vs "Stay strong!") MUST fall
  back gracefully to a neutral string when `gender == .unspecified`.

### V. Simplicity & No Premature Abstraction

The minimum viable structure for any feature is the correct starting point.
The following rules apply:
- View Models, Coordinators, Router patterns, or custom DI containers MUST
  NOT be introduced unless a concrete, demonstrable problem cannot be solved
  with SwiftUI's built-in `@Environment`, `@Query`, `@State`, and
  `ObservableObject` patterns.
- YAGNI applies: three concrete, clear implementations are preferred over one
  speculative abstraction.
- Any complexity beyond the minimum MUST be justified in the plan's
  Complexity Tracking table before implementation begins.

## Platform & Technical Standards

- **Minimum deployment target**: iOS 17.0 (required by SwiftData).
- **Language**: Swift 5.9+. No Objective-C files except auto-generated
  bridging headers.
- **Dependencies**: Zero third-party Swift Package Manager dependencies in
  the current codebase. Any new SPM dependency MUST be discussed and approved
  before being added; justify why a system framework cannot solve the problem.
- **Audio**: `AVFoundation` / `AVSpeechSynthesizer` via `TTSManager` for all
  text-to-speech. No third-party TTS libraries.
- **Notifications**: `UserNotifications` framework only, via
  `NotificationManager`. Notification identifiers MUST be stable string
  constants, not inline literals.
- **Testing**: `XCTest` for unit and UI tests. Test targets MUST use
  `inMemory: true` model containers to avoid polluting persistent storage.

## Development Workflow

- Feature branches are numbered sequentially (per `.specify/init-options.json`
  `branch_numbering: "sequential"`).
- Every Swift view file that introduces a new `View` MUST include a
  corresponding `#Preview` block.
- When a new `@Model` type is created, registering it in
  `dailyApp.sharedModelContainer`'s `Schema` is part of the same commit —
  never deferred.
- Commits MUST be made after each logically complete task unit (not batched
  across multiple unrelated changes).
- The `speckit` workflow governs feature specification: `speckit.specify` →
  `speckit.plan` → `speckit.tasks` → `speckit.implement`.

## Governance

This constitution supersedes all prior oral conventions or ad-hoc practices.

**Amendment procedure**:
1. Open a branch and update `.specify/memory/constitution.md` with the
   proposed change and a version bump per the semver rules below.
2. Review the Sync Impact Report (HTML comment at top of file) to identify
   dependent templates and update them in the same PR.
3. Merge only after the author has verified no existing specs or plans
   contradict the amended principle.

**Versioning policy** (semantic versioning):
- MAJOR: Backward-incompatible governance change, principle removal, or
  redefinition that invalidates existing specs.
- MINOR: New principle, new mandatory section, or materially expanded
  guidance.
- PATCH: Clarifications, wording improvements, typo fixes.

**Compliance review**:
- Every `speckit.plan` execution MUST include a "Constitution Check" gate
  verifying the planned feature satisfies all five Core Principles.
- Any violation MUST be documented in the plan's Complexity Tracking table
  with justification before implementation.

**Version**: 1.0.0 | **Ratified**: 2026-03-24 | **Last Amended**: 2026-03-24
