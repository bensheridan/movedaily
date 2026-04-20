# Research: Weekly Workout Planner

**Feature**: 007-weekly-planner
**Date**: 2026-04-19

---

## Decision 1: SwiftData model topology for WorkoutPlan → PlanDay

**Decision**: Two `@Model` classes with a SwiftData `@Relationship(deleteRule: .cascade)` parent→child link. Plan exercises stored as a `[PlanExercise]` array where `PlanExercise` is a `Codable` struct — not a third `@Model`.

**Rationale**:
- `WorkoutPlan` and `PlanDay` are independently queried and edited → separate `@Model` makes sense.
- `PlanExercise` is a pure value object (name + value + unit) with no identity of its own and is never queried independently. Storing it as a `Codable` struct array on `PlanDay` avoids a third `@Model` and keeps queries simple.
- SwiftData supports `[CodableStruct]` as a stored property in an `@Model` class (iOS 17+).
- `@Relationship(deleteRule: .cascade)` ensures deleting a `WorkoutPlan` automatically deletes its `PlanDay` children.

**Alternatives considered**:
- All-`@Model` (three levels): unnecessary complexity for a value object like `PlanExercise` that has no relationships.
- Flat JSON blob on `WorkoutPlan`: makes day-level editing (add/remove/reorder days) cumbersome; forfeits SwiftData relationship management.

---

## Decision 2: Weekday representation

**Decision**: Store assigned weekdays as `[Int]` on `PlanDay`, using `Calendar.weekday` convention: 1 = Sunday, 2 = Monday … 7 = Saturday.

**Rationale**:
- `Calendar.current.component(.weekday, from: Date())` returns this convention natively — no conversion needed when looking up "today's plan day".
- `Calendar.current.shortWeekdaySymbols` (locale-aware Mon/Tue/… strings) maps to these indices directly for display.
- Storing as `[Int]` inside the Codable `PlanDay` @Model is trivially serialised.

**Alternatives considered**:
- Weekday as `[String]` ("Monday", "Tuesday"): localisation risk, heavier storage.
- Separate `WeekdayAssignment` `@Model`: over-engineered for a 1–7 integer set.

---

## Decision 3: "Today's Session" detection in DashboardView

**Decision**: `DashboardView` adds `@Query private var allPlans: [WorkoutPlan]` and computes `activePlan` and `todayPlanDay` as inline computed properties using `Calendar.current.component(.weekday, from: Date())`.

**Rationale**:
- No new architecture needed; `@Query` + computed properties follows the existing pattern used throughout the codebase (e.g., `DashboardView.exercises`).
- The lookup is O(n) on a tiny in-memory collection (≤7 days per plan) — no performance concern.
- Correctly refreshes at app launch and whenever the model context changes (SwiftData triggers view re-render automatically).

**Alternatives considered**:
- `@EnvironmentObject` for active plan: premature abstraction; violates Constitution Principle V.
- `NotificationCenter` + midnight timer: complex for what is a simple property read.

---

## Decision 4: Rendering plan workouts in RoutineDetailView

**Decision**: Convert `PlanExercise` entries to synthetic `Exercise` objects the same way `CustomWorkoutBuilderView` does for `CustomExercise` — sets use `value * 45` as nominal seconds, seconds use `value` directly. Pass them as `allExercises` to `RoutineDetailView`.

**Rationale**:
- `RoutineDetailView` already accepts an `allExercises: [Exercise]` parameter and looks up exercises by name. Reusing this interface costs zero new code in RoutineDetailView.
- The 45-second-per-set nominal matches the existing convention in `CustomWorkoutBuilderView`.

**Alternatives considered**:
- A new "PlanRoutineDetailView": code duplication; violates YAGNI.
- Modifying RoutineDetailView to accept a heterogeneous list: increases coupling.

---

## Decision 5: Activation mutex (one active plan at a time)

**Decision**: When the user activates a plan, iterate `allPlans` in `modelContext` and set `isActive = false` on all others before setting the target plan's `isActive = true`. No database transaction required — SwiftData saves atomically on the next autosave cycle.

**Rationale**: Simple, correct, and consistent with how `UserProfile` (single record pattern) is already managed in this codebase.

---

## Decision 6: Import reuses WorkoutParser

**Decision**: The import flow calls the existing `WorkoutParser.parse(text:)` (which already returns `[ParsedDay]`) and maps each `ParsedDay` into a `PlanDay` with empty `weekdays`. The user then assigns weekdays in the schedule step before saving.

**Rationale**: Zero new parsing code needed. The parser already handles multi-day programs correctly.

---

## Decision 7: Dashboard entry point

**Decision**: "Weekly Plans" is accessed via a toolbar button or card on the Dashboard — not via Profile. A `WeeklyPlannerView` (sheet or navigation push) shows the plan list and creates/edits plans.

**Rationale**: Plans are session-level decisions (what am I doing this week?) not profile settings. Profile already contains injury and gender settings; adding plan management there would overload it.
