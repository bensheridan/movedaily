# Feature Specification: App Review & Bug Fix Audit

**Feature Branch**: `001-app-review-audit`
**Created**: 2026-03-24
**Status**: Draft
**Input**: User description: "review the current app, is everything working?"

## Summary

A thorough review of the app found five defects across the core gameplay loop,
exercise execution flow, and profile screen. This spec captures all issues as
user-facing stories so they can be fixed independently.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Streak and XP track correctly (Priority: P1)

A user completes their daily routine and expects their streak count, XP, and
level to update according to the published rules: XP is awarded once per day,
missed days reset the streak to 1, hitting a streak milestone (7, 30, 100
days) awards bonus XP, and levelling up rolls over XP correctly.

Today the app contains two competing implementations of the completion logic.
The one that actually runs does not reset broken streaks, does not award
milestone bonuses, and may calculate level-ups incorrectly. The correct
implementation is present in the codebase but is never called.

**Why this priority**: Streak and XP are the primary motivation mechanics. If
they behave incorrectly users lose trust in the app immediately.

**Independent Test**: Complete a routine on two consecutive days and verify
streak increases; skip a day, complete again, and verify streak resets to 1;
reach streak day 7 and verify +50 bonus XP is awarded.

**Acceptance Scenarios**:

1. **Given** the user has a 6-day streak, **When** they complete a routine the
   next day, **Then** their streak becomes 7 and they receive base XP plus
   50 bonus XP.
2. **Given** the user has a streak, **When** they complete a routine for the
   second time on the same calendar day, **Then** no additional XP or streak
   increment is awarded.
3. **Given** the user has a 3-day streak, **When** they skip a day and then
   complete a routine, **Then** their streak resets to 1.
4. **Given** the user has 90 XP and earns 20 base XP, **When** the routine
   completes, **Then** their level increases by 1 and XP rolls over to 10.

---

### User Story 2 - Exercise timer completes exactly once (Priority: P2)

A user runs an exercise countdown and, when time reaches zero, the app plays
a completion sound/vibration and says "Exercise complete. Great job!" exactly
one time, then stays silent.

Today, after the timer hits zero the completion haptic and spoken message fire
repeatedly — every second — until the user leaves the screen.

**Why this priority**: Repeated vibrations and speech are disruptive and make
the app feel broken during the core exercise flow.

**Independent Test**: Start any exercise, wait for the countdown to reach
zero, and confirm the completion cue fires only once. Wait 5 seconds and
confirm no further cues fire.

**Acceptance Scenarios**:

1. **Given** an exercise is in progress, **When** the timer reaches zero,
   **Then** exactly one haptic pulse and one spoken "Exercise complete" message
   play, and the timer stops advancing.
2. **Given** the timer has already reached zero, **When** 5 additional seconds
   pass, **Then** no further haptics or speech occur.
3. **Given** the user presses the reset button after completion, **When** they
   do not start the timer again, **Then** no completion cues fire.

---

### User Story 3 - Profile screen navigates and displays correctly (Priority: P3)

A user taps the profile icon in the top-right corner of the dashboard and
sees a clean profile screen that: shows their stats (streak, level, XP) as
read-only, lets them change their gender, and has a single navigation bar
with a back button.

Today the profile screen wraps itself in its own navigation container while
already being inside the app's navigation, producing a duplicate navigation
bar. Additionally, a "Close" button appears that does nothing. Level and XP
can also be edited via steppers, bypassing the game's progression rules.

**Why this priority**: The profile screen is visually broken on every visit
and allows data corruption via the editable steppers.

**Independent Test**: Navigate to the profile screen, verify one navigation
bar is shown, verify Level and XP are displayed as text (not editable), and
verify the back button returns to the dashboard.

**Acceptance Scenarios**:

1. **Given** the user is on the dashboard, **When** they tap the profile icon,
   **Then** they see exactly one navigation bar with a "Profile" title and a
   back button.
2. **Given** the profile screen is open, **When** the user looks at Level and
   XP, **Then** they are displayed as read-only text values (not adjustable
   controls).
3. **Given** the profile screen is open, **When** the user changes their
   gender and goes back, **Then** the dashboard greeting reflects the new
   gender on next appearance.

---

### User Story 4 - Profile screen includes notifications and photo (Priority: P4)

A user opens the profile screen and can: set a daily reminder time, toggle
the reminder on/off, upload a profile photo from their photo library, and
reset their stats (with a confirmation prompt). These features are already
built but stored in the wrong location and blocked by a mismatch between the
reminder API's expected input format and how callers invoke it.

**Why this priority**: Lower priority than correctness fixes but these are
complete features that just need to be wired up correctly.

**Independent Test**: Enable a reminder, set a time, close and reopen the
app — the reminder persists. Tap the profile photo area and pick an image —
it persists across app restarts.

**Acceptance Scenarios**:

1. **Given** the profile screen is open, **When** the user enables the daily
   reminder and picks a time, **Then** the system schedules a notification at
   that time each day.
2. **Given** the reminder is enabled, **When** the user changes the reminder
   time, **Then** the previous notification is cancelled and a new one is
   scheduled at the updated time.
3. **Given** the profile screen is open, **When** the user taps the profile
   photo and selects an image, **Then** the chosen photo is saved and shown
   on all subsequent visits.
4. **Given** the profile screen is open, **When** the user taps "Reset
   Profile" and confirms, **Then** streak, XP, and level reset to defaults
   while gender and photo are preserved.

---

### Edge Cases

- What happens when a routine contains exercise names that don't match any
  seeded exercise (e.g., after a data migration)? The routine detail screen
  shows an empty list rather than crashing.
- What happens when `routineCompleted` callback is nil? No crash — completion
  is silently skipped.
- What happens if the user revokes notification permission after enabling the
  reminder? The reminder toggle should reflect actual permission state on
  next launch.
- What happens if the user taps "Start Routine" on a routine with zero
  matching exercises? The button should be disabled or the sheet should show
  a friendly empty state.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The routine completion logic MUST award XP once per calendar
  day, reset the streak on missed days, grant milestone bonus XP at 7/30/100
  day streaks, and level up by rolling over XP correctly.
- **FR-002**: There MUST be exactly one implementation of routine completion
  logic; duplicate implementations MUST be removed.
- **FR-003**: The exercise timer MUST fire completion feedback (haptic +
  speech) exactly once when the countdown reaches zero, then stop.
- **FR-004**: The profile screen MUST NOT introduce a second navigation
  container — it MUST inherit the app's existing navigation hierarchy.
- **FR-005**: Level and XP MUST be displayed as read-only values on the
  profile screen; only Gender MUST be user-editable.
- **FR-006**: The profile screen MUST allow the user to set and toggle a
  daily reminder notification with a user-selected time.
- **FR-007**: The profile screen MUST allow the user to upload and persist a
  profile photo from their photo library.
- **FR-008**: The profile screen MUST offer a "Reset Profile" action with a
  destructive confirmation dialog that resets XP, level, and streak while
  preserving gender and photo.
- **FR-009**: The notification scheduling function MUST accept a consistently
  typed time value; all call sites MUST use the same calling convention.

### Key Entities

- **UserProfile**: The user's persistent state — gender, XP, level, streak
  count, last exercise date, and optional profile photo.
- **Exercise**: A single exercise with a countdown duration, category,
  difficulty, optional gender focus, instructions, tips, and timed audio cues.
- **Routine**: A named sequence of exercise references presented as the
  daily recommendation.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After completing the same routine twice in one day, XP and
  streak count remain unchanged on the second completion.
- **SC-002**: After completing a routine on day 7 of a continuous streak, the
  user's XP increases by at least 70 (20 base + 50 milestone bonus) in that
  session.
- **SC-003**: An exercise timer that has reached zero produces no additional
  haptic or audio output within a 10-second observation window.
- **SC-004**: The profile screen renders with exactly one navigation bar in
  all orientations and device sizes.
- **SC-005**: Level and XP fields on the profile screen are not interactive —
  tapping or long-pressing them produces no editable control.
- **SC-006**: A daily reminder notification set at a specific time fires at
  that time on the following day.
- **SC-007**: A profile photo selected by the user is visible after closing
  and relaunching the app without any additional steps.
