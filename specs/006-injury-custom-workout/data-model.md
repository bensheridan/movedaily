# Data Model: Injury & Custom Workout Builder

**Branch**: `006-injury-custom-workout` | **Phase**: 1 | **Date**: 2026-04-19

## New Entity: InjuryType (Enum)

**Location**: `daily/Models.swift` (add alongside existing enums)

```
InjuryType: String, CaseIterable, Identifiable, Codable
├── .lowerBack       → "Lower Back"
├── .shoulder        → "Shoulder / Rotator Cuff"
├── .knee            → "Knee"
├── .wristElbow      → "Wrist / Elbow"
├── .ankleFoot       → "Ankle / Foot"
└── .neck            → "Neck / Cervical"

var displayName: String   // human-readable label for UI
var icon: String          // SF Symbol for picker row
```

**Validation**: None required — predefined cases.

---

## New Entity: CustomExercise (@Model)

**Location**: `daily/Models.swift` (add alongside Exercise and Routine)  
**Registration**: `dailyApp.sharedModelContainer` Schema

```
@Model class CustomExercise
├── name: String                  // required; user-entered; max ~80 chars
└── durationSeconds: Int          // required; must be > 0
```

**Validation rules** (enforced in UI before saving):
- `name` must be non-empty after trimming whitespace
- `durationSeconds` must be a positive integer (> 0)

**Relationships**: None. Custom exercises are standalone and selected by the user into a session; they are not linked to `Routine`.

**State transitions**: Created → Available in reuse list → (optionally deleted by user — out of scope for this feature).

---

## Modified Entity: UserProfile (@Model)

**Location**: `daily/Models.swift` (add field to existing class)

```
+ activeInjuries: [String]   // raw values of InjuryType; default []
```

- Stores the user's current active injuries as an array of `InjuryType` raw string values.
- Multiple injuries allowed simultaneously.
- Empty array = no active injury (default for new and existing users — lightweight migration safe).
- Persisted; survives app restarts.

---

## Modified Entity: Exercise (@Model)

**Location**: `daily/Models.swift` (add field to existing class)

```
+ contraindications: [String]   // raw values of InjuryType; default []
```

- Lists which injury types make this exercise unsafe to include.
- Populated during `Exercise.seedInitialData(context:)` / `Exercise.migrateData(context:)`.
- Empty array = safe for all users (no contraindications).
- Lightweight migration safe (default `[]`).

**Example contraindication assignments (illustrative)**:
| Exercise Category | Example Injury Contraindications |
|-------------------|----------------------------------|
| Bodyweight (squats, lunges) | `.knee`, `.ankleFoot` |
| Bodyweight (push-ups, planks) | `.shoulder`, `.wristElbow` |
| Stretching (neck rolls) | `.neck` |
| Stretching (hamstring, hip) | `.lowerBack`, `.knee` |
| Balance (single-leg) | `.knee`, `.ankleFoot` |
| Breathing | (none — safe for all injuries) |

---

## Session Filtering Logic

Applied in two places (both already iterate the exercise pool):

### 1. Auto-generated daily session (`Routine.buildSession`)
```
Current filter: genderFocus == nil || genderFocus == profile.gender
New filter:     (genderFocus == nil || genderFocus == profile.gender)
                && intersection(contraindications, profile.activeInjuries).isEmpty
```

### 2. Custom workout builder (new)
```
categoryPool = allExercises
    .filter { selectedCategories.contains($0.category) }
    .filter { intersection($0.contraindications, activeInjuries).isEmpty }

sessionExercises = categoryPool (shuffled, greedy-fill to tier duration)
    + userSelectedCustomExercises
```

---

## Schema Registration

**File**: `daily/dailyApp.swift`

```swift
// Before (existing):
Schema([UserProfile.self, Exercise.self, Routine.self])

// After:
Schema([UserProfile.self, Exercise.self, Routine.self, CustomExercise.self])
```

No `SchemaMigrationPlan` required — all changes are additive with defaults.
