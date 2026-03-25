# Data Model: Session Duration Tiers

**Branch**: `005-session-tiers` | **Date**: 2026-03-24

---

## Overview

This feature requires no new `@Model` types and no SwiftData schema migration. All changes are:
1. A new `ExperienceTier` enum (pure Swift value type)
2. A new `SessionTier` enum (pure Swift value type)
3. Computed properties added to existing `UserProfile`
4. A static `SessionBuilder` function (or static method on `Routine`)
5. `@AppStorage` key for `preferredSessionTier` (stored in `UserDefaults`, not SwiftData)
6. Modified return type of `completeRoutine()` to signal tier-up events

---

## Existing Entities (modified)

### UserProfile (`@Model`)

**Existing fields** (unchanged):
| Field | Type | Notes |
|-------|------|-------|
| `gender` | `Gender` | No change |
| `xp` | `Int` | No change — rolling XP, resets each level |
| `level` | `Int` | No change — increments by 1 per 100 XP |
| `streakCount` | `Int` | No change |
| `lastExerciseDate` | `Date?` | No change |
| `profileImageData` | `Data?` | No change |

**New computed properties** (no schema change):
| Property | Type | Logic |
|----------|------|-------|
| `experienceTier` | `ExperienceTier` | `level >= 20 → .advanced`, `level >= 7 → .intermediate`, else `.beginner` |

**Modified method**:
- `completeRoutine(baseXP:)` return type changes from `Void` to `ExperienceTier?`
- Returns the new `ExperienceTier` if a tier boundary was crossed during this call, `nil` otherwise
- All existing XP/streak/level logic preserved unchanged

---

### Routine (`@Model`)

**Existing fields** (unchanged):
| Field | Type | Notes |
|-------|------|-------|
| `name` | `String` | No change |
| `routineDescription` | `String` | No change |
| `exerciseNames` | `[String]` | No change |

**New static function** (no schema change):
```
Routine.buildSession(
    tier: SessionTier,
    exercises: [Exercise],
    profile: UserProfile?
) -> [String]  // returns ordered list of exercise names
```

This function selects exercises from the pool to fill the tier's duration budget. It is a pure function — deterministic given the same input (exercises shuffled, but result is a list of names, not a persisted `Routine`).

---

## New Types (pure Swift, no @Model)

### ExperienceTier

```
enum ExperienceTier: String, Codable, CaseIterable, Identifiable
  cases: .beginner, .intermediate, .advanced
  static let intermediateLevel: Int = 7
  static let advancedLevel: Int = 20
  var displayName: String
  var id: String { rawValue }
```

**State transitions for UserProfile.level**:
```
level 1-6  → ExperienceTier.beginner
level 7-19 → ExperienceTier.intermediate
level 20+  → ExperienceTier.advanced
```

Tier can only increase (level is monotonically non-decreasing). There is no tier demotion.

---

### SessionTier

```
enum SessionTier: String, CaseIterable, Identifiable
  cases: .basic ("10-12 min"), .intermediate ("15-20 min"), .advanced ("20-30 min")
  var durationRange: ClosedRange<Int>   // in seconds
    .basic:        600...720
    .intermediate: 900...1200
    .advanced:     1200...1800
  var requiredExperienceTier: ExperienceTier
    .basic:        .beginner
    .intermediate: .intermediate
    .advanced:     .advanced
  var isUnlocked(for profile: UserProfile?) -> Bool
  var unlockLabel: String
  var id: String { rawValue }
```

**Validation rules**:
- `SessionTier.basic` is always available (even with `nil` profile)
- `SessionTier.intermediate` requires `profile.experienceTier >= .intermediate`
- `SessionTier.advanced` requires `profile.experienceTier == .advanced`

---

## Preferences (UserDefaults via @AppStorage)

| Key | Type | Default | Notes |
|-----|------|---------|-------|
| `"preferredSessionTier"` | `String` | `SessionTier.basic.rawValue` | Clamped to highest available tier on read |

Stored as the `rawValue` string of `SessionTier` (e.g., `"10-12 min"`). On read, the view clamps the stored value to the user's highest available tier to handle edge cases gracefully.

---

## Session Generation Contract

```
Input:
  tier: SessionTier               — duration budget
  exercises: [Exercise]           — full seeded pool (61 exercises)
  profile: UserProfile?           — for gender-focus filtering

Output:
  [String]                        — ordered exercise names for the session
                                    total duration ∈ tier.durationRange (±120s tolerance)

Algorithm:
  1. Filter exercises by genderFocus (keep nil + profile.gender matches)
  2. Shuffle filtered pool
  3. Greedily append exercises until cumulative duration ≥ tier.durationRange.lowerBound
     and ≤ tier.durationRange.upperBound
  4. If budget cannot be reached without exceeding upper bound, allow overshoot by
     one exercise (±120s tolerance, per FR-004)
  5. Return exercise names in selection order

Guarantees:
  - No exercise repeats (pool is shuffled, each exercise picked at most once)
  - Falls back to allowing repeats only if pool is exhausted before hitting lower bound
     (impossible with 61 exercises for a 30-min budget)
```

---

## Level-Up Event Contract

When `completeRoutine()` is called and a tier boundary is crossed:

| From tier | To tier | Return value |
|-----------|---------|--------------|
| .beginner | .intermediate | `.intermediate` |
| .intermediate | .advanced | `.advanced` |
| Any | same tier | `nil` |

The caller (`DashboardView`) is responsible for presenting the level-up UI. The model layer does not present UI.

---

## No Migration Required

All SwiftData schema changes are absent. The existing `UserProfile` and `Routine` entities are unchanged at the persistence layer. The new `ExperienceTier` and `SessionTier` types are transient enums; `preferredSessionTier` uses `UserDefaults` and does not require a migration plan.
