# Feature Specification: Rich Voice Guidance

**Feature Branch**: `004-rich-voice-guidance`
**Created**: 2026-03-24
**Status**: Draft

## Overview

The daily app currently speaks a small number of audio cues during exercises — typically one or two prompts like "switch sides" at the halfway point. Users performing exercises eyes-free (phone face-down, screen locked) receive very little spoken guidance. This feature expands every exercise's voice script into a full, structured set of cues that coach the user from start to finish: setting position, guiding form, counting through phases, prompting side-switches, providing encouragement, and calling out the final stretch.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Guided From Start to Finish (Priority: P1)

A user starts an exercise with their phone set aside. From the moment the timer begins to the moment it completes, they hear clear spoken cues at meaningful intervals — enough to know exactly what to do without looking at the screen.

**Why this priority**: This is the core value of voice guidance. Without rich start-to-finish cues, eyes-free exercise is not meaningfully supported. Every other story builds on this foundation.

**Independent Test**: Start any exercise with audio enabled, place the phone face-down, and complete the full timer. Verify that cues fire at the start (positioning), during (form or pacing), at any side-switch point, and near the end (final encouragement).

**Acceptance Scenarios**:

1. **Given** audio is enabled and an exercise starts, **When** the timer begins, **Then** a spoken cue within the first 3 seconds tells the user how to get into position.
2. **Given** the user is mid-exercise, **When** they are approaching a side-switch or phase change, **Then** a spoken cue prepares them for the transition.
3. **Given** the exercise has a midpoint side-switch (e.g. left/right stretches), **When** the midpoint is reached, **Then** a spoken cue clearly announces the switch and names the new side.
4. **Given** 10 seconds remain in the exercise, **When** that threshold is reached, **Then** a spoken cue acknowledges the effort and encourages the user to hold on.

---

### User Story 2 - Exercise-Specific Form Coaching (Priority: P2)

Rather than generic prompts, each exercise speaks cues that are specific to its movement — a plank cue reminds users to keep hips level; a breathing exercise counts the phases aloud; a stretch cue reminds users to relax into the position rather than force it.

**Why this priority**: Generic cues ("keep going", "almost done") add noise without value. Cues tailored to each exercise's technique make voice guidance genuinely useful for safety and better results.

**Independent Test**: Run three distinct exercises from different categories (bodyweight, breathing, stretching) with audio enabled. Verify that the spoken cues reference that exercise's specific form or phase — not generic filler text.

**Acceptance Scenarios**:

1. **Given** the user is doing a timed-hold bodyweight exercise (e.g. plank), **When** a mid-exercise cue fires, **Then** it references a specific form point for that exercise (e.g. "keep your hips level, core tight").
2. **Given** the user is doing a phased breathing exercise (e.g. box breathing), **When** each phase begins, **Then** a cue calls out the phase name and count (e.g. "Inhale — four counts").
3. **Given** the user is doing a passive stretch, **When** mid-exercise cues fire, **Then** they encourage relaxing into the position rather than demanding active effort (e.g. "breathe into the stretch").

---

### User Story 3 - Encouragement and Pacing Cues (Priority: P3)

Beyond technique coaching, the voice system delivers well-timed encouragement and pacing prompts — letting users know how far through they are and keeping motivation up during longer exercises.

**Why this priority**: Motivation cues improve completion rates for longer exercises. They are lower priority than form coaching but meaningfully improve the experience for exercises over 90 seconds.

**Independent Test**: Run a 3-minute or longer exercise with audio enabled. Verify at least one motivational or pacing cue fires between the opening instruction and the final 10-second window.

**Acceptance Scenarios**:

1. **Given** an exercise longer than 90 seconds, **When** approximately halfway through, **Then** a spoken cue acknowledges the midpoint (e.g. "Halfway there — keep it up").
2. **Given** the user is in the final 10 seconds of any exercise, **When** that window begins, **Then** a cue signals the end is near (e.g. "Almost there — last few seconds").
3. **Given** the exercise timer reaches zero, **When** the completion event fires, **Then** the existing "Exercise complete. Great job!" cue plays — this behaviour is preserved unchanged.

---

### Edge Cases

- What happens when the user pauses the timer mid-exercise? Pausing stops the timer tick, so no new cues fire while paused. On resume, the timer continues from the paused second and cues fire at their correct elapsed timestamps as normal.
- What happens when audio is disabled? All cues are silently skipped — no spoken output. The existing `audioEnabled` toggle continues to suppress all cues.
- What happens if two cues are assigned the same timestamp? Only one would fire. The cue scripts must assign unique timestamps; this is verified before shipping.
- What happens for very short exercises (under 30 seconds)? Only a start cue and a near-end cue are appropriate. Intermediate cues are omitted to avoid speech overlap.
- What happens if a cue fires while a previous cue is still being spoken? The existing TTS manager handles queuing and interruption — its behaviour is unchanged by this feature.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Every exercise MUST have at least one audio cue at second 0 (or within the first 3 seconds) describing how to get into position.
- **FR-002**: Every exercise with a midpoint side-switch or phase change MUST have a spoken cue at the transition timestamp that names the new side or phase explicitly (e.g. "Switch to your left leg" not just "Switch").
- **FR-003**: Every exercise longer than 90 seconds MUST have at least one mid-exercise cue between the opening cue and the final 10-second window.
- **FR-004**: Every exercise MUST have a cue in the final 10 seconds signalling that the exercise is nearly complete.
- **FR-005**: Cues for bodyweight and strength exercises MUST include at least one form-specific coaching point relevant to that exercise's primary movement pattern.
- **FR-006**: Cues for breathing exercises MUST call out each phase (inhale, hold, exhale) at the correct timestamp matching the phase duration.
- **FR-007**: Cues for passive stretches MUST use calm, relaxing language (e.g. "breathe into the stretch") rather than high-intensity effort prompts.
- **FR-008**: No two cues within a single exercise MAY share the same timestamp.
- **FR-009**: The audio toggle (mute/unmute) MUST continue to suppress all cues when disabled — no change to the existing mute behaviour.
- **FR-010**: The existing completion cue ("Exercise complete. Great job!") MUST be preserved and continue to fire when the timer reaches zero.

### Key Entities

- **AudioCue**: A timestamp-to-text pairing `(seconds → text)` attached to an exercise. The timestamp is the number of seconds elapsed since the exercise started when the cue fires.
- **Exercise**: An existing entity whose `audioCues` field (a dictionary of elapsed-seconds to spoken text) is expanded by this feature. No structural changes to the entity are required — only its content changes.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of exercises have a spoken cue within the first 3 seconds — verifiable by inspecting the exercise seed data.
- **SC-002**: 100% of exercises with side-switches have an explicitly named transition cue at the switch timestamp — verifiable by inspection.
- **SC-003**: 100% of exercises longer than 90 seconds have at least 3 distinct cues (start, mid, near-end) — verifiable by counting cues per exercise.
- **SC-004**: A user completing a full exercise eyes-free can determine correct positioning and all major transitions solely from spoken cues — verifiable by a blind walkthrough of at least 5 exercises across different categories.
- **SC-005**: Zero exercises have duplicate timestamps in their cue dictionary — verifiable by inspection of all cue keys.

## Assumptions

- The `audioCues: [Int: String]` data model is sufficient for this feature; no schema changes are needed.
- Cue text is written in plain, natural English intended to be read aloud by text-to-speech — short, clear sentences work better than long ones.
- All 61 exercises currently in the library are in scope. Exercises added after this branch are out of scope.
- The existing TTS delivery system (speak on elapsed second match) is unchanged; this feature only changes the content of the cue scripts.
- Cue timestamps are based on elapsed seconds from exercise start (0 = the first second the timer begins), matching the existing convention.
- Exercises under 30 seconds receive only a start cue and a near-end cue to avoid speech overlap given the short duration.
