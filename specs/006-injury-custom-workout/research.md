# Research: Injury & Custom Workout Builder

**Branch**: `006-injury-custom-workout` | **Phase**: 0 | **Date**: 2026-04-19

## Decision 1: SwiftData Migration Strategy

**Decision**: Use lightweight automatic migration (default values on new properties). No explicit `SchemaMigrationPlan` required.

**Rationale**: iOS 17 SwiftData handles adding new optional-or-defaulted properties to existing `@Model` classes transparently. The two new fields (`activeInjuries: [String]` on `UserProfile`, `contraindications: [String]` on `Exercise`) both default to `[]`, making them safe to add without a versioned migration plan. `CustomExercise` is a net-new `@Model` class and simply needs to be appended to the `Schema` array in `dailyApp.swift` — no migration step required for new models.

**Alternatives considered**:
- Explicit `SchemaMigrationPlan` — rejected as unnecessary overhead for additive-only changes with sensible defaults.
- Separate JSON sidecar for contraindications — rejected; keeping data in SwiftData keeps the model authoritative and offline.

---

## Decision 2: Injury Type Representation

**Decision**: `InjuryType` as a `String`-backed enum defined in `Models.swift`. Six cases covering the most common exercise-relevant conditions for a wellness app: `.lowerBack`, `.shoulder`, `.knee`, `.wristElbow`, `.ankleFoot`, `.neck`.

**Rationale**: A predefined enum ensures reliable contraindication mapping (no free-text typos), is lightweight, and maps cleanly to the `[String]` raw-value arrays stored on `UserProfile.activeInjuries` and `Exercise.contraindications`. Six injury types covers the overwhelming majority of user needs for a daily wellness app without over-engineering the taxonomy.

**Alternatives considered**:
- Free-text injury entry — rejected; makes contraindication mapping impossible without an NLP layer.
- Separate `Injury` `@Model` — rejected; the injury list is static (predefined), so a `@Model` adds SwiftData overhead for no benefit. An enum stored as `[String]` on `UserProfile` is sufficient.

---

## Decision 3: Contraindication Mapping Approach

**Decision**: Each `Exercise` carries a `contraindications: [String]` field (raw values of `InjuryType`). Filtering is applied at session-build time in `Routine.buildSession` and in the custom workout builder — both already iterate the exercise pool, making injection of one additional `.filter` step trivial.

**Rationale**: Data-local approach; the contraindication relationship lives on the exercise where it semantically belongs. The seed data method (`Exercise.seedInitialData`) already sets per-exercise properties — adding `contraindications:` to each seed call is consistent with existing patterns.

**Alternatives considered**:
- Separate contraindication lookup table — rejected as premature abstraction (Principle V).
- Category-level contraindication only (e.g., all Bodyweight exercises blocked for knee) — rejected as too coarse; a user with a knee injury should still be able to do upper-body bodyweight exercises.

---

## Decision 4: Custom Workout Builder Entry Point

**Decision**: A full-screen sheet launched from the `DashboardView` via a new "Build your own" button on the `DailyRoutineCard` or below it. The sheet is `CustomWorkoutBuilderView`.

**Rationale**: The existing pattern in the app uses `sheet(item:)` for modal flows (e.g., `LevelUpView`). A sheet keeps the dashboard as the navigation root and makes the custom session feel like a one-off alternative to the auto-generated session rather than replacing it permanently.

**Alternatives considered**:
- New tab or top-level navigation item — rejected; adds global nav weight for a supplemental feature.
- NavigationLink pushing into the stack — rejected; the builder is a transient session-creation flow, not a content drill-down.

---

## Decision 5: Custom Exercise Persistence

**Decision**: New `@Model class CustomExercise` with `name: String` and `durationSeconds: Int`. Registered in `dailyApp.sharedModelContainer` Schema. Displayed in `CustomWorkoutBuilderView` as a reusable list; user taps to add to the current session.

**Rationale**: Constitution Principle II mandates SwiftData for all persisted user-generated data. A dedicated `@Model` is the minimal correct structure — one class, two fields.

**Alternatives considered**:
- `@AppStorage` JSON blob — rejected by Principle II (model-level data must use SwiftData).
- Storing custom exercises inside `Routine.exerciseNames` as a special prefix — rejected as a hack that pollutes the exercise name space.
