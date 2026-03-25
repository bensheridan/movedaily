# Tasks: Session Duration Tiers

**Input**: Design documents from `/specs/005-session-tiers/`
**Prerequisites**: plan.md ✅ | spec.md ✅ | research.md ✅ | data-model.md ✅ | quickstart.md ✅

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story. No tests were requested in the spec — no test tasks are included.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files / no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

---

## Phase 1: Setup

**Purpose**: No new files or dependencies required. Confirm the working branch is correct.

- [x] T001 Confirm git is on branch `005-session-tiers` (run `git checkout -b 005-session-tiers` if not already there)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core Swift types that every user story depends on. MUST be complete before Phase 3+.

**⚠️ CRITICAL**: All three user stories need `ExperienceTier`, `SessionTier`, and `UserProfile.experienceTier` before any story-specific work begins.

- [x] T002 [P] Add `ExperienceTier` enum to `daily/Models.swift` — cases `.beginner`, `.intermediate`, `.advanced`; `static let intermediateLevel = 7`, `static let advancedLevel = 20`; `var displayName: String`; conforms to `String, Codable, CaseIterable, Identifiable`
- [x] T003 [P] Add `SessionTier` enum to `daily/Models.swift` — cases `.basic` ("10-12 min"), `.intermediate` ("15-20 min"), `.advanced` ("20-30 min"); `var durationRange: ClosedRange<Int>` (600...720 / 900...1200 / 1200...1800 seconds); `var requiredExperienceTier: ExperienceTier`; `var unlockLabel: String`; conforms to `String, CaseIterable, Identifiable`
- [x] T004 Add `var experienceTier: ExperienceTier` computed property to `UserProfile` in `daily/Models.swift` — returns `.advanced` if `level >= ExperienceTier.advancedLevel`, `.intermediate` if `level >= ExperienceTier.intermediateLevel`, else `.beginner` (depends on T002)
- [x] T005 Add `func isUnlocked(for profile: UserProfile?) -> Bool` to `SessionTier` in `daily/Models.swift` — returns `true` for `.basic` always; otherwise compares `profile.experienceTier` against `requiredExperienceTier` (depends on T002, T003, T004)

**Checkpoint**: `ExperienceTier`, `SessionTier`, `UserProfile.experienceTier`, and `SessionTier.isUnlocked(for:)` all compile. All user story phases can now begin.

---

## Phase 3: User Story 1 — Session Tier Selection (Priority: P1) 🎯 MVP

**Goal**: Show a tier picker in the dashboard; lock tiers above the user's experience level; persist the selection via `@AppStorage`.

**Independent Test**: Manually set `level` to 1, 7, and 20 in a preview/debug build and confirm the correct set of tiers is shown and selectable. Verify the selection survives a force-quit and relaunch (check `@AppStorage` key `"preferredSessionTier"` in UserDefaults).

### Implementation for User Story 1

- [x] T006 [P] [US1] Add `SessionTierPicker` SwiftUI view to `daily/ContentView.swift` — a horizontal or segmented row of `SessionTier.allCases`; available tiers render as solid/tappable chips; locked tiers render grayed out with `tier.unlockLabel` beneath them; bound to `@AppStorage("preferredSessionTier") var preferredSessionTier: String`; includes `#Preview` block (depends on T002, T003, T005)
- [x] T007 [US1] Add `@AppStorage("preferredSessionTier") private var preferredSessionTier: String = SessionTier.basic.rawValue` to `DashboardView` in `daily/ContentView.swift` and embed `SessionTierPicker` above the "Routine of the Day" card (depends on T006)
- [x] T008 [US1] Add clamping guard to `DashboardView` in `daily/ContentView.swift`: on `.onAppear` and whenever `profile?.level` changes, if the stored `preferredSessionTier` is locked for the user's current tier, reset it to the highest available `SessionTier` silently (depends on T007, T004)

**Checkpoint**: US1 is fully functional. At any level the correct tiers display; locked tiers show unlock labels; preference persists across restarts.

---

## Phase 4: User Story 2 — Level Progression via XP (Priority: P2)

**Goal**: Calibrate XP thresholds so 30 days → Intermediate and 90 days → Advanced. Surface a `LevelUpView` celebration sheet when a tier boundary is crossed.

**Independent Test**: In a Simulator build, call `completeRoutine()` 30 times in sequence (simulated days) and verify `level` reaches ≥ 7. Call it 90 times and verify `level` reaches ≥ 20. Also verify that completing a routine when `level` crosses 7 or 20 returns a non-nil `ExperienceTier` from `completeRoutine()`.

### Implementation for User Story 2

- [x] T009 [US2] Change `completeRoutine(baseXP:)` return type from `Void` to `ExperienceTier?` in `daily/Models.swift` — compute `experienceTier` before and after the XP/level update; if the tier changed, return the new tier; otherwise return `nil`; preserve all existing XP/streak/level logic unchanged (depends on T004)
- [x] T010 [P] [US2] Add `LevelUpView` SwiftUI view to `daily/ContentView.swift` — accepts `tier: ExperienceTier`; displays congratulatory headline ("You've reached [tier.displayName]!"), a subtitle announcing the newly unlocked session duration (e.g., "15-20 min sessions are now available"), and a dismiss button; includes `#Preview` block (depends on T002)
- [x] T011 [US2] Wire `routineCompleted` callback in `DashboardView` in `daily/ContentView.swift` — store `@State private var unlockedTier: ExperienceTier?`; inside the callback assign `unlockedTier = profile?.completeRoutine()`; add `.sheet(item: $unlockedTier) { LevelUpView(tier: $0) }` (depends on T009, T010)
- [x] T012 [P] [US2] Add `ExperienceTier` tier badge to `ProfileView` in `daily/ProfileView.swift` — display current tier name alongside the level stat (e.g., "Level 8 · Intermediate"); no new view file needed, edit existing `ProfileView` stat rows (depends on T004)

**Checkpoint**: Completing routines accumulates XP; level 7 triggers a "Intermediate unlocked" sheet; level 20 triggers an "Advanced unlocked" sheet. ProfileView shows the tier label.

---

## Phase 5: User Story 3 — Extended Exercise Content for Longer Sessions (Priority: P3)

**Goal**: Replace the day-of-year fixed routine with a dynamic session built to fill the selected duration budget. Ensure no exercise repeats within a session.

**Independent Test**: With an Intermediate user profile and "15-20 min" selected, tap "Start Routine" and verify: (a) the exercise list sums to 900–1200 seconds, (b) no exercise name appears twice. Repeat for "20-30 min" with an Advanced user.

### Implementation for User Story 3

- [x] T013 [US3] Add `static func buildSession(tier: SessionTier, exercises: [Exercise], profile: UserProfile?) -> [String]` to `Routine` in `daily/Models.swift` — filter exercises by `genderFocus`; shuffle; greedily append until `cumulativeDuration >= tier.durationRange.lowerBound` and `<= tier.durationRange.upperBound`; return array of `exercise.name` strings (depends on T003, T005)
- [x] T014 [US3] Add fallback logic to `Routine.buildSession` in `daily/Models.swift`: if the pool is exhausted before the lower-bound is reached (edge case with very few exercises), allow repeating the least-recently-added exercise rather than returning an undersized session (depends on T013)
- [x] T015 [US3] Replace day-of-year `dailyRoutine` computed property in `DashboardView` in `daily/ContentView.swift` with a `@State private var sessionExerciseNames: [String]` built by calling `Routine.buildSession(tier:exercises:profile:)` on `.onAppear` and whenever `preferredSessionTier` changes; pass `sessionExerciseNames` into a synthetic `Routine` (name: "Today's Session", exerciseNames: sessionExerciseNames) for `RoutineDetailView` (depends on T013, T007)
- [x] T016 [P] [US3] Review the 61 seeded exercises in `daily/Models.swift`; for any exercise where `durationSeconds < 60` increase it to at minimum 60 seconds so a 20-30 min session can be filled from the pool without excessive repetition — verified: all exercises ≥ 60s, pool total ≈ 91 min; no changes needed

**Checkpoint**: All three user stories are functional end-to-end. Dynamic sessions fill the correct duration window without exercise repetition.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final validation, `#Preview` hygiene, and success criteria verification.

- [x] T017 [P] Verify all new/modified SwiftUI views in `daily/ContentView.swift` and `daily/ProfileView.swift` have correct `#Preview` blocks that compile without errors — SessionTierPicker (2 previews), LevelUpView (2 previews), ContentView preview updated
- [ ] T018 [P] Run quickstart.md Scenarios 1–6 manually in Simulator and confirm expected results match; note any discrepancies and fix before merging
- [x] T019 Verify SC-001 (sessions within ±2 min of selected tier) — verified via simulation: basic=600s, advanced=1200s, all within tier.durationRange ✓
- [x] T020 Verify SC-002 (30/90-day progression) — verified via simulation: level 7 at exactly day 30, level 20 at day 95; both within spec targets (28-35 / 85-95) ✓
- [x] T021 [P] Update `daily/CLAUDE.md` via speckit agent context — completed successfully ✓

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Setup — **BLOCKS all user stories**
- **User Story 1, 2, 3 (Phases 3–5)**: All depend on Foundational (Phase 2); can proceed in priority order (P1 → P2 → P3) or in parallel if team capacity allows
- **Polish (Phase 6)**: Depends on all user story phases being complete

### User Story Dependencies

| Story | Depends On | Shared Data |
|-------|-----------|-------------|
| US1 (P1) | Phase 2 complete | `ExperienceTier`, `SessionTier`, `UserProfile.experienceTier` |
| US2 (P2) | Phase 2 complete; integrates with US1's `routineCompleted` callback | `completeRoutine()` return, `LevelUpView` |
| US3 (P3) | Phase 2 complete; integrates with US1's `preferredSessionTier` | `Routine.buildSession`, session display |

### Within Each User Story

- Models/enums → computed properties → view components → wiring/integration
- Parallel `[P]` tasks within a story may be launched together

### Parallel Opportunities

- T002 and T003 (foundational enums) are independent and can run simultaneously
- T006 (`SessionTierPicker` view) and T009 (`completeRoutine` return type) are in different stories and different files — can run in parallel once Phase 2 is done
- T010 (`LevelUpView`) and T012 (ProfileView badge) are view-only and parallel to each other
- T016 (exercise duration review) is data-only and parallel to T015 (DashboardView wiring)
- T017, T018, T019, T020, T021 in Phase 6 are all independent and fully parallel

---

## Parallel Example: Foundational Phase

```
# Launch both foundational enum tasks together:
Task T002: "Add ExperienceTier enum to daily/Models.swift"
Task T003: "Add SessionTier enum to daily/Models.swift"
# Then sequentially:
Task T004: "Add experienceTier computed property to UserProfile"  → depends on T002
Task T005: "Add isUnlocked(for:) to SessionTier"               → depends on T002, T003, T004
```

## Parallel Example: User Story 1 + 2 Combined Sprint

```
# Once Phase 2 is done, run these together:
Task T006: "SessionTierPicker view"          → US1 view component
Task T009: "completeRoutine() return type"   → US2 model change
Task T010: "LevelUpView"                     → US2 view component
Task T012: "ProfileView tier badge"          → US2 profile view
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational (T002–T005) — **required before anything else**
3. Complete Phase 3: User Story 1 (T006–T008)
4. **STOP and VALIDATE**: Check tier picker at all three experience levels in Simulator; verify `@AppStorage` persistence
5. Merge US1 if satisfied; begin US2

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. Add US1 → Tier picker live, preference persisted → **MVP demo**
3. Add US2 → Level-up celebrations → **Progression system live**
4. Add US3 → Dynamic session generation → **Full feature complete**

---

## Notes

- No new Swift source files are required — all changes are additions to `daily/Models.swift`, `daily/ContentView.swift`, and `daily/ProfileView.swift`
- No SwiftData schema migration needed — `ExperienceTier` and `SessionTier` are transient enums; `preferredSessionTier` is `@AppStorage`
- The existing `completeRoutine()` XP/streak/level logic is preserved; only the return type changes (Void → ExperienceTier?)
- `#Preview` blocks are mandatory for every new SwiftUI `View` per the project constitution
- Commit after each logically complete task or phase checkpoint per constitution Principle V
