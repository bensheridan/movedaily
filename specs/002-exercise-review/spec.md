# Feature Specification: Exercise Library Review & Reorganization

**Feature Branch**: `002-exercise-review`
**Created**: 2026-03-24
**Status**: Draft
**Input**: User description: "Review the exercises, move kegels into the stretching section, and complete review of the exercise library. Add more exercises if they are sensible and fit the intention of the app."

## Clarifications

### Session 2026-03-24

- Q: Should the app have 3 or 4 exercise categories? → A: 4 categories — add Balance. Balance is very important for elderly users and is a genuinely distinct pillar of daily wellness.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Reorganized Category Navigation (Priority: P1) 🎯 MVP

A user opens the app and sees four exercise category cards on the dashboard: Stretching, Breathing, Bodyweight, and Balance. The former Kegels category has been replaced by Balance — a new category focused on stability, proprioception, and fall prevention. Pelvic-floor exercises have been absorbed into Stretching. The dashboard grid remains a clean 2×2 layout.

**Why this priority**: The category grid is the first thing users interact with after the daily routine card. Replacing Kegels with Balance improves the information architecture — Balance is a distinct wellness pillar that serves users of all ages, especially older adults. This is the core structural change everything else builds on.

**Independent Test**: Open the app dashboard. Confirm exactly four category cards appear (Stretching, Breathing, Bodyweight, Balance). Tap Stretching and verify that pelvic-floor exercises (Muscle Discovery, Standard Kegels, Power Pulses, Elevator Kegels) appear within the Stretching list. Tap Balance and verify dedicated balance exercises appear.

**Acceptance Scenarios**:

1. **Given** a fresh install of the app, **When** the user views the dashboard, **Then** exactly four exercise category cards are displayed: Stretching, Breathing, Bodyweight, Balance
2. **Given** the user taps the Stretching category, **When** the exercise list loads, **Then** all former kegel exercises appear alongside existing stretching exercises
3. **Given** the user taps the Balance category, **When** the exercise list loads, **Then** dedicated balance exercises appear
4. **Given** the user has a previously seeded database with the old Kegels category, **When** the app is updated and relaunched, **Then** kegel exercises are reassigned to the Stretching category and Balance exercises are added

---

### User Story 2 — Expanded Stretching Library (Priority: P2)

A user browses the Stretching category and finds a broader range of exercises that now includes pelvic-floor work plus new flexibility and mobility exercises. The additions feel intentional and consistent with the app's daily wellness focus — each new exercise is doable at home, requires no equipment, and fits within the existing timer-based format.

**Why this priority**: With kegel exercises merging into stretching, it is a natural time to review and fill gaps in the stretching library. Adding complementary exercises increases variety and makes the category feel complete.

**Independent Test**: Open the Stretching category. Confirm new exercises appear (e.g., Wrist & Forearm Stretch, Pigeon Pose, Seated Spinal Twist). Tap each new exercise and verify it has a description, instructions, tips, and audio cues. Start the timer and confirm it counts down correctly.

**Acceptance Scenarios**:

1. **Given** the user opens the Stretching category, **When** the exercise list loads, **Then** new stretching exercises are present alongside existing ones
2. **Given** the user selects any new stretching exercise, **When** they view the detail screen, **Then** the exercise has a complete description, step-by-step instructions, tips, and timed audio cues
3. **Given** the user starts a new stretching exercise timer, **When** the timer reaches zero, **Then** the completion cue fires exactly once (consistent with existing timer behavior)

---

### User Story 3 — New Balance Category (Priority: P3)

A user browses the new Balance category and finds exercises focused on stability, proprioception, and fall prevention. The exercises range from very accessible (Weight Shifts, Standing Knee Lifts) to moderately challenging (Clock Reach), making the category welcoming for older adults while still offering progression for all users.

**Why this priority**: Balance is a distinct wellness pillar that was missing from the app. It is especially valuable for elderly users and anyone focused on injury prevention. The exercises are simple, require no equipment, and are uniquely suited to the app's daily wellness mission.

**Independent Test**: Open the Balance category. Confirm balance exercises appear. Tap each and verify complete detail content. Start a timer and verify it works correctly with the existing exercise detail view.

**Acceptance Scenarios**:

1. **Given** the user opens the Balance category, **When** the exercise list loads, **Then** balance-specific exercises are displayed
2. **Given** the user selects any balance exercise, **When** they view the detail screen, **Then** the exercise has a description, difficulty level, instructions, tips, and audio cues
3. **Given** the user is elderly or a beginner, **When** they browse Balance exercises, **Then** the majority of exercises are beginner-friendly and accessible

---

### User Story 4 — Expanded Breathing Library (Priority: P4)

A user browses the Breathing category and finds additional breathing techniques that complement the existing set. The breathing category currently has the fewest exercises (8), and adding well-known techniques increases variety for users who rely on this category for stress relief and mindfulness.

**Why this priority**: Breathing currently has the smallest exercise count. Adding a few well-known techniques rounds out the library without bloating it.

**Independent Test**: Open the Breathing category. Confirm new breathing exercises appear. Tap each and verify complete detail content. Run the timer through to completion.

**Acceptance Scenarios**:

1. **Given** the user opens the Breathing category, **When** the exercise list loads, **Then** new breathing exercises are present alongside existing ones
2. **Given** the user selects any new breathing exercise, **When** they view the detail screen, **Then** the exercise has a description, instructions, tips, and timed audio cues appropriate to the breathing pattern

---

### User Story 5 — Expanded Bodyweight Library (Priority: P5)

A user browses the Bodyweight category and finds additional core stability and postural exercises that fill gaps in the current library. These additions target commonly overlooked areas (back extension, deep core stability) that are important for daily wellness.

**Why this priority**: The bodyweight category is already the largest (20 exercises), so fewer additions are needed. The new exercises specifically address gaps in back and core work.

**Independent Test**: Open the Bodyweight category. Confirm new exercises appear. Tap each and verify complete detail content.

**Acceptance Scenarios**:

1. **Given** the user opens the Bodyweight category, **When** the exercise list loads, **Then** new bodyweight exercises are present alongside existing ones
2. **Given** the user selects any new bodyweight exercise, **When** they view the detail screen, **Then** the exercise has a description, difficulty level, instructions, tips, and audio cues

---

### Edge Cases

- What happens when a user upgrades from the previous version that had Kegels as a category? The seed data only runs on first launch (when exercise count is 0), so existing users will retain the old category assignments. A data migration must re-categorize existing kegel exercises to Stretching and insert the new Balance exercises.
- What happens if both "Standard Kegels" entries (male and female) exist in the same category? They should remain as separate exercises with gender focus filtering. The display should differentiate them through the existing gender-focus personalization system.
- What happens to the "Relax & De-Stress" routine that references "Standard Kegels" by name? It continues to work because routine-to-exercise lookup is by exercise name, not category. No routine changes required.
- What happens to the category grid layout? The grid remains a 2×2 layout with 4 categories (same tile count as the current version), so no layout changes are needed.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST display exactly four exercise categories on the dashboard: Stretching, Breathing, Bodyweight, and Balance
- **FR-002**: All exercises previously categorized as Kegels MUST appear within the Stretching category
- **FR-003**: The Kegels category MUST be replaced by Balance and no longer appear anywhere in the app
- **FR-004**: Existing users who upgrade MUST have their kegel exercises automatically re-categorized to Stretching and receive the new Balance exercises on next app launch
- **FR-005**: The app MUST include the following new stretching exercises: Wrist & Forearm Stretch, Pigeon Pose, Seated Spinal Twist
- **FR-006**: The app MUST include the following new breathing exercises: Lion's Breath, Humming Bee Breath
- **FR-007**: The app MUST include the following new bodyweight exercises: Superman Hold, Dead Bug, Bird Dog
- **FR-008**: The app MUST include a new Balance category with the following exercises: Single-Leg Stand, Heel-to-Toe Walk, Tree Pose, Standing Knee Lifts, Weight Shifts, Clock Reach
- **FR-009**: Every new exercise MUST have a complete definition including: name, description, duration, category, difficulty level, step-by-step instructions, tips, and timed audio cues
- **FR-010**: New exercises MUST require no equipment and be suitable for home environments
- **FR-011**: Balance exercises MUST be predominantly beginner-friendly to ensure accessibility for elderly users
- **FR-012**: Gender-focused exercises MUST continue to be filtered based on the user's profile gender selection
- **FR-013**: All existing routines MUST continue to function correctly after the category reorganization
- **FR-014**: The seed data MUST include all new exercises so that fresh installs receive the complete updated library

### Key Entities

- **Exercise Category**: The grouping system for exercises. Currently has four values (Stretching, Breathing, Bodyweight, Kegels). Kegels is replaced by Balance. Stretching absorbs pelvic-floor exercises.
- **Exercise**: An individual exercise with name, description, duration, category, difficulty, optional gender focus, instructions, tips, and audio cues. Five existing exercises change category from Kegels to Stretching. Fourteen new exercises are added across four categories.
- **Routine**: A named collection of exercises referenced by exercise name. No changes required — existing name-based references remain valid.

## Proposed New Exercises

### New Stretching Exercises (3)

| Name                    | Description                                | Duration | Difficulty   | Gender Focus |
| ----------------------- | ------------------------------------------ | -------- | ------------ | ------------ |
| Wrist & Forearm Stretch | Desk-worker relief for wrists and forearms | 60s      | Beginner     | Universal    |
| Pigeon Pose             | Deep hip opener for flexibility            | 60s      | Intermediate | Universal    |
| Seated Spinal Twist     | Rotational mobility for the spine          | 60s      | Beginner     | Universal    |

### New Breathing Exercises (2)

| Name               | Description                         | Duration | Difficulty | Gender Focus |
| ------------------ | ----------------------------------- | -------- | ---------- | ------------ |
| Lion's Breath      | Energizing stress-release technique | 120s     | Beginner   | Universal    |
| Humming Bee Breath | Calming vibration breath (Bhramari) | 180s     | Beginner   | Universal    |

### New Bodyweight Exercises (3)

| Name          | Description                  | Duration | Difficulty | Gender Focus |
| ------------- | ---------------------------- | -------- | ---------- | ------------ |
| Superman Hold | Back extension for posture   | 60s      | Beginner   | Universal    |
| Dead Bug      | Deep core stability exercise | 60s      | Beginner   | Universal    |
| Bird Dog      | Balance and core coordination | 60s     | Beginner   | Universal    |

### New Balance Exercises (6)

| Name                | Description                                  | Duration | Difficulty   | Gender Focus |
| ------------------- | -------------------------------------------- | -------- | ------------ | ------------ |
| Single-Leg Stand    | Fundamental one-leg balance hold             | 60s      | Beginner     | Universal    |
| Heel-to-Toe Walk    | Straight-line tandem walking for stability   | 60s      | Beginner     | Universal    |
| Tree Pose           | Yoga-inspired single-leg balance             | 60s      | Beginner     | Universal    |
| Standing Knee Lifts | Alternating slow knee raises for balance     | 60s      | Beginner     | Universal    |
| Weight Shifts       | Side-to-side weight transfer for stability   | 60s      | Beginner     | Universal    |
| Clock Reach         | Single-leg reach to clock positions          | 60s      | Intermediate | Universal    |

### Exercise Library Summary (After Changes)

| Category     | Current Count | Moved In          | New | Final Count |
| ------------ | ------------- | ----------------- | --- | ----------- |
| Stretching   | 14            | +5 (from Kegels)  | +3  | 22          |
| Breathing    | 8             | —                 | +2  | 10          |
| Bodyweight   | 20            | —                 | +3  | 23          |
| Balance      | 0 (new)       | —                 | +6  | 6           |
| **Total**    | **42 + 5**    |                   |     | **61**      |

## Assumptions

- The app's intention is daily home wellness: short routines, no equipment, beginner-to-advanced, timer-based exercises with voice guidance
- Kegel exercises are a form of pelvic-floor stretching/flexibility work, making Stretching the natural home category
- Balance is a distinct wellness pillar focused on stability, proprioception, and fall prevention — especially valuable for older adults
- New exercises follow the same content format as existing ones (name, description, duration, instructions, tips, audio cues)
- Existing users who have already seeded their database will need a migration to re-categorize kegel exercises and insert new Balance exercises; this will be handled by checking for exercises with the old category on app launch
- The 2-column grid layout on the dashboard remains a 2×2 grid with 4 categories (same tile count as before)
- No changes to the XP, streak, or gamification systems are required
- No changes to existing routines are required since they reference exercises by name

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users see exactly 4 category tiles on the dashboard: Stretching, Breathing, Bodyweight, Balance
- **SC-002**: The Stretching category contains all former kegel exercises plus 3 new exercises (22 total)
- **SC-003**: The Breathing category contains 2 new exercises (10 total)
- **SC-004**: The Bodyweight category contains 3 new exercises (23 total)
- **SC-005**: The Balance category contains 6 new exercises, with 5 of 6 at beginner difficulty
- **SC-006**: All 61 exercises display complete content (description, instructions, tips, audio cues) with no missing fields
- **SC-007**: All 4 existing routines continue to work correctly, matching exercises by name
- **SC-008**: Existing users' kegel exercises are automatically re-categorized on upgrade without data loss
- **SC-009**: All new exercises can be completed using the existing timer interface with no modifications to the exercise detail view
- **SC-010**: The Kegels category no longer appears anywhere in the app
