# Tasks: Weekly Workout Planner

**Input**: Design documents from `/specs/007-weekly-planner/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ui-contracts.md ✅

**Tests**: Not requested — no test tasks included.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

---

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

---

## Phase 1: Setup

**Purpose**: Confirm clean baseline on branch `007-weekly-planner` before any changes land.

- [x] T001 Verify the project builds cleanly in Xcode on branch `007-weekly-planner` before making any changes

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Data model additions that every user story depends on. Must be complete before any UI work begins.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T002 Add `PlanExercise` Codable struct, `WorkoutPlan` @Model, and `PlanDay` @Model to `daily/Models.swift` — add after the `CustomExercise` class. `PlanExercise`: `name: String`, `value: Int`, `unit: String`, computed `nominalSeconds: Int` (`unit == "sets" ? value * 45 : value`). `WorkoutPlan`: `name: String`, `isActive: Bool = false`, `createdAt: Date = Date()`, `@Relationship(deleteRule: .cascade, inverse: \PlanDay.plan) var days: [PlanDay] = []`, init taking `name`. `PlanDay`: `name: String`, `weekdays: [Int] = []` (Calendar.weekday: 1=Sun…7=Sat), `exercises: [PlanExercise] = []`, `var plan: WorkoutPlan?`, init taking `name, weekdays, exercises`.

- [x] T003 Register `WorkoutPlan.self` and `PlanDay.self` in the `Schema` array inside `dailyApp.sharedModelContainer` in `daily/dailyApp.swift`

**Checkpoint**: Build must succeed with no SwiftData schema errors before proceeding.

---

## Phase 3: User Story 1 — Import a Program and Map to the Week (Priority: P1) 🎯 MVP

**Goal**: Users paste a multi-day workout program, assign each extracted day to days of the week, save it as an active plan, and see Today's Session on the Dashboard driven by that plan.

**Independent Test**: Open "Weekly Plans" → "New Plan" → paste the 5-day physio program → tap "Extract & Schedule" → assign Day 1 → Monday, Day 2 → Tuesday, Day 3 → Wednesday, Day 4 → Thursday, Day 5 → Friday → save and activate → return to Dashboard → confirm Today's Session shows the correct Day's exercises for the current weekday.

- [x] T004 [P] [US1] Create `daily/WeeklyPlannerView.swift` — a SwiftUI `View` presented as a sheet that shows all `WorkoutPlan` records via `@Query`. Empty state: "No plans yet. Create your first plan." with a "New Plan" button. List state: each plan as a card showing name, active badge ("Active" chip when `isActive == true`), "Activate" button (disabled if already active), and a swipe-to-delete action with a confirmation alert. "New Plan" button in the navigation bar navigates to `PlanEditorView(plan: nil)`. Include `#Preview`.

- [x] T005 [P] [US1] Create `daily/PlanEditorView.swift` — a SwiftUI `View` (full-screen sheet or navigation push from WeeklyPlannerView) for creating a new `WorkoutPlan`. Contains: a `TextField` for the plan name, a `List` of the plan's `PlanDay` entries (empty state: "No days added yet"), an import section (collapsible, see T006), a "Save Plan" button (disabled when name is empty or no days added), and an "Activate on save" toggle. On save: insert `WorkoutPlan` into `modelContext`, if activate toggle is on then set all other plans' `isActive = false` and new plan's `isActive = true`. Include `#Preview`.

- [x] T006 [US1] Add import section to `daily/PlanEditorView.swift` — a collapsible "Import a program" section with a `TextEditor` (placeholder: "Paste a workout program here…"), an "Extract & Schedule" button that calls `WorkoutParser.parse(text:)` asynchronously and stores results in `@State var parsedDays: [ParsedDay]`. Show a `ProgressView` while parsing. Show a parse error label if it throws. The extracted days are rendered by T007.

- [x] T007 [US1] Implement extracted-day weekday assignment UI inside `daily/PlanEditorView.swift` — for each `ParsedDay` in `parsedDays`, show a card with: the day name (e.g. "Day 1 – Upper Body"), the exercise count, and a compact Mon–Sun weekday selector (7 toggle chips labelled with `Calendar.current.veryShortWeekdaySymbols`). Weekdays already assigned to another extracted day are shown disabled. An "Add to Plan" button per card is enabled only when at least one weekday is selected; tapping it creates a `PlanDay` from the `ParsedDay`'s exercises (mapping `ParsedExerciseResult` → `PlanExercise`) and appends it to the plan's `days` array. An "Add All" button adds all unassigned extracted days in order, auto-assigning weekdays sequentially from Monday if none were manually chosen.

- [x] T008 [US1] Modify `daily/ContentView.swift` (`DashboardView`) — add `@Query private var allPlans: [WorkoutPlan]`, two computed properties: `var activePlan: WorkoutPlan? { allPlans.first(where: { $0.isActive }) }` and `var todayPlanDay: PlanDay? { let wd = Calendar.current.component(.weekday, from: Date()); return activePlan?.days.first(where: { $0.weekdays.contains(wd) }) }`. Add a toolbar button (`.navigationBarTrailing`, `systemImage: "calendar.badge.plus"`) that presents `WeeklyPlannerView` as a sheet via `@State private var showingWeeklyPlanner = false`.

- [x] T009 [US1] Modify `daily/ContentView.swift` (`DashboardView`) — when `todayPlanDay != nil`, replace `DailyRoutineCard` with a **Today's Plan Card**: show the active plan name as a caption, the plan day name as a headline (e.g. "Day 1 – Upper Body"), a list of up to 3 exercise names as a preview, a "Start Session" button that navigates to `RoutineDetailView` using the plan day's exercises converted to synthetic `Exercise` objects (`PlanExercise.nominalSeconds` for duration, category `.bodyweight`, empty instructions and tips), and a "Not today — auto session" text button that sets a local `@State var ignorePlanToday = false` and falls back to the normal `DailyRoutineCard`.

**Checkpoint**: User Story 1 is fully functional. Import a program, schedule it, see Today's Session change on the Dashboard.

---

## Phase 4: User Story 2 — Manually Build a Weekly Plan (Priority: P2)

**Goal**: Users build a plan day-by-day from scratch using a dedicated day builder that lets them name the day, pick weekdays, and select exercises from the exercise library or custom exercises.

**Independent Test**: Open "Weekly Plans" → "New Plan" → tap "Add a day manually" → name it "Monday – Strength" → assign to Monday → add Bodyweight + Stretching categories → save day → add another day "Wednesday – Core" assigned to Wednesday → save plan and activate → on Monday, Dashboard shows "Monday – Strength".

- [x] T010 [P] [US2] Create `daily/PlanDayBuilderView.swift` — a SwiftUI `View` presented as a sheet from `PlanEditorView`. Takes an optional existing `PlanDay` (nil = new) and a `Set<Int>` of weekdays already taken by other days in the plan. Contains: a `TextField` for the day name, a Mon–Sun weekday selector (same chip style as T007, taken weekdays disabled), a category grid (2×2, same style as `CustomWorkoutBuilderView`) for selecting `ExerciseCategory.displayCategories` — selecting a category adds all exercises from that category as `PlanExercise` entries (injury filter NOT applied per spec), a "My Exercises" section listing all `CustomExercise` records via `@Query` with toggles to include, an "Add custom exercise" inline form (name field + Seconds/Sets segmented control + value field, same validation as `CustomWorkoutBuilderView`), a "Save Day" button disabled when name is empty or no weekday selected. On save, calls a completion closure `(PlanDay) -> Void`. Include `#Preview`.

- [x] T011 [US2] Wire `PlanDayBuilderView` into `daily/PlanEditorView.swift` — add an "Add a day manually" button below the import section; tapping it presents `PlanDayBuilderView` as a sheet (passing the set of weekdays already used by existing plan days). On completion, append the returned `PlanDay` to the plan's days list. Also make existing day rows in the days list tappable: tapping a day opens `PlanDayBuilderView` in edit mode (pre-populated name, weekdays, exercises), and on save, updates the existing `PlanDay` in place.

**Checkpoint**: User Story 2 works independently — a plan can be fully built without importing any text.

---

## Phase 5: User Story 3 — Manage and Switch Plans (Priority: P3)

**Goal**: Users can activate a different plan, edit day assignments on an existing plan, delete unwanted plans, and delete individual days within a plan.

**Independent Test**: Create two plans → activate Plan B → Dashboard shows Plan B → activate Plan A → Dashboard switches to Plan A → delete Plan B → Plan B no longer appears in the list.

- [x] T012 [US3] Implement plan activation in `daily/WeeklyPlannerView.swift` — "Activate" button action: iterate all plans fetched via `@Query`, set `plan.isActive = false` on each, then set the selected plan's `isActive = true`. Deactivating the currently active plan (if user somehow taps its Activate button again) should show the plan as active. After mutation, `modelContext` autosave propagates the change to `DashboardView` automatically via SwiftData.

- [x] T013 [US3] Add plan editing in `daily/WeeklyPlannerView.swift` — each plan card gains an "Edit" button (or swipe action) that opens `PlanEditorView` in edit mode: pass the existing `WorkoutPlan` so the editor pre-fills name, days list, and the activate toggle reflects the current `isActive` state. On save in edit mode, update the existing record (do not insert a new one).

- [x] T014 [US3] Add swipe-to-delete for individual days within `daily/PlanEditorView.swift` — days list rows support `.swipeActions(edge: .trailing, allowsFullSwipe: true)` with a destructive "Remove" button that removes the `PlanDay` from the plan's `days` array and calls `modelContext.delete(day)`.

**Checkpoint**: All three user stories are independently functional.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Rest day banner, edge case hardening, empty-state copy.

- [x] T015 [P] Add rest day banner to `daily/ContentView.swift` (`DashboardView`) — when `activePlan != nil` but `todayPlanDay == nil`, replace the normal `DailyRoutineCard` area with a rest day card: an icon (`bed.double`), headline "Rest day", caption showing the active plan name, and a "Do an auto session instead" button that sets `@State var ignorePlanToday = true` and restores the normal auto-generated card for this app session only (does not deactivate the plan).

- [x] T016 [P] Edge case hardening — in `daily/PlanEditorView.swift`, prevent saving a plan with no days: keep the "Save Plan" button disabled and show "Add at least one workout day to save." as an inline hint when the days list is empty. In `daily/WeeklyPlannerView.swift`, if deleting the active plan, show a confirmation alert: "Deleting this plan will revert Today's Session to auto-generated workouts." Before confirming, deactivate the plan and delete it.

**Checkpoint**: Run all acceptance scenarios from `spec.md` before marking the feature complete.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — **blocks all user stories**
- **US1 (Phase 3)**: Depends on Phase 2 — T004 and T005 can start as soon as T003 is complete
- **US2 (Phase 4)**: Depends on Phase 2 — T010 can start as soon as T003 is complete; T011 requires T005 (PlanEditorView) to exist
- **US3 (Phase 5)**: Depends on US1 (T004 — WeeklyPlannerView) and US2 (T011 — PlanEditorView edit mode)
- **Polish (Phase 6)**: T015 depends on T008/T009 (Dashboard changes); T016 depends on T004/T005; T015 and T016 are independent of each other

### User Story Dependencies

- **US1 (P1)**: Starts after Phase 2. No dependency on US2 or US3.
- **US2 (P2)**: Starts after Phase 2. T010 (new file) is independent; T011 requires T005 (PlanEditorView shell) to exist.
- **US3 (P3)**: Extends WeeklyPlannerView (T004) and PlanEditorView (T005/T011) — implement after US1 and US2.

### Within Each Phase

- T002 → T003 (models must exist before Schema registration)
- T004 and T005 are new files → can run in parallel [P]
- T006 → T007 (import section must exist before weekday assignment UI)
- T008 → T009 (Query + computed properties must exist before Today's Plan Card)
- T010 → T011 (PlanDayBuilderView must exist before wiring into PlanEditorView)
- T012, T013, T014 can run in any order (different actions in different files or different parts of same file)
- T015 and T016 are independent [P]

### Parallel Opportunities

```
# Once T003 is complete, these two new files can be written simultaneously:
T004: Create daily/WeeklyPlannerView.swift          [US1]
T005: Create daily/PlanEditorView.swift             [US1]
T010: Create daily/PlanDayBuilderView.swift         [US2]  ← also independent

# Polish tasks are independent:
T015: Rest day banner in ContentView.swift
T016: Edge case hardening in PlanEditorView + WeeklyPlannerView
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational (T002–T003)
3. Complete Phase 3: User Story 1 (T004–T009)
4. **STOP and VALIDATE**: Import a program → schedule it → confirm Dashboard shows planned workout
5. Ship MVP — users can follow imported programs on a weekly schedule

### Incremental Delivery

1. Setup + Foundational → data model ready
2. US1 → import & schedule live (MVP)
3. US2 → manual plan builder live
4. US3 → plan management live
5. Polish → rest day banner + edge cases

---

## Notes

- All new `.swift` files belong in `daily/` (Xcode auto-syncs all files in that directory)
- Every new `View` file requires a `#Preview` block (Constitution Principle I)
- `WorkoutPlan.self` and `PlanDay.self` must be in the Schema before first launch on any device (T003 is critical)
- The injury filter does NOT apply to plan workouts — exercises are stored as a snapshot at import/build time (per spec edge cases)
- Weekday values follow `Calendar.weekday` convention: 1 = Sunday, 2 = Monday … 7 = Saturday
- `Calendar.current.veryShortWeekdaySymbols` gives locale-aware single-letter labels for the weekday chip selector
- The `ignorePlanToday` fallback in DashboardView is session-only (`@State`) — it resets when the app restarts, which is intentional
