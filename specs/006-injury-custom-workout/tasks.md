# Tasks: Injury & Custom Workout Builder

**Input**: Design documents from `/specs/006-injury-custom-workout/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅

**Tests**: Not requested — no test tasks included.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

---

## Phase 1: Setup

**Purpose**: Confirm clean baseline before any changes land.

- [x] T001 Verify the project builds cleanly on branch `006-injury-custom-workout` in Xcode before making any changes

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: All data model changes that every user story depends on. Must be complete before any UI work begins.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T002 Add `InjuryType` enum to `daily/Models.swift` — `String`-backed, `CaseIterable`, `Identifiable`, `Codable`; six cases: `.lowerBack`, `.shoulder`, `.knee`, `.wristElbow`, `.ankleFoot`, `.neck`; add `displayName: String` and `icon: String` computed properties
- [x] T003 Add `contraindications: [String]` field (default `[]`) to the `Exercise` `@Model` class in `daily/Models.swift`
- [x] T004 Add `activeInjuries: [String]` field (default `[]`) to the `UserProfile` `@Model` class in `daily/Models.swift`
- [x] T005 Add new `@Model class CustomExercise` to `daily/Models.swift` with fields `name: String` and `durationSeconds: Int`
- [x] T006 Register `CustomExercise.self` in the `Schema` array inside `dailyApp.sharedModelContainer` in `daily/dailyApp.swift`
- [x] T007 Update `Exercise.seedInitialData(context:)` in `daily/Models.swift` to populate `contraindications` for every seeded exercise using `InjuryType` raw values — breathing exercises get `[]`; bodyweight push/plank exercises get `[.shoulder, .wristElbow]`; bodyweight squat/lunge exercises get `[.knee, .ankleFoot]`; balance single-leg exercises get `[.knee, .ankleFoot]`; neck stretches get `[.neck]`; lower-back stretches get `[.lowerBack]`
- [x] T008 Update `Routine.buildSession(tier:exercises:profile:)` in `daily/Models.swift` to add an injury filter step: after the gender filter, exclude any exercise where `Set(exercise.contraindications).intersection(Set(profile.activeInjuries))` is non-empty

**Checkpoint**: Build must succeed with no SwiftData schema errors before proceeding. Launch app on simulator to confirm existing sessions still generate correctly.

---

## Phase 3: User Story 1 — Indicate an Injury (Priority: P1) 🎯 MVP

**Goal**: Users can record one or more active injuries in their profile; the auto-generated daily session excludes contraindicated exercises.

**Independent Test**: Set a shoulder injury in Profile → go to Dashboard → start Today's Session → confirm no shoulder-contraindicated exercises appear in the routine list.

- [x] T009 [US1] Create `daily/InjuryPickerView.swift` — a SwiftUI `View` that shows all `InjuryType` cases as a scrollable list with a checkmark toggle for each; reads/writes to `profile.activeInjuries` via `@Environment(\.modelContext)`; include a `#Preview` block
- [x] T010 [US1] Modify `daily/ProfileView.swift` to add an "Active Injuries" section below the gender selector — show existing active injury names as tag chips (or "None" when empty); add a "Edit Injuries" button that presents `InjuryPickerView` as a sheet
- [x] T011 [US1] Verify end-to-end in simulator: set lower-back injury → return to Dashboard → confirm lower-back-contraindicated exercises are absent from the generated session; clear injury → confirm full pool restores

**Checkpoint**: User Story 1 is fully functional and testable independently at this point.

---

## Phase 4: User Story 2 — Custom Workout Builder (Priority: P2)

**Goal**: Users can build a one-off session by multi-selecting from the four exercise categories; the assembled session respects the current session tier duration and any active injury restrictions.

**Independent Test**: Open builder → select Stretching + Breathing → confirm → verify `RoutineDetailView` shows only exercises from those two categories (no Bodyweight or Balance exercises present).

- [x] T012 [US2] Create `daily/CustomWorkoutBuilderView.swift` — a SwiftUI `View` presented as a full-screen sheet; show the four `ExerciseCategory.displayCategories` as a 2×2 multi-select grid using the same category icons as `DashboardView`; show a live estimated duration label that updates as categories are toggled; disable the "Build Session" button when no categories are selected and show an inline error message
- [x] T013 [US2] Implement session assembly inside `CustomWorkoutBuilderView`: on "Build Session" tap, filter `allExercises` to selected categories and apply the same injury filter from T008 (`Set(contraindications).intersection(activeInjuries).isEmpty`), then greedy-fill to the current `SessionTier` duration range; pass the resulting `[String]` of exercise names to `RoutineDetailView` as the session; include a `#Preview` block
- [x] T014 [US2] Modify `daily/ContentView.swift` (`DashboardView`) to add a "Build your own" button below `DailyRoutineCard`; wire it to a `sheet(isPresented:)` presenting `CustomWorkoutBuilderView`

**Checkpoint**: User Story 2 works independently — custom builder opens, categories can be toggled, session assembles and launches correctly.

---

## Phase 5: User Story 3 — Add a Custom Exercise (Priority: P3)

**Goal**: Users can add a personal exercise (name + duration) to any custom session; saved custom exercises persist and are available for reuse.

**Independent Test**: Tap "Add my own exercise" → enter "Physio Hip Rotation" + 90 seconds → confirm → verify the exercise appears in the current session with correct name and duration; close and reopen builder → verify it appears in "My Exercises" list.

- [x] T015 [US3] Extend `daily/CustomWorkoutBuilderView.swift` to add a "My Exercises" section below the category grid — query all `CustomExercise` records via `@Query`; show each with a toggle to include/exclude it in the current session; show an "Add my own exercise" button that reveals an inline form with a name text field and a duration number field; validate on submit (non-empty name, duration > 0); save valid entries as new `CustomExercise` via `modelContext.insert`
- [x] T016 [US3] Extend session assembly in `CustomWorkoutBuilderView` (T013) to append all user-selected `CustomExercise` entries to the session's exercise name list; ensure custom exercise names are passed through to `RoutineDetailView` and displayed correctly alongside standard exercises

**Checkpoint**: All three user stories are independently functional.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Injury feedback notice in the auto-generated session flow; edge-case hardening.

- [x] T017 [P] Modify `daily/ContentView.swift` (`DashboardView`) to detect when injury filtering has reduced the session pool below the tier's minimum duration — show a non-blocking inline notice (e.g., a banner or subtitle on `DailyRoutineCard`) explaining that some exercises were removed due to the active injury; the notice should disappear when no injury is active
- [x] T018 [P] Handle the empty-pool edge case in `Routine.buildSession` in `daily/Models.swift`: if the filtered pool yields zero exercises, return an empty array rather than crashing; handle the empty array gracefully in `DashboardView` (show a "No exercises available for your current injury settings" message instead of a broken routine card)

**Checkpoint**: Run all 10 verification scenarios from `plan.md` before marking feature complete.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — **blocks all user stories**
- **US1 (Phase 3)**: Depends on Phase 2 — can start as soon as T008 is complete
- **US2 (Phase 4)**: Depends on Phase 2 — can start as soon as T008 is complete
- **US3 (Phase 5)**: Depends on Phase 4 (T012, T013 must exist to extend) — sequential with US2
- **Polish (Phase 6)**: Depends on Phase 2 complete; T017/T018 are independent of US1–US3

### User Story Dependencies

- **US1 (P1)**: Starts after Phase 2. No dependency on US2 or US3.
- **US2 (P2)**: Starts after Phase 2. No dependency on US1 (injury filter is shared from T008).
- **US3 (P3)**: Extends US2's view file — implement after T012 and T013 are complete.

### Within Each Phase

- T002 → T003, T004, T005 (InjuryType enum must exist before referencing its raw values)
- T005 → T006 (model must exist before Schema registration)
- T002, T003 → T007 (enum + field must exist before seeding)
- T003, T004 → T008 (both fields must exist before filtering)
- T012, T013 → T015, T016 (view must exist before extending it)

### Parallel Opportunities

- T003 and T004 touch different `@Model` classes but are in the same file — edit sequentially
- T009 (`InjuryPickerView.swift`) and T012 (`CustomWorkoutBuilderView.swift`) are **new files** — fully parallelizable once Phase 2 is complete
- T017 and T018 are independent — can be done in parallel

---

## Parallel Example: Once Phase 2 Is Complete

```
# These two tasks can run simultaneously (different new files):
Task T009: Create daily/InjuryPickerView.swift          [US1]
Task T012: Create daily/CustomWorkoutBuilderView.swift  [US2]

# These two polish tasks can run simultaneously:
Task T017: Add injury notice banner in ContentView.swift
Task T018: Handle empty-pool edge case in Models.swift
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational (T002–T008)
3. Complete Phase 3: User Story 1 (T009–T011)
4. **STOP and VALIDATE**: Injury appears in Profile, daily session excludes contraindicated exercises
5. Ship MVP — injury safety is live

### Incremental Delivery

1. Setup + Foundational → data model ready
2. US1 → injury indication live (MVP)
3. US2 → custom workout builder live
4. US3 → custom exercise entry live
5. Polish → injury notice + edge cases hardened

---

## Notes

- All new `.swift` files belong in `daily/` (Xcode auto-syncs all files in that directory)
- Every new `View` file requires a `#Preview` block (Constitution Principle I)
- `CustomExercise` must be in the Schema before first launch on any device (T006 is critical)
- The injury filter in T008 must use set intersection — a simple `.contains` check on a single injury is insufficient when multiple injuries are active
- Commit after each phase checkpoint, not after every individual task
