# Research: Session Duration Tiers

**Branch**: `005-session-tiers` | **Date**: 2026-03-24

---

## Decision 1: XP Threshold Calibration for 30/90-Day Level Targets

**Decision**: Set Intermediate tier at level ≥ 7, Advanced tier at level ≥ 20.

**Rationale**:

The current system awards 20 XP per day + 50 bonus XP at streak milestones of 7, 30, and 100 days, with a level-up every 100 XP (rolling).

| Scenario | Days | Daily XP | Streak Bonus | Total XP | Levels Gained |
|----------|------|----------|--------------|----------|---------------|
| Perfect no-miss path, 30 days | 30 | 20 × 30 = 600 | +50 (day 7) + 50 (day 30) = 100 | 700 | 7 |
| Imperfect path (~10% missed days), 30 days | 27 | 20 × 27 = 540 | +50 (day 7) | 590 | 5–6 |
| Perfect no-miss path, 90 days | 90 | 20 × 90 = 1800 | +50 (day 7) + 50 (day 30) = 100 | 1900 | 19 |
| Imperfect path (~10% missed), 90 days | 81 | 20 × 81 = 1620 | +50 (day 7) | 1670 | 16–17 |

Starting at level 1, a perfect-path user crosses level 7 on day 30 and level 20 on approximately day 90. This aligns with SC-002 (28–35 days to Intermediate, 85–95 days to Advanced).

Mapping:
- **Beginner**: `level < 7` (levels 1–6)
- **Intermediate**: `level >= 7 && level < 20` (levels 7–19)
- **Advanced**: `level >= 20`

These are compile-time constants defined in the `ExperienceTier` enum; adjusting them in a future version requires only changing two integer literals.

**Alternatives considered**:
- *Cumulative XP tracking*: Store total lifetime XP separately and gate tiers on absolute totals (e.g., 600 XP → Intermediate). More intuitive to display but requires adding a new `totalXP` field to `UserProfile` and a migration. Rejected: adds schema complexity with no user-visible benefit given that `level` already monotonically increases and conveys the same information.
- *Time-based gating (calendar days)*: Gate tiers on `lastExerciseDate - createdAt` regardless of XP. Simpler logic but doesn't reward consistency — a user could create an account, never open the app for 30 days, and be "promoted" automatically. Rejected.

---

## Decision 2: Session Generation Strategy

**Decision**: Dynamically generate a session (ordered list of exercise names) at view time by selecting exercises from the seeded pool to fill a duration budget. Store the result transiently — not persisted as a new `Routine` object.

**Rationale**:

The existing system seeds four named `Routine` objects with fixed `exerciseNames` lists. These cover the 10-12 min window. Rather than creating a combinatorial matrix of routines for all three tiers, a `SessionBuilder` static function will:

1. Accept `durationBudget: Int` (seconds), `exercises: [Exercise]`, and `profile: UserProfile?`
2. Shuffle the pool of exercises filtered by gender focus
3. Greedily pick exercises until the cumulative duration reaches the budget (±120 seconds tolerance)
4. Return the selected exercises in order

This approach:
- Requires no new `@Model` types or schema changes
- Generates variety on each session
- Scales to any future duration tier without new seed data
- Fits cleanly in `Models.swift` as a static method on `Routine` or as a free function

**Alternatives considered**:
- *More seeded routines per tier*: Add 8–10 additional `Routine` seeds for 15-20 min and 20-30 min tiers. Simple but static — users would see the same routines repeatedly at the 20-30 min tier after a few weeks. Rejected for P3 (variety matters for long sessions), acceptable as a fallback.
- *Separate `LongRoutine` model*: New `@Model` subclass with additional metadata. Over-engineered for this feature; violates Principle V. Rejected.

---

## Decision 3: Tier Preference Storage — @AppStorage vs SwiftData

**Decision**: Store `preferredSessionTier` in `UserDefaults` via `@AppStorage("preferredSessionTier")` in the view layer.

**Rationale**:

Constitution Principle II explicitly permits `@AppStorage` for "flags and lightweight preferences." Session tier preference (one of three raw string values) is a lightweight preference, not model-level data. Using `@AppStorage`:
- No migration required
- Automatically persists across app launches
- Directly bindable in SwiftUI with `@AppStorage`
- Value survives `UserProfile` deletion/recreation

**Alternatives considered**:
- *`UserProfile.preferredSessionTier: SessionTier`*: Adds a new SwiftData-persisted field; could trigger a schema migration warning if the database is already populated. Rejected: `@AppStorage` is simpler and constitution-preferred for this use case.

---

## Decision 4: Level-Up Detection and Announcement

**Decision**: Modify `UserProfile.completeRoutine()` to return the `ExperienceTier` of the new level (as an optional — `nil` if no tier change occurred). `DashboardView` checks the return value after calling `completeRoutine()` and, if non-nil, sets `@State private var levelUpTier: ExperienceTier?` to trigger a sheet or full-screen cover.

**Rationale**:

The simplest approach that avoids polling, Combine publishers, or observation of derived state. The function return value cleanly communicates the event at the point it occurs. A SwiftUI sheet on `DashboardView` presents the celebration inline with the completion flow.

**Alternatives considered**:
- *Observe level changes with `.onChange(of: profile?.level)`*: Works, but fires for every level-up, not just tier-crossings. Would require deriving the previous tier in the onChange closure. More complex.
- *`NotificationCenter` post from `completeRoutine()`*: Decouples the model from the view but adds unnecessary plumbing for a single call site. Rejected.

---

## Decision 5: Where ExperienceTier Lives

**Decision**: `ExperienceTier` is a new `enum` in `Models.swift` (alongside `Difficulty`, `Gender`, etc.), with a computed property `var experienceTier: ExperienceTier` on `UserProfile`.

**Rationale**:

Consistent with how `Difficulty` and `Gender` are structured. No new file needed; keeps all model-related code in one place per the project's single-file model convention. The enum is not a `@Model` — it is a pure Swift value type.

**Threshold constants** (inline with enum, adjustable):
```swift
enum ExperienceTier: String, Codable {
    case beginner     = "Beginner"
    case intermediate = "Intermediate"
    case advanced     = "Advanced"

    static let intermediateLevel = 7
    static let advancedLevel     = 20
}
```

`UserProfile.experienceTier` computed property:
```swift
var experienceTier: ExperienceTier {
    if level >= ExperienceTier.advancedLevel     { return .advanced }
    if level >= ExperienceTier.intermediateLevel { return .intermediate }
    return .beginner
}
```

---

## Decision 6: SessionTier Definition

**Decision**: Define three `SessionTier` cases as a Swift enum with associated min/max minutes and required `ExperienceTier`. Stored as a raw `String` in `@AppStorage`.

```swift
enum SessionTier: String, CaseIterable, Identifiable {
    case basic        = "10-12 min"
    case intermediate = "15-20 min"
    case advanced     = "20-30 min"

    var id: String { rawValue }

    var durationRange: ClosedRange<Int> { // seconds
        switch self {
        case .basic:        return (10 * 60)...(12 * 60)   // 600...720
        case .intermediate: return (15 * 60)...(20 * 60)   // 900...1200
        case .advanced:     return (20 * 60)...(30 * 60)   // 1200...1800
        }
    }

    var requiredTier: ExperienceTier {
        switch self {
        case .basic:        return .beginner
        case .intermediate: return .intermediate
        case .advanced:     return .advanced
        }
    }

    var label: String { rawValue }
    var unlockLabel: String {
        switch self {
        case .basic:        return "Available"
        case .intermediate: return "Unlocks at Intermediate"
        case .advanced:     return "Unlocks at Advanced"
        }
    }
}
```

---

## Decision 7: Session Generation Algorithm

**Decision**: Greedy fill with category diversity — pick one exercise from each available category in round-robin order until the duration budget is reached.

```
func buildSession(budget: ClosedRange<Int>, exercises: [Exercise], profile: UserProfile?) -> [Exercise]
  filtered = exercises filtered by genderFocus
  shuffled = filtered.shuffled()
  selected = []
  totalDuration = 0
  for exercise in shuffled:
    if totalDuration + exercise.durationSeconds <= budget.upperBound:
      selected.append(exercise)
      totalDuration += exercise.durationSeconds
    if totalDuration >= budget.lowerBound:
      break
  return selected
```

This is O(n) over 61 exercises — negligible. Category diversity is achieved via shuffle. If fewer exercises are available than needed (impossible with 61 exercises for a 30-min budget), fall back to allowing repeats.

