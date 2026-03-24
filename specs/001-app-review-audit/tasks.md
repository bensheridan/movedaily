---

description: "Task list for App Review & Bug Fix Audit"
---

# Tasks: App Review & Bug Fix Audit

**Input**: Design documents from `/specs/001-app-review-audit/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅

**Organization**: Tasks are grouped by user story to enable independent
implementation and testing of each story.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US4)
- Exact file paths included in all descriptions

---

## Phase 1: Setup

**Purpose**: Confirm the project builds cleanly before any changes.

No code changes. This phase establishes a green baseline.

- [x] T001 Confirm clean build in Xcode (⌘B) with zero errors before making changes

---

## Phase 2: Foundational (Blocking Prerequisite)

**Purpose**: Add the `NotificationManager` convenience overload that the
improved ProfileView requires to compile. Must complete before Phase 5.

**⚠️ CRITICAL**: Phase 5 (Profile screen) cannot begin until this phase is done.

- [x] T002 Add `func scheduleDailyReminder(at timeString: String)` convenience overload to `daily/NotificationManager.swift` that parses the `"HH:mm"` string with `DateFormatter` and delegates to the existing `(at hour: Int, minute: Int)` method

**Checkpoint**: Build the project (⌘B) — zero errors expected. Foundation ready.

---

## Phase 3: User Story 1 — Streak and XP Track Correctly (Priority: P1) 🎯 MVP

**Goal**: Remove the duplicate `completeRoutine()` extension in ContentView so
the correct implementation in Models.swift is called, fixing streak resets,
milestone bonuses, and level-up logic.

**Independent Test**: Complete a routine twice in one day and verify XP and
streak do not change on the second completion. Advance the date by two days
and complete again — verify streak resets to 1.

### Implementation for User Story 1

- [x] T003 [P] [US1] Remove the entire `extension UserProfile { func completeRoutine() { ... } }` block (lines ~140–157) from `daily/ContentView.swift`, leaving the `DashboardView` extension and all other code intact

**Checkpoint**: Build succeeds. The `profile?.completeRoutine()` call in
DashboardView now routes to `completeRoutine(baseXP: 20)` in Models.swift.
User Story 1 is fully testable independently.

---

## Phase 4: User Story 2 — Exercise Timer Completes Exactly Once (Priority: P2)

**Goal**: Prevent the timer's `onReceive` handler from firing completion
haptics and speech on every tick after zero. Fix `.buttonStyle()` so the
Start/Pause and Reset buttons render correctly.

**Independent Test**: Start any exercise, let the timer reach zero — observe
one haptic + one speech cue. Wait 5 seconds — confirm no further cues. Press
reset — confirm no cue fires.

### Implementation for User Story 2

- [x] T004 [P] [US2] Add `@State private var timerCompleted = false` to `ExerciseDetailView` in `daily/ExerciseListView.swift`; change the `else if timeRemaining == 0` branch to guard with `&& !timerCompleted`, then immediately set `timerCompleted = true` inside that branch; add `timerCompleted = false` to the reset button's action alongside the existing `timeRemaining` reset

- [x] T005 [US2] Fix `.buttonStyle()` placement in `daily/ExerciseListView.swift`: move `.buttonStyle(.borderedProminent).tint(.blue)` from inside the Start/Pause `Label` to be modifiers on the `Button` itself; move `.buttonStyle(.bordered).tint(.secondary)` from inside the Reset `Image` to be modifiers on its `Button` — both changes are in `ExerciseDetailView.body`

**Checkpoint**: Build succeeds. Exercise timer fires completion cue once and
stops. Buttons display with correct bordered styles. User Story 2 is fully
testable independently.

---

## Phase 5: User Stories 3 + 4 — Profile Screen (Priority: P3 + P4)

**Goal**: Replace the current `daily/ProfileView.swift` (which has a nested
NavigationView, editable Level/XP steppers, and no notifications/photo
support) with the improved implementation from `daily.xcodeproj/ProfileView.swift`.
This single replacement simultaneously fixes US3 (navigation, read-only stats)
and delivers US4 (notifications, profile photo, reset).

**Depends on**: T002 (Foundational — NotificationManager overload must exist)

**Independent Test (US3)**: Navigate to profile — one navigation bar, back
button works, Level and XP are read-only text.

**Independent Test (US4)**: Enable reminder, set a time, restart app — reminder
persists. Pick a photo — photo persists after restart. Reset Profile — stats
reset, gender/photo preserved.

### Implementation for User Stories 3 + 4

- [x] T006 [US3] Replace the entire contents of `daily/ProfileView.swift` with the implementation from `daily.xcodeproj/ProfileView.swift`; add `import PhotosUI` at the top of the file alongside the existing imports to resolve the missing `PHPickerViewController`/`PHPickerViewControllerDelegate` symbols; verify the file does NOT contain a `NavigationView { }` wrapper around the `Form`

**Checkpoint**: Build succeeds with zero errors. Profile screen shows one
navigation bar, Level/XP are read-only, reminder toggle and photo picker are
accessible. User Stories 3 and 4 are both testable independently.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final build validation and manual verification across all stories.

- [x] T007 Perform a clean build (`⇧⌘K` then `⌘B`) in Xcode and confirm zero errors and zero warnings in changed files (`ContentView.swift`, `ExerciseListView.swift`, `ProfileView.swift`, `NotificationManager.swift`)

- [ ] T008 [P] Run manual verification steps from `specs/001-app-review-audit/quickstart.md` for Fix 1 (duplicate completion) and Fix 2 (timer)

- [ ] T009 [P] Run manual verification steps from `specs/001-app-review-audit/quickstart.md` for Fix 3–5 (profile navigation, photo, notifications)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — verify baseline
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS Phase 5 only
- **US1 (Phase 3)**: Independent — can start after Phase 1; no dependency on Phase 2
- **US2 (Phase 4)**: Independent — can start after Phase 1; no dependency on Phase 2
- **US3+4 (Phase 5)**: Depends on Phase 2 (NotificationManager overload must exist)
- **Polish (Phase 6)**: Depends on all prior phases complete

### User Story Dependencies

- **US1 (Phase 3)**: No dependencies — starts after baseline confirmed
- **US2 (Phase 4)**: No dependencies — starts after baseline confirmed
- **US3+4 (Phase 5)**: Depends only on T002 (Foundational)

### Within Each User Story

- T003 → no prerequisites (removes code, no dependencies)
- T004 → no prerequisites (adds state var, independent)
- T005 → depends on T004 (same file — T004 must merge first to avoid conflicts)
- T006 → depends on T002 (NotificationManager overload must exist to compile)

### Parallel Opportunities

- **T003 and T004** can run in parallel — different files (ContentView.swift vs ExerciseListView.swift)
- **T003 and T006** can run in parallel after T002 — different files
- **T008 and T009** can run in parallel — independent verification flows

---

## Implementation Strategy

### MVP First (User Story 1 — P1 Only)

1. Complete Phase 1: baseline build
2. Complete Phase 3: remove duplicate extension (T003 only)
3. **STOP and VALIDATE**: Verify streak/XP correctness per quickstart.md Fix 1
4. Ship if only this fix is needed

### Recommended Execution Order (solo developer)

1. `⌘B` — confirm green baseline (T001)
2. Add NotificationManager overload (T002) — quick, unlocks Phase 5
3. Remove ContentView extension (T003) — 1 min
4. Fix timer flag (T004) — 5 min
5. Fix buttonStyle (T005) — 2 min
6. Replace ProfileView.swift (T006) — copy + add import PhotosUI
7. Clean build (T007)
8. Manual verification (T008, T009)

**Estimated scope**: ~30 minutes of implementation across 4 files.

---

## Notes

- `[P]` tasks use different files — no merge conflicts
- T004 and T005 are in the same file — run T004 first
- T006 source content lives in `daily.xcodeproj/ProfileView.swift` — copy the
  entire file body into `daily/ProfileView.swift` and add `import PhotosUI`
- `BreathingView.swift` is dead code (no navigation link references it) —
  not modified in this fix set; can be removed in a future cleanup task
- No automated tests added — manual verification via quickstart.md
