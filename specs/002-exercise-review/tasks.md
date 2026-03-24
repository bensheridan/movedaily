---

description: "Task list for Exercise Library Review & Reorganization"
---

# Tasks: Exercise Library Review & Reorganization

**Input**: Design documents from `/specs/002-exercise-review/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅

**Organization**: Tasks are grouped by user story to enable independent
implementation and testing of each story.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US5)
- Exact file paths included in all descriptions

---

## Phase 1: Setup

**Purpose**: Confirm the project builds cleanly before any changes.

No code changes. This phase establishes a green baseline.

- [x] T001 Confirm clean build in Xcode (⌘B) with zero errors before making changes

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add the `.balance` enum case and update the dashboard to show the
correct 4 categories. Must complete before any user story implementation.

**⚠️ CRITICAL**: All user story phases depend on this phase being complete.

- [x] T002 In `daily/Models.swift`, add `case balance = "Balance"` to the `ExerciseCategory` enum after the `kegels` case; add `case .balance: return "figure.stand"` to the `icon` computed property; add a static computed property `static var displayCategories: [ExerciseCategory] { [.stretching, .breathing, .bodyweight, .balance] }` to the enum

- [x] T003 [P] In `daily/ContentView.swift`, change `let categories = ExerciseCategory.allCases` in `DashboardView` to `let categories = ExerciseCategory.displayCategories`

**Checkpoint**: Build the project (⌘B) — zero errors expected. Dashboard should
now show 4 tiles: Stretching, Breathing, Bodyweight, Balance. Balance tile will
show an empty exercise list (exercises added in Phase 5).

---

## Phase 3: User Story 1 — Reorganized Category Navigation (Priority: P1) 🎯 MVP

**Goal**: Move all kegel exercises into the Stretching category so the Kegels
tile no longer appears on the dashboard and pelvic-floor exercises appear under
Stretching.

**Independent Test**: Open the app (fresh install). Dashboard shows 4 category
tiles (no Kegels). Tap Stretching — kegel exercises appear in the list.

### Implementation for User Story 1

- [x] T004 [US1] In `daily/Models.swift`, in the `kegelExercises()` method, change every `category: .kegels` to `category: .stretching` across all 5 Exercise initializers in that method (Muscle Discovery, Standard Kegels male, Power Pulses, Standard Kegels female, Elevator Kegels)

**Checkpoint**: Build succeeds. Fresh install shows kegel exercises under
Stretching. User Story 1 is testable independently.

---

## Phase 4: User Story 2 — Expanded Stretching Library (Priority: P2)

**Goal**: Add 3 new stretching exercises to fill gaps in flexibility/mobility
coverage: wrist work for desk workers, a deep hip opener, and spinal rotation.

**Independent Test**: Open Stretching category. Find Wrist & Forearm Stretch,
Pigeon Pose, Seated Spinal Twist. Tap each — verify full content and timer.

### Implementation for User Story 2

- [x] T005 [US2] In `daily/Models.swift`, append 3 new Exercise entries to the array returned by `stretchingExercises()`: (1) "Wrist & Forearm Stretch" — beginner, 60s, instructions: ["Extend one arm forward, palm up.", "Gently pull fingers down with the other hand.", "Hold for 15 seconds.", "Flip the hand palm-down and pull fingers toward you.", "Switch arms."], tips: ["Don't force the stretch — go to gentle tension only.", "Great for anyone who types or uses a phone frequently.", "Breathe normally throughout."], audioCues: [0: "Extend your right arm. Pull fingers down gently.", 15: "Now flip your hand and pull fingers toward you.", 30: "Switch to your left arm.", 45: "Flip and stretch."]; (2) "Pigeon Pose" — intermediate, 60s, instructions: ["Start on all fours.", "Bring your right knee forward behind your right wrist.", "Extend your left leg straight back.", "Lower your hips toward the floor.", "Hold and breathe.", "Switch sides."], tips: ["Place a cushion under your hip if this feels too intense.", "Keep your hips level and square.", "This stretch deepens over time — don't force it."], audioCues: [0: "Right knee forward. Settle into the stretch.", 30: "Switch to your left side."]; (3) "Seated Spinal Twist" — beginner, 60s, instructions: ["Sit with legs extended.", "Bend your right knee and cross it over your left leg.", "Place your left elbow on the outside of your right knee.", "Twist gently to the right.", "Hold.", "Switch sides."], tips: ["Sit tall — don't round your back.", "Twist from your torso, not just your shoulders.", "Breathe into the stretch."], audioCues: [0: "Cross your right knee over. Twist to the right.", 30: "Switch sides. Cross your left knee over."]

**Checkpoint**: Build succeeds. Stretching category shows 3 new exercises with
full content. User Story 2 is testable independently.

---

## Phase 5: User Story 3 — New Balance Category (Priority: P3)

**Goal**: Populate the Balance category with 6 exercises focused on stability
and fall prevention. All exercises include chair/wall safety instructions in
instructions, tips, and first audio cue — especially important for elderly users.

**Independent Test**: Tap Balance on dashboard. Find 6 exercises. Tap each —
verify instructions begin with chair safety setup. Start timer — first audio cue
mentions chair support.

### Implementation for User Story 3

- [x] T006 [US3] In `daily/Models.swift`, add a new `private static func balanceExercises() -> [Exercise]` method returning 6 exercises with full safety-conscious content per `data-model.md`: (1) "Single-Leg Stand" — beginner, 60s, category: .balance, instructions start with "Stand near a chair or wall for support.", tips include "Keep a chair within arm's reach for safety.", audioCues[0]: "Hold onto a chair if needed. Lift your right foot."; (2) "Heel-to-Toe Walk" — beginner, 60s, instructions start with "Stand near a wall or counter for support.", tips include "Walk alongside a wall you can touch for safety."; (3) "Tree Pose" — beginner, 60s, instructions start with "Stand near a chair or wall.", tips include "Use a chair for support until you feel confident.", also tip "Never place your foot directly on the knee joint."; (4) "Standing Knee Lifts" — beginner, 60s, instructions start with "Stand tall near a chair for support.", tips include "Hold the back of a chair if you feel unsteady."; (5) "Weight Shifts" — beginner, 60s, instructions include "Keep a chair nearby.", tips include "Keep a chair nearby for safety."; (6) "Clock Reach" — intermediate, 60s, instructions start with "Stand on one leg near a chair for support.", tips include "Use a chair for support when starting out." — refer to `specs/002-exercise-review/data-model.md` for complete instructions, tips, and audioCues for each exercise

- [x] T007 [US3] In `daily/Models.swift`, update the `seedInitialData(context:)` method: change `let allExercises = stretchingExercises() + breathingExercises() + bodyweightExercises() + kegelExercises()` to `let allExercises = stretchingExercises() + breathingExercises() + bodyweightExercises() + kegelExercises() + balanceExercises()`

**Checkpoint**: Build succeeds. Balance category shows 6 exercises, each with
chair safety instructions. 5 of 6 are Beginner difficulty. User Story 3 is
testable independently.

---

## Phase 6: User Story 4 — Expanded Breathing Library (Priority: P4)

**Goal**: Add 2 new breathing exercises to diversify the breathing category:
an energizing technique (Lion's Breath) and a calming vibration technique
(Humming Bee Breath).

**Independent Test**: Open Breathing category. Find Lion's Breath and Humming
Bee Breath. Tap each — verify full content and timer.

### Implementation for User Story 4

- [x] T008 [US4] In `daily/Models.swift`, append 2 new Exercise entries to the array returned by `breathingExercises()`: (1) "Lion's Breath" — beginner, 120s, category: .breathing, instructions: ["Sit comfortably or kneel.", "Inhale deeply through your nose.", "Open your mouth wide, stick out your tongue, and exhale forcefully with a ha sound.", "Relax your face.", "Repeat."], tips: ["This may feel silly at first — that's normal and part of the stress release.", "Let the exhale be loud and forceful.", "Great for releasing jaw and face tension."], audioCues: [0: "Inhale deeply through your nose.", 5: "Open wide and roar it out. Ha!", 15: "Inhale again.", 20: "And release. Ha!", 60: "Keep going. Inhale.", 65: "Release!"]; (2) "Humming Bee Breath" — beginner, 180s, instructions: ["Sit comfortably with eyes closed.", "Place your index fingers gently on the cartilage of your ears.", "Inhale deeply.", "Exhale while making a steady humming sound.", "Feel the vibration in your head and chest.", "Repeat."], tips: ["The humming should be smooth and continuous.", "Experiment with pitch — find what feels most soothing.", "This technique is excellent before sleep."], audioCues: [0: "Close your eyes. Fingers on your ears.", 5: "Inhale deeply.", 10: "Hum as you exhale.", 30: "Inhale again.", 35: "Long, steady hum.", 90: "Continue at your own pace."]

**Checkpoint**: Build succeeds. Breathing category shows 2 new exercises with
full content. User Story 4 is testable independently.

---

## Phase 7: User Story 5 — Expanded Bodyweight Library (Priority: P5)

**Goal**: Add 3 new bodyweight exercises targeting gaps in back extension and
deep core stability.

**Independent Test**: Open Bodyweight category. Find Superman Hold, Dead Bug,
Bird Dog. Tap each — verify full content and timer.

### Implementation for User Story 5

- [x] T009 [US5] In `daily/Models.swift`, append 3 new Exercise entries to the array returned by `bodyweightExercises()`: (1) "Superman Hold" — beginner, 60s, category: .bodyweight, instructions: ["Lie face down with arms extended overhead.", "Simultaneously lift your arms, chest, and legs off the floor.", "Hold for 3 to 5 seconds.", "Lower slowly.", "Repeat."], tips: ["Lift gently — you don't need to go high.", "Keep your neck neutral — look at the floor.", "Squeeze your glutes as you lift."], audioCues: [0: "Lie face down. Arms overhead.", 5: "Lift everything off the floor. Hold.", 10: "Lower slowly.", 15: "And lift again."]; (2) "Dead Bug" — beginner, 60s, instructions: ["Lie on your back with arms pointing to the ceiling.", "Lift your legs to a tabletop position, knees at 90 degrees.", "Slowly extend your right arm overhead and left leg out straight.", "Return to center.", "Switch sides."], tips: ["Press your lower back into the floor throughout.", "Move slowly — this is about control, not speed.", "If it's too hard, keep your knees bent as you extend."], audioCues: [0: "Arms up, knees at 90 degrees.", 5: "Right arm back, left leg out.", 10: "Return to center.", 15: "Left arm back, right leg out."]; (3) "Bird Dog" — beginner, 60s, instructions: ["Start on all fours with a flat back.", "Extend your right arm forward and left leg back simultaneously.", "Hold for 3 seconds.", "Return to all fours.", "Switch to left arm and right leg."], tips: ["Keep your hips level — don't let them rotate.", "Move slowly and deliberately.", "Imagine balancing a cup of water on your lower back."], audioCues: [0: "On all fours. Flat back.", 5: "Right arm and left leg out.", 10: "Return.", 15: "Left arm and right leg out."]

**Checkpoint**: Build succeeds. Bodyweight category shows 3 new exercises with
full content. User Story 5 is testable independently.

---

## Phase 8: Data Migration (Cross-Cutting — Depends on All Exercise Phases)

**Purpose**: Add migration logic so existing users (upgrading from the previous
version) get their kegel exercises re-categorized and new exercises inserted.

**Depends on**: T005, T006, T008, T009 (all new exercises must be defined so
the migration can insert them)

- [x] T010 In `daily/Models.swift`, add a `private static func migrateData(context: ModelContext)` method that: (1) fetches all Exercise entities; (2) iterates over exercises and changes `.category` from `.kegels` to `.stretching` for any that match; (3) collects existing exercise names into a Set; (4) builds a list of all new exercises (the 3 new stretching + 6 balance + 2 breathing + 3 bodyweight) plus `kegelExercises()` (since kegel exercises are no longer inserted on fresh install under .kegels — but wait, kegelExercises() already returns .stretching from T004 so existing users have them); (5) for each new exercise whose name is NOT in the existing set, inserts it into the context — then update `seedInitialData(context:)` to call `migrateData(context: context)` in the `else` branch (when `count > 0`)

**Checkpoint**: Build succeeds. Upgrading from the previous version re-categorizes
kegel exercises and inserts all new exercises. No data loss.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Final build validation and manual verification across all stories.

- [x] T011 Perform a clean build (`⇧⌘K` then `⌘B`) in Xcode and confirm zero errors and zero warnings in changed files (`Models.swift`, `ContentView.swift`)

- [x] T012 [P] Run manual verification steps from `specs/002-exercise-review/quickstart.md` for Fix 1 (category reorganization), Fix 2 (new stretching), and Fix 3 (balance safety instructions)

- [x] T013 [P] Run manual verification steps from `specs/002-exercise-review/quickstart.md` for Fix 4 (breathing), Fix 5 (bodyweight), Fix 6 (migration), and Fix 7 (routine compatibility)

<!-- T011–T013 are manual Xcode steps for the developer to complete -->

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — verify baseline
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Phase 2 — kegel recategorization
- **US2 (Phase 4)**: Depends on Phase 2 — can start after T004 (same file, no conflict with US1 task)
- **US3 (Phase 5)**: Depends on Phase 2 — adds balance exercises + seed call
- **US4 (Phase 6)**: Depends on Phase 2 — adds breathing exercises
- **US5 (Phase 7)**: Depends on Phase 2 — adds bodyweight exercises
- **Migration (Phase 8)**: Depends on ALL exercise phases (T005–T009) — needs full exercise list to build migration set
- **Polish (Phase 9)**: Depends on all prior phases complete

### User Story Dependencies

- **US1 (Phase 3)**: No dependencies on other stories — starts after foundational
- **US2 (Phase 4)**: No dependencies on other stories — starts after foundational
- **US3 (Phase 5)**: No dependencies on other stories — starts after foundational
- **US4 (Phase 6)**: No dependencies on other stories — starts after foundational
- **US5 (Phase 7)**: No dependencies on other stories — starts after foundational

### Within Each User Story

- All user story tasks modify `daily/Models.swift` — run sequentially to avoid conflicts
- T003 is the only task in `daily/ContentView.swift` — can run in parallel with Models.swift tasks
- T012 and T013 can run in parallel — independent verification flows

### Parallel Opportunities

- **T002 and T003** can run in parallel — different files (Models.swift vs ContentView.swift)
- **T012 and T013** can run in parallel — independent verification flows

---

## Implementation Strategy

### MVP First (User Story 1 — P1 Only)

1. Complete Phase 1: baseline build
2. Complete Phase 2: enum change + ContentView update (T002, T003)
3. Complete Phase 3: kegel recategorization (T004)
4. **STOP and VALIDATE**: Verify dashboard shows 4 categories, kegel exercises appear under Stretching
5. Ship if only category reorganization is needed

### Recommended Execution Order (solo developer)

1. `⌘B` — confirm green baseline (T001)
2. Add `.balance` to enum + `displayCategories` (T002) — quick, unlocks everything
3. Update ContentView to use displayCategories (T003) — 1 min
4. Change kegelExercises() category to .stretching (T004) — 2 min
5. Add 3 new stretching exercises (T005) — 5 min
6. Add balanceExercises() with 6 exercises + update seed call (T006, T007) — 10 min
7. Add 2 new breathing exercises (T008) — 5 min
8. Add 3 new bodyweight exercises (T009) — 5 min
9. Add migration logic (T010) — 5 min
10. Clean build (T011)
11. Manual verification (T012, T013)

**Estimated scope**: ~35 minutes of implementation across 2 files.

---

## Notes

- All user story tasks are in `daily/Models.swift` — run sequentially to avoid merge conflicts
- T003 is the only task in `daily/ContentView.swift` — independent
- `.kegels` case is KEPT in the enum for SwiftData backward compatibility (see research.md R1)
- Balance exercises MUST include chair/wall safety instructions (see data-model.md and user request)
- T010 (migration) must be the last implementation task — it references all new exercises
- No automated tests added — manual verification via quickstart.md
- BreathingView.swift is dead code — not modified in this feature
