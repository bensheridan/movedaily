# Research: Rich Voice Guidance

**Branch**: `004-rich-voice-guidance` | **Phase**: 0 | **Date**: 2026-03-24

---

## Cue Audit: Current State of audioCues Across All 61 Exercises

### Critical Gap: Bodyweight Exercises (20 exercises, 0 cues)

All 20 original bodyweight exercises (`originalBodyweightExercises()`) have **empty `audioCues` dictionaries**:
Push-ups, Knee Push-ups, Plank Shoulder Taps, Triceps Dips, Arm Circles, Inchworm Walks, Front Plank, Side Plank, Glute Bridges, Bicycle Crunches, Leg Raises, Mountain Climbers, Squats, Lunges, Calf Raises, Wall Sit, Burpees, Clamshells, Diamond Push-ups, Jump Squats.

### Secondary Gap: Long Exercises Without Cycling Cues

These exercises are 2–5 minutes long but have cues only for the first 12–35 seconds, leaving 2–4 minutes of silence:
- Box Breathing (300s) — 4 cues covering 1 cycle (16s), then silence
- Resonant Breathing (300s) — 2 cues covering 12s, then silence
- Progressive Relaxation (300s) — 2 cues covering 30s, then silence
- Belly Breathing (180s) — 3 cues covering 10s, then silence
- 4-7-8 Breathing (120s) — 3 cues covering 19s, then silence
- Standard Kegels / Elevator Kegels (120s each) — cycling cues stop after first cycle

### Tertiary Gap: Missing Near-End Cues

Most 60s exercises have no cue in the final 10 seconds. Users have no spoken signal that the exercise is about to complete.

### What Works Well (preserve)

- `Wrist & Forearm Stretch`: 4 cues with correct side-switch timing ✓
- `Superman Hold`, `Dead Bug`, `Bird Dog`: Rich repetition cues ✓
- `Weight Shifts`, `Standing Knee Lifts`, `Clock Reach`: Good multi-cue structure ✓
- `Lion's Breath`, `Humming Bee Breath`: Phase-aware cues ✓
- The existing completion cue in `ExerciseDetailView` ("Exercise complete. Great job!") fires at t=durationSeconds — preserve this ✓

---

## Decision 1: Migration Strategy

**Decision**: No migration needed. This is a new app targeting fresh installs only. The updated `audioCues` values are delivered via the seed data (`seedInitialData`) which runs on first launch when the exercise count is zero. All users will receive the new cues from the start.

**Rationale**: Confirmed by product owner. No existing user base to migrate.

---

## Decision 2: Cue Cadence Standard

**Question**: How many cues per exercise, and at what timestamps?

**Decision**: Apply these rules by exercise duration and type:

| Duration | Minimum cues | Required positions |
|----------|-------------|-------------------|
| < 30s | 2 | t=0, t=duration-8 |
| 30–90s | 3–4 | t=0, midpoint(s), t=duration-10 |
| 91–180s | 5–7 | t=0, every ~30s, t=duration-10 |
| 181–300s | 8–15 | t=0, every 15–20s for cycling phases, t=duration-10 |

**Special rules**:
- Side-switch exercises: cue at t=0 (start side), t=durationSeconds/2 (switch), t=durationSeconds-10 (near-end)
- Isometric holds (plank, wall sit): form coaching at t=15, t=30, encouragement at t=50 (for 60s)
- Breathing cycles: cue fires at every phase boundary for the entire duration
- Repetition exercises (push-ups, squats): pace cue at t=0, form check at t=20, halfway encouragement at t=30, near-end at t=50

---

## Decision 3: Cue Language Standard

**Question**: What tone, length, and style should cues follow?

**Decision**:
- **Maximum length**: 8 words per cue (TTS reads ~2.5 words/second; 8 words ≈ 3 seconds)
- **Bodyweight (active)**: Directive, present tense. "Keep hips level." "Push through your heels." "Good — hold it."
- **Stretching (passive)**: Calm, inviting. "Breathe into the stretch." "Let gravity do the work." "Relax your shoulders."
- **Breathing**: Phase-naming. "Inhale — four counts." "Hold." "Exhale slowly." No filler words.
- **Balance**: Safety-aware. "Hold the chair if needed." "Eyes forward, nice and steady."
- **Near-end (all types)**: "Almost there." or "Last few seconds — finish strong."
- **Avoid**: "Great job" mid-exercise (save for completion), "now" as filler, "please", second-guessing ("if you can"), overly long sentences.

---

## Decision 4: File Structure — Single File, Targeted Edits

**Question**: Should cue updates go in a separate constants file?

**Decision**: Update `audioCues` dictionaries directly in `Models.swift` where each exercise is defined. No new file needed.

**Rationale**: All exercise data is already co-located in `Models.swift`. Splitting cues into a separate file would require a lookup mechanism (by name string), adding indirection. Direct co-location is simpler, matches the existing pattern, and is the minimum viable approach (Constitution Principle V).
