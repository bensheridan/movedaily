# Feature Specification: Session Duration Tiers

**Feature Branch**: `005-session-tiers`
**Created**: 2026-03-24
**Status**: Draft
**Input**: User description: "ok new feature, the current app builds quick workouts 10-12 mins, as users level up, I want to be able allow them to optionally select longer sessions. 10-12(or what ever the default is now), 15-20 and 20-30, these levels will be locked Beginner only has access to 10-12, Intermidate can also select 15-20 and Advanced can select 20-30. We will need to extend the times and reps on excersice to be able to increase the times. And we weill need to set Experience points to levels. We will need sesible time lines between levels. 30days of activity Beginner to Advanced, maybe add bonus points for streaks,. and another 60 days to Advanced"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Session Tier Selection (Priority: P1)

A user opens the workout generation screen and, depending on their current level, can choose how long their session will be. Beginners see only the 10-12 min option. Intermediate users additionally see a 15-20 min option. Advanced users additionally see a 20-30 min option. The chosen tier is remembered for future sessions so the user does not need to re-select it every time.

**Why this priority**: The tier selector is the primary user-visible surface of the feature — it directly delivers the core value proposition of longer workouts for more experienced users, and it gates everything downstream.

**Independent Test**: Can be fully tested by setting a user profile to each level and verifying the correct set of session-length options are displayed and selectable on the workout generation screen. Delivers complete tier-gating behaviour without requiring XP or exercise-scaling work.

**Acceptance Scenarios**:

1. **Given** a user with Beginner level, **When** they open the session duration picker, **Then** only the "10-12 min" option is visible and selectable; the 15-20 and 20-30 options are absent or visually locked with an explanatory label.
2. **Given** a user with Intermediate level, **When** they open the session duration picker, **Then** "10-12 min" and "15-20 min" are both visible and selectable; the 20-30 option is absent or locked.
3. **Given** a user with Advanced level, **When** they open the session duration picker, **Then** all three options (10-12, 15-20, 20-30 min) are visible and selectable.
4. **Given** a user selects a session duration, **When** they navigate away and return, **Then** their last-selected duration is pre-selected (persisted preference).
5. **Given** a Beginner user views a locked tier, **When** they see it, **Then** a brief label indicates what level is required to unlock it (e.g., "Unlocks at Intermediate").

---

### User Story 2 — Level Progression via XP (Priority: P2)

A user earns XP each day they complete a routine. Over roughly 30 days of consistent activity they reach Intermediate level; over roughly 90 days total (60 more days) they reach Advanced level. Streaks award bonus XP to reward consistency. Level-up events are surfaced to the user with a clear congratulatory message that explains which new session tier has been unlocked.

**Why this priority**: The progression system is what makes tier gating feel earned and motivating rather than arbitrary. Without it, tiers could only be set manually. However, it does not block the tier UI — tier selection (US1) is independently deliverable first.

**Independent Test**: Can be fully tested by simulating XP accumulation at known rates (completing routines daily, hitting streak milestones) and verifying that level thresholds are crossed at the expected cadence, and that a level-up notification fires with the correct unlock message.

**Acceptance Scenarios**:

1. **Given** a user completes their daily routine, **When** the routine ends, **Then** their XP increases by the daily base amount.
2. **Given** a user maintains a streak of 7 consecutive days, **When** they complete the 7th day, **Then** they receive a streak bonus in addition to the base daily XP.
3. **Given** a user reaches the Intermediate XP threshold (approx. 30 days of consistent daily activity), **When** the threshold is crossed, **Then** their level advances to Intermediate and an in-app message congratulates them and announces that the 15-20 min session tier has unlocked.
4. **Given** a user at Intermediate level continues daily activity for approximately 60 more days, **When** the Advanced threshold is crossed, **Then** their level advances to Advanced and an in-app message announces that the 20-30 min session tier has unlocked.
5. **Given** a user breaks their streak and then resumes, **When** they complete a routine after the break, **Then** their streak resets to 1 but XP accumulation and level progress are not lost.
6. **Given** a user who has already reached Intermediate or Advanced, **When** the app is launched, **Then** their session tier options correctly reflect their current level (persistent across app restarts).

---

### User Story 3 — Extended Exercise Content for Longer Sessions (Priority: P3)

When a user selects a 15-20 min or 20-30 min session, the generated workout contains exercises whose individual durations are proportionally longer than in the 10-12 min session, delivering a genuinely more challenging and varied workout rather than repeating the same short exercises more times.

**Why this priority**: This is the content quality layer. Without it, longer sessions still work (via US1 + US2) — the app can fill time by adding more exercises at existing durations — but the per-exercise depth is shallow. This is a polish concern rather than a functional blocker.

**Independent Test**: Can be tested by generating a 20-30 min session and inspecting the selected exercises: exercises should have longer individual durations than their 10-12 min counterparts, or the session includes more exercises drawn from the full library without repeating the same exercise twice.

**Acceptance Scenarios**:

1. **Given** an Intermediate or Advanced user selects a 15-20 min session, **When** the session is generated, **Then** the total selected exercise duration falls within the 15-20 min window.
2. **Given** an Advanced user selects a 20-30 min session, **When** the session is generated, **Then** the total selected exercise duration falls within the 20-30 min window.
3. **Given** a longer session is generated, **When** the user views the exercise list, **Then** no single exercise repeats within that session.
4. **Given** exercises have extended duration variants, **When** the session generator selects exercises for a longer tier, **Then** it picks the appropriately scaled duration for each exercise rather than the shortest available.

---

### Edge Cases

- What happens when a user's XP data is missing or corrupted? Default to level 1 / Beginner with 0 XP — no crash, no data loss.
- What happens if the user edits their profile (e.g., changes gender)? Level and XP are unaffected by profile edits.
- What if the exercise library does not have enough exercises to fill a 20-30 min session without repetition? Fall back to allowing repetition of the least-recently-used exercise rather than showing an error.
- What if a persisted session-duration preference exceeds the user's current level (e.g., after a hypothetical future level-reset)? Clamp to the highest tier available at their current level silently.
- What if a user completes multiple routines on the same day? Only the first completion awards XP and streak credit — subsequent completions in the same calendar day are ignored.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST present a session duration selector with options limited to the tiers the user's current level permits (Beginner: 10-12 min only; Intermediate: 10-12 and 15-20; Advanced: all three).
- **FR-002**: Locked tier options MUST be visually distinguishable from available ones and MUST display the level required to unlock them.
- **FR-003**: The user's last-selected session duration MUST be persisted and restored as the default on subsequent sessions.
- **FR-004**: The workout generator MUST produce a session whose total exercise time falls within the selected tier window (±2 minutes tolerance).
- **FR-005**: The XP system MUST award daily base XP exactly once per calendar day, regardless of how many routines are completed on that day (existing behaviour preserved).
- **FR-006**: The XP system MUST award streak bonus XP at streak milestones of 7, 30, and 100 consecutive days (existing behaviour preserved).
- **FR-007**: Level thresholds MUST be calibrated so that a user completing one routine per day with no streak bonuses reaches Intermediate in approximately 30 days and Advanced in approximately 90 days total.
- **FR-008**: When a user levels up from Beginner→Intermediate or Intermediate→Advanced, the app MUST display a congratulatory message that names the newly unlocked session tier.
- **FR-009**: Level and XP MUST persist across app restarts and MUST NOT reset when the user edits their profile.
- **FR-010**: The session generator MUST support exercises with appropriately scaled durations when building longer-tier sessions.

### Key Entities

- **UserProfile**: Existing entity — `level` integer maps to a named tier (Beginner / Intermediate / Advanced); gains a `preferredSessionDuration` preference field.
- **SessionTier**: A value type representing a duration window (min/max minutes) and the minimum level required to access it. Three tiers: Basic (10-12 min, level 1), Intermediate (15-20 min, level 2), Advanced (20-30 min, level 3).
- **Exercise**: Existing entity — gains support for scaled durations per tier (either via a dictionary mapping or separate fields) so longer sessions can use longer per-exercise durations.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of generated sessions fall within ±2 minutes of the user's selected tier window.
- **SC-002**: A simulated new user completing one routine per day with no streak bonuses reaches Intermediate in 28–35 days and Advanced in 85–95 days total.
- **SC-003**: All available session tiers are discoverable without tutorial — a first-time Intermediate user can locate and select the 15-20 min option within 10 seconds of opening the workout screen.
- **SC-004**: Zero crashes or data-loss events occur when a level-up event fires during routine completion.
- **SC-005**: Locked tier options are clearly distinguished from available options — 100% of test users in a brief usability pass correctly identify which tiers are locked vs. available without assistance.

## Assumptions

- The current daily base XP (20 XP/day) and streak bonus (+50 at 7/30/100 days) are preserved; only the level-threshold values are recalibrated to hit the 30/90-day targets.
- Named tiers (Beginner / Intermediate / Advanced) map to integer level ranges derived from the existing `level` field on `UserProfile`; exact threshold integers are determined during planning.
- Session generation currently picks exercises from a category pool; extending it to respect a duration budget is achievable without a full rewrite of the generation logic.
- There is no server-side state — all XP, level, and session preference data lives on-device.
- Exercise duration scaling for longer tiers will use a per-tier duration dictionary or a multiplier applied at session generation time; the exact approach is determined in planning.
- The 10-12 min default session behaviour is fully preserved for Beginner users — no behaviour changes for existing users who have not yet levelled up.
