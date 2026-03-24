# Tasks: Rich Voice Guidance

**Input**: Design documents from `/specs/004-rich-voice-guidance/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

**Organization**: Tasks are grouped by user story. All tasks modify `daily/Models.swift` only — one file, sequential execution. No [P] markers apply.

## Format: `[ID] [Story] Description`

- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- All tasks target `daily/Models.swift` — execute sequentially within each phase

---

## Phase 1: Setup

**Purpose**: Understand the current state of audioCues across all 61 exercises before editing.

- [x] T001 Read `daily/Models.swift` in full — identify the 5 category factory functions (`originalStretchingExercises`, `originalBreathingExercises`, `originalBodyweightExercises`, and any balance/pelvic-floor functions) and confirm current audioCues values match the audit in `specs/004-rich-voice-guidance/data-model.md`

---

## Phase 2: Foundational

**Purpose**: No schema or infrastructure changes required. This feature is content-only. Phase 2 is a single validation checkpoint.

**⚠️ CRITICAL**: Confirm `Exercise.audioCues` is of type `[Int: String]` and that `seedInitialData` is the sole delivery mechanism before editing any cues.

- [x] T002 Verify in `daily/Models.swift` that `audioCues: [Int: String]` exists on `Exercise`, that `seedInitialData(context:)` inserts exercises on first launch, and that no migration plan is needed — then proceed

**Checkpoint**: Foundation confirmed — user story implementation can now begin

---

## Phase 3: User Story 1 — Guided From Start to Finish (Priority: P1) 🎯 MVP

**Goal**: Every exercise has a spoken cue within the first 3 seconds (positioning), a named side-switch cue at the midpoint for bilateral exercises, and a near-end cue in the final 10 seconds.

**Independent Test**: Start any exercise with audio enabled, phone face-down. Verify a cue fires at t=0–3 (positioning), at t=durationSeconds/2 for bilateral exercises (names the new side explicitly), and at t=durationSeconds-10 (near-end signal). Run Scenarios 1, 3, and 5 from `quickstart.md`.

### Implementation for User Story 1

- [x] T003 [US1] In `daily/Models.swift` — add opening cue (t=0) and near-end cue (t=50) to these 17 standard stretching exercises that are currently missing one or both: Shoulder Rolls, Chest Stretch (Doorway), Cat-Cow, Triceps Stretch, Side Reach Stretch, Hamstring Stretch, Quadriceps Stretch, Calf Stretch, Hip Flexor Stretch, Figure-4 Stretch, Butterfly Stretch, Child's Pose, IT Band Stretch, Pigeon Pose, Seated Spinal Twist — plus side-switch cue at t=30 naming the new side for Hamstring Stretch, Quadriceps Stretch, Calf Stretch, Hip Flexor Stretch, Figure-4 Stretch, IT Band Stretch, Pigeon Pose, Side Reach Stretch (currently missing explicit side name)

- [x] T004 [US1] In `daily/Models.swift` — add near-end cue (t=50 for 60s, t=110 for 120s) to these pelvic-floor / kegel stretching exercises: Muscle Discovery (t=50), Power Pulses (t=50), Standard Kegels M (t=110), Standard Kegels F (t=110), Elevator Kegels (t=110)

- [x] T005 [US1] In `daily/Models.swift` — add opening cue (t=0) and near-end cue to these breathing exercises: Belly Breathing (t=170), 4-7-8 Breathing (t=110), Box Breathing (t=290), Alternate Nostril (t=170), Pursed Lip Breathing (t=110), Resonant Breathing (t=290), Gentle Breath Holds (t=110), Progressive Relaxation (t=290), Lion's Breath (t=110), Humming Bee Breath (t=170) — replace any existing near-end cue if already present, otherwise add

- [x] T006 [US1] In `daily/Models.swift` — add opening cue (t=0), at least one mid-exercise cue (t=30), and near-end cue (t=50) to all 20 zero-cue bodyweight exercises: Push-ups, Knee Push-ups, Plank Shoulder Taps, Triceps Dips, Arm Circles, Inchworm Walks, Front Plank, Side Plank, Glute Bridges, Bicycle Crunches, Leg Raises, Mountain Climbers, Squats, Lunges, Calf Raises, Wall Sit, Burpees, Clamshells, Diamond Push-ups, Jump Squats — and add near-end cue (t=50) to Superman Hold, Dead Bug, and Bird Dog — use placeholder cue language (e.g., "Get into position.", "Keep going.", "Almost there.") for now; US2 will replace mid-cues with form-specific content

- [x] T007 [US1] In `daily/Models.swift` — add near-end cue (t=50) to all 6 balance exercises that are missing it: Single-Leg Stand, Heel-to-Toe Walk, Tree Pose — and confirm Standing Knee Lifts, Weight Shifts, and Clock Reach already have a cue at t≥50

**Checkpoint**: Every exercise now has t=0 cue + near-end cue. Bilateral exercises have explicit named side-switch cues. User Story 1 is independently verifiable.

---

## Phase 4: User Story 2 — Exercise-Specific Form Coaching (Priority: P2)

**Goal**: Each exercise's mid-exercise cues reference that exercise's specific form, technique, or phase — not generic filler text.

**Independent Test**: Run Push-ups, Box Breathing, and Hamstring Stretch with audio enabled. Verify that mid-exercise cues reference exercise-specific form points (not "keep going"). Run Scenarios 2 and 4 from `quickstart.md`.

### Implementation for User Story 2

- [x] T008 [US2] In `daily/Models.swift` — replace the placeholder mid-exercise cues (from T006) with form-specific coaching cues for all 20 zero-cue bodyweight exercises and add correct side-switch cues for bilateral ones:
  - Plank-type holds (Front Plank, Side Plank, Plank Shoulder Taps, Wall Sit): "Keep hips level, core tight." at t=15 and "Breathe — don't hold your breath." at t=30
  - Side Plank + Clamshells + Arm Circles: side-switch cue at t=30 naming the new side explicitly (e.g., "Switch to your left side.")
  - Push-type (Push-ups, Knee Push-ups, Diamond Push-ups, Triceps Dips): "Lower with control, chest to floor." at t=20
  - Leg/glute exercises (Glute Bridges, Leg Raises, Bicycle Crunches, Mountain Climbers): exercise-specific form cue at t=20 (e.g., "Drive through your heels." / "Keep your lower back flat.")
  - Full-body (Burpees, Jump Squats, Inchworm Walks): pace-check at t=20 (e.g., "Land softly — control the jump.")
  - Squat/lunge pattern (Squats, Lunges): "Knees track over toes — chest up." at t=20; Lunges side-switch at t=30

- [x] T009 [US2] In `daily/Models.swift` — replace or supplement opening cues in all 10 breathing exercises with phase-naming cues that explicitly call out each inhale/hold/exhale/hold phase boundary:
  - 4-7-8 Breathing (120s): inhale at t=0 (4s), hold at t=4 (7s), exhale at t=11 (8s), repeat cues for remaining cycles
  - Box Breathing (300s): placeholder start + cycle cues — US3 (T012) will fill the full cycling script
  - Pursed Lip Breathing (120s): "Inhale through your nose." at t=0, "Exhale through pursed lips." at t=4, then repeat cues
  - Alternate Nostril (180s): side-instruction cues ("Right nostril closed — inhale left." etc.)
  - Lion's Breath (120s): phase cues are largely present — verify language is phase-specific, not generic
  - Humming Bee Breath (180s): phase cues largely present — verify and top up if needed

- [x] T010 [US2] In `daily/Models.swift` — update mid-exercise cues for the following stretching exercises to use calm, relaxing language (per the language standard in `research.md`): Cat-Cow (add cycling cue "Inhale — arch your back." and "Exhale — round your spine."), Hip Flexor Stretch ("Let your hips sink forward gently."), Chest Stretch ("Breathe — let your chest open."), Pigeon Pose ("Breathe into your hip — let it soften."), Seated Spinal Twist ("Breathe — deepen the twist on each exhale."), Child's Pose t=30 ("Breathe deep — let your back expand.") — ensure no cue uses effort language like "push" or "harder"

- [x] T011 [US2] In `daily/Models.swift` — update or add mid-exercise form cues for all 6 balance exercises using safety-aware language: Single-Leg Stand ("Hold the wall if needed." at t=15 and "Eyes forward, soft focus." at t=30), Heel-to-Toe Walk ("Arms out for balance, eyes forward." at t=15), Tree Pose ("Hold the chair if needed." at t=15 and "Find a focus point — breathe." at t=30)

**Checkpoint**: All exercises now have exercise-specific cues. User Story 2 is independently verifiable.

---

## Phase 5: User Story 3 — Encouragement and Cycling Cues for Long Exercises (Priority: P3)

**Goal**: Exercises longer than 90 seconds have at least one mid-exercise motivational or pacing cue between the opening instruction and the final 10-second window. Breathing and kegel exercises running 2–5 minutes have cycling cues covering the full duration.

**Independent Test**: Run Box Breathing (300s) with audio enabled. Verify phase-name cues fire every 4 seconds for the full 5 minutes with no silence exceeding 4 seconds. Run Scenario 2 from `quickstart.md`.

### Implementation for User Story 3

- [x] T012 [US3] In `daily/Models.swift` — add full cycling cue scripts to the 3 longest breathing exercises:
  - **Box Breathing (300s)**: 4-phase cycle (inhale 4s → hold 4s → exhale 4s → hold 4s = 16s/cycle); add cues at t=4, 8, 12, 16, 20, 24, 28, 32 … t=284 — each cue names the phase ("Inhale — four counts.", "Hold.", "Exhale — four counts.", "Hold."); t=290 already set in T005
  - **Resonant Breathing (300s)**: inhale 5s → exhale 6s = 11s/cycle; add cues at t=5, 11, 16, 22 … t=289 alternating "Exhale — slow and steady." / "Inhale — fill your lungs."; t=290 already set in T005
  - **Progressive Relaxation (300s)**: body-scan cues at ~30s intervals targeting successive muscle groups (e.g., "Tense your feet — hold." at t=10, "Release." at t=15, "Tense your calves." at t=30 etc.); t=290 already set in T005

- [x] T013 [US3] In `daily/Models.swift` — add cycling/repeat cues to the remaining long breathing exercises:
  - **Belly Breathing (180s)**: inhale 4s → exhale 6s = 10s/cycle; cues at t=4, 10, 14, 20 … t=170 already set in T005
  - **Alternate Nostril (180s)**: per-side cues through full 3 minutes (work continues from T009 phase cues)
  - **Gentle Breath Holds (120s)**: inhale → hold → exhale cycle cues through full 2 minutes
  - **4-7-8 Breathing (120s)**: complete remaining repeat cycles beyond what T009 added; cues at t=19, 23, 30, 38 (2nd cycle) and t=38, 42, 49, 57 (3rd cycle); t=110 already set in T005

- [x] T014 [US3] In `daily/Models.swift` — add cycling cues to the 3 long kegel exercises that stop after the first cycle: Standard Kegels M (120s) — contract 5s / rest 5s = 10s/cycle, add cues at t=10, 20, 30 … t=100 alternating "Contract." / "Relax."; Standard Kegels F (120s) — same pattern; Elevator Kegels (120s) — progressive hold levels ("Squeeze to level one.", "Level two — hold.", "Level three — squeeze tight.", "Release slowly.") cycling for 2 minutes; all three already have t=110 set in T005

**Checkpoint**: All long exercises now have cycling cues covering their full duration. User Story 3 is independently verifiable.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Final compliance audit across all 61 exercises before the feature is considered complete.

- [x] T015 Audit all 61 exercises in `daily/Models.swift` for compliance with the Cue Content Standard from `specs/004-rich-voice-guidance/data-model.md`: (1) every exercise has a cue at t≤3; (2) every bilateral exercise has an explicit named side-switch cue at t=durationSeconds/2; (3) every exercise >90s has ≥3 distinct cues; (4) no exercise has duplicate timestamps; (5) no cue value exceeds 8 words — fix any violations found

- [x] T016 Manually run all 6 integration scenarios from `specs/004-rich-voice-guidance/quickstart.md` against the updated seed data to verify end-to-end cue delivery

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — confirms preconditions before editing
- **US1 (Phase 3)**: Depends on Phase 2 — establishes skeleton cues; T003–T007 are sequential (same file)
- **US2 (Phase 4)**: Depends on Phase 3 completion — replaces placeholder cues with form-specific content; T008–T011 sequential
- **US3 (Phase 5)**: Depends on Phase 3 (near-end cues must exist); T012–T014 sequential
- **Polish (Phase 6)**: Depends on all user story phases being complete

### User Story Dependencies

- **US1 (P1)**: Standalone — no prior story dependency
- **US2 (P2)**: Builds on US1 skeleton (replaces placeholder mid-cues with form-specific cues)
- **US3 (P3)**: Extends US1 (adds cycling cues beyond the start + near-end skeleton)

### Within Each Phase

- All tasks within a phase target `daily/Models.swift` — execute sequentially, one category at a time
- No parallel execution within any phase (same file)
- Commit after each task (or after completing a full category within a task)

### Parallel Opportunities

- Phase 3, 4, and 5 cannot be parallelized internally (same file), but each phase is independently completable — implement US1 → demo → implement US2 → demo → implement US3

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational (T002)
3. Complete Phase 3: US1 (T003–T007) — skeleton cues for all 61 exercises
4. **STOP and VALIDATE**: Run quickstart.md Scenarios 1, 3, 5
5. Ship US1 — every exercise has voice guidance from start to finish

### Incremental Delivery

1. Setup + Foundational → confirmed
2. US1 → test → ✅ start + near-end + side-switch for all exercises
3. US2 → test → ✅ form-specific coaching throughout
4. US3 → test → ✅ full cycling cue scripts for long exercises
5. Polish → ✅ compliance audit passes SC-001 to SC-005

---

## Notes

- All 61 exercises live in `daily/Models.swift` — no other files require modification
- cue keys are elapsed seconds from exercise start (t=0 = first second of exercise)
- Cue language standards: bodyweight = directive ("Keep hips level."), stretch = calm ("Breathe into the stretch."), breathing = phase-named ("Inhale — four counts."), balance = safety-aware ("Hold the chair if needed.")
- Maximum 8 words per cue value — count words before writing
- "Exercise complete. Great job!" fires at `durationSeconds` from `ExerciseDetailView`, not from `audioCues` — do not add this to the dictionary
- Commit after each task completes — one logical group per commit
