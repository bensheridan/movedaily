# Quickstart: Rich Voice Guidance

**Branch**: `004-rich-voice-guidance` | **Phase**: 1 | **Date**: 2026-03-24

---

## How Cues Fire (Existing System)

The TTS pipeline is unchanged by this feature. For reference:

1. `ExerciseDetailView` starts a 1-second repeating timer when the user begins an exercise.
2. Each tick increments `elapsedSeconds`.
3. On each tick, the view checks `exercise.audioCues[elapsedSeconds]`.
4. If a value exists and `audioEnabled == true`, it calls `TTSManager.shared.speak(text)`.
5. At `elapsedSeconds == exercise.durationSeconds`, the completion cue fires: `"Exercise complete. Great job!"` — this is **not** in `audioCues`; it is hardcoded in the view.

The feature adds cue content only. No code changes to the timer or TTS dispatch logic are needed.

---

## Integration Scenarios

These scenarios are used to verify the feature works end-to-end after implementation.

### Scenario 1 — Bodyweight Exercise (Push-ups, 60s)

**Target cues after implementation**:

| t (s) | Cue |
|-------|-----|
| 0 | "Start in a high plank position." |
| 15 | "Keep your core tight, hips level." |
| 30 | "Good pace — halfway there." |
| 50 | "Last few seconds — finish strong." |

**Test**: Start Push-ups with audio enabled, phone face-down. Verify all four cues are spoken at the correct elapsed times. No cues in the first 14 seconds except t=0.

---

### Scenario 2 — Breathing Exercise (Box Breathing, 300s)

**Target cue pattern** (repeating every 16 seconds for the full 5 minutes):

| t (s) | Cue |
|-------|-----|
| 0 | "Sit tall, relax your shoulders." |
| 4 | "Inhale — four counts." |
| 8 | "Hold — four counts." |
| 12 | "Exhale — four counts." |
| 16 | "Hold — four counts." |
| 20 | "Inhale — four counts." |
| ... | (repeating cycle) |
| 290 | "Almost there." |

**Test**: Start Box Breathing. Verify phase-name cues fire every 4 seconds matching the inhale / hold / exhale / hold cycle. Verify silence does not exceed 4 seconds at any point during the exercise.

---

### Scenario 3 — Side-Switch Stretch (Hamstring Stretch, 60s)

**Target cues after implementation**:

| t (s) | Cue |
|-------|-----|
| 0 | "Sit and extend your right leg." |
| 30 | "Switch to your left leg." |
| 50 | "Almost there." |

**Test**: Start Hamstring Stretch. Verify the t=30 cue explicitly names "left leg" (not just "switch"). Verify t=0 names the starting side.

---

### Scenario 4 — Long Stretch with Mid-Cue (Child's Pose, 60s)

**Target cues after implementation**:

| t (s) | Cue |
|-------|-----|
| 0 | "Kneel and reach arms forward." |
| 30 | "Breathe into the stretch." |
| 50 | "Almost there." |

**Test**: Start Child's Pose. Verify all three cues fire. The t=30 cue uses calm language (not an active effort prompt).

---

### Scenario 5 — Audio Disabled

**Test**: Toggle audio off in settings. Start any exercise. Verify no speech is heard for any elapsed second — including cues that exist in `audioCues`. The existing `audioEnabled` toggle suppresses all cues.

---

### Scenario 6 — Pause and Resume

**Test**: Start a 60s exercise. At t=20, pause the timer. Wait 10 seconds (real time). Resume. Verify the cue for t=30 fires approximately 10 seconds after resuming (i.e., elapsed time resumes from 20, not 30+).

---

## Verification Checklist (SC-001 to SC-005)

| Criterion | How to Verify |
|-----------|---------------|
| SC-001: 100% exercises have t≤3 cue | Inspect all 61 `audioCues` dictionaries; confirm `audioCues[0]`, `[1]`, `[2]`, or `[3]` is non-nil for every exercise |
| SC-002: 100% side-switch exercises have explicit named transition cue | Inspect exercises with `/2` cues; confirm text contains "left" or "right" or names the specific side |
| SC-003: 100% of exercises >90s have ≥3 cues | Count cues per exercise for all 15 exercises with `durationSeconds > 90` |
| SC-004: Eyes-free blind walkthrough | Run 5 exercises (1 bodyweight, 1 breathing, 1 stretch, 1 balance, 1 side-switch) with phone face-down; verify positioning and all transitions are audible |
| SC-005: Zero duplicate timestamps | Inspect all `audioCues` keys per exercise; confirm no duplicates within a single exercise's dictionary |
