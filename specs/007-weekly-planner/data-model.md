# Data Model: Weekly Workout Planner

**Feature**: 007-weekly-planner
**Date**: 2026-04-19

---

## New @Model: WorkoutPlan

```swift
@Model final class WorkoutPlan {
    var name: String
    var isActive: Bool = false
    var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \PlanDay.plan)
    var days: [PlanDay] = []

    init(name: String) {
        self.name = name
    }
}
```

**Validation**:
- `name` must be non-empty before saving.
- At most one `WorkoutPlan` may have `isActive == true` at any time (enforced in Swift, not at the DB level).

**State transitions**:
- `isActive`: false → true (activate), true → false (deactivate or superseded by another plan).

---

## New @Model: PlanDay

```swift
@Model final class PlanDay {
    var name: String
    /// Calendar.weekday values: 1=Sunday, 2=Monday … 7=Saturday.
    /// A weekday appears at most once per plan (enforced in UI).
    var weekdays: [Int] = []
    var exercises: [PlanExercise] = []   // Codable value-type array
    var plan: WorkoutPlan?               // inverse of WorkoutPlan.days

    init(name: String, weekdays: [Int] = [], exercises: [PlanExercise] = []) {
        self.name = name
        self.weekdays = weekdays
        self.exercises = exercises
    }
}
```

**Validation**:
- `name` must be non-empty.
- `weekdays` contains values in 1…7 only, no duplicates.
- `exercises` may be empty (rest day with a name, uncommon but valid).

---

## New Codable Struct: PlanExercise

```swift
struct PlanExercise: Codable {
    var name: String
    var value: Int      // set count or total seconds
    var unit: String    // "sets" or "seconds"

    /// Nominal duration for RoutineDetailView timer display.
    var nominalSeconds: Int {
        unit == "sets" ? value * 45 : value
    }
}
```

**Validation**:
- `value` must be > 0.
- `unit` must be `"sets"` or `"seconds"`.

---

## Schema Registration (dailyApp.swift)

```swift
Schema([
    UserProfile.self,
    Exercise.self,
    Routine.self,
    CustomExercise.self,
    WorkoutPlan.self,   // NEW
    PlanDay.self,       // NEW
])
```

Both new `@Model` types added in the same commit. No `SchemaMigrationPlan` required — purely additive.

---

## Relationships

```
WorkoutPlan (1) ──cascade──▶ PlanDay (many)
PlanDay.exercises: [PlanExercise]  (value array, not a relationship)
```

---

## Dashboard Integration: Today's Plan Day lookup

```swift
// In DashboardView (computed properties, no new architecture)

var activePlan: WorkoutPlan? {
    allPlans.first(where: { $0.isActive })
}

var todayPlanDay: PlanDay? {
    let weekday = Calendar.current.component(.weekday, from: Date())
    return activePlan?.days.first(where: { $0.weekdays.contains(weekday) })
}
```

When `todayPlanDay != nil`, Today's Session renders the plan workout.
When `todayPlanDay == nil` but `activePlan != nil`, a rest day banner is shown.
When `activePlan == nil`, the existing auto-generated session is shown unchanged.

---

## Synthetic Exercise conversion (for RoutineDetailView)

```swift
// Converts PlanExercise → Exercise for use in RoutineDetailView.allExercises
func syntheticExercise(from pe: PlanExercise) -> Exercise {
    Exercise(
        name: pe.name,
        exerciseDescription: pe.unit == "sets"
            ? "\(pe.value) set\(pe.value == 1 ? "" : "s")"
            : "\(pe.value) sec",
        durationSeconds: pe.nominalSeconds,
        category: .bodyweight,
        instructions: [],
        tips: []
    )
}
```
