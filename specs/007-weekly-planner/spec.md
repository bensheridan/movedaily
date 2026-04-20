# Feature Specification: Weekly Workout Planner

**Feature Branch**: `007-weekly-planner`
**Created**: 2026-04-19
**Status**: Draft
**Input**: User description: "Weekly workout planner. Users can plan their week of workouts outside the auto-generated daily structure. When a user imports a multi-day program, the app maps days to the week and lets the user select the schedule. Today's Session follows the active plan. Users can also manually build a weekly plan day by day."

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Import a Program and Map to the Week (Priority: P1)

A user pastes a multi-day workout program (e.g. a 5-day physio plan with "Day 1 – Upper", "Day 2 – Lower") into the app. The app parses the day structure and presents a scheduling screen where the user assigns each workout day to one or more days of the week (e.g. Day 1 → Monday & Thursday, Day 2 → Tuesday & Friday). The user names the plan, saves it, and it becomes the active plan. From that point, "Today's Session" on the Dashboard reflects whichever workout day is scheduled for the current day of the week.

**Why this priority**: This is the primary use case — import a real-world program and have the app follow it automatically. Delivers immediate value to users with existing workout plans.

**Independent Test**: Paste a 5-day program → assign Day 1 to Monday, Day 2 to Tuesday, Day 3 to Wednesday, Day 4 to Thursday, Day 5 to Friday → save → on a Monday, Dashboard shows Day 1 exercises.

**Acceptance Scenarios**:

1. **Given** a user pastes multi-day program text, **When** they tap "Extract & Schedule", **Then** the app shows each detected day (e.g. "Day 1 – Upper Body") as a card ready for weekday assignment.
2. **Given** extracted workout days are shown, **When** the user assigns Day 1 to Monday and Thursday, **Then** both assignments are accepted.
3. **Given** a plan is saved and today is Monday, **When** the user opens the Dashboard, **Then** "Today's Session" shows the Monday workout — not the auto-generated session.
4. **Given** a plan is active and today has no assigned workout, **When** the user opens the Dashboard, **Then** a rest day card is shown with the option to do an auto-generated session instead.
5. **Given** an active plan exists, **When** the user deactivates it, **Then** the Dashboard immediately reverts to the auto-generated session.

---

### User Story 2 — Manually Build a Weekly Plan (Priority: P2)

A user builds a weekly plan from scratch without importing text. They open the Weekly Planner, add days one at a time using the Custom Workout Builder (selecting categories, saved exercises, or custom exercises), name each day, assign it to weekdays, and save the plan.

**Why this priority**: Not all users have a text program to import. Manual building enables the feature for all users.

**Independent Test**: Create a new plan → add "Monday – Strength" using Bodyweight + Stretching categories → add "Wednesday – Core" → save → on Monday, Dashboard shows the strength workout.

**Acceptance Scenarios**:

1. **Given** the Weekly Planner is open, **When** the user taps "Add a day", **Then** they can name the day and select exercises using the existing Custom Workout Builder interface.
2. **Given** a manually built plan day is configured, **When** the user assigns it to multiple weekdays (e.g. Tuesday and Friday), **Then** both assignments are saved and shown in the weekly view.
3. **Given** a complete manual plan is saved, **When** the user opens the Dashboard on an assigned day, **Then** "Today's Session" shows the correct planned workout.

---

### User Story 3 — Manage and Switch Plans (Priority: P3)

A user can view all saved plans, switch which plan is active, edit an existing plan's day assignments, and delete plans they no longer need.

**Why this priority**: Without management, users are stuck with their first plan. Essential for long-term usefulness but not blocking for MVP.

**Independent Test**: Create two plans → activate Plan B → Dashboard shows Plan B's workout → delete Plan A → Plan A no longer appears.

**Acceptance Scenarios**:

1. **Given** multiple plans exist, **When** the user taps "Activate" on a plan, **Then** it becomes active and the previously active plan is deactivated.
2. **Given** an active plan exists, **When** the user edits a day assignment, **Then** the change takes effect immediately on the Dashboard.
3. **Given** a plan exists, **When** the user deletes it, **Then** it is removed; if it was active, the Dashboard reverts to auto-generated sessions.

---

### Edge Cases

- What happens when a day has no assigned workout in the active plan? → Show a rest day card with an option to do an auto-generated session.
- What happens when the user imports a program with no "Day N" structure? → All exercises are treated as a single day that the user can assign to any weekday.
- What happens if a plan day has exercises that conflict with active injury settings? → Exercises are displayed as imported; injury filtering only applies to auto-generated sessions.
- What happens when the user has no active plan? → Dashboard behaves exactly as today (auto-generated session).
- What happens when a second program is imported while a plan is already active? → A new separate plan is created; the user chooses whether to activate it.
- What happens if the user assigns the same weekday to two different plan days? → Last assignment wins; the UI prevents accidental overwriting with a confirmation prompt.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Users MUST be able to paste multi-day workout text and have the app extract individual workout days with their exercises.
- **FR-002**: Users MUST be able to assign each extracted or manually-built workout day to one or more days of the week (Monday–Sunday).
- **FR-003**: Users MUST be able to name a collection of day assignments and save it as a named workout plan.
- **FR-004**: Only one plan may be active at a time; activating a new plan automatically deactivates the current one.
- **FR-005**: When a plan is active and the current weekday has an assigned workout, "Today's Session" MUST display that planned workout instead of the auto-generated one.
- **FR-006**: When a plan is active but the current weekday has no assigned workout, the Dashboard MUST show a rest day message with an option to fall back to an auto-generated session.
- **FR-007**: When no plan is active, the Dashboard MUST behave identically to the current auto-generated session flow.
- **FR-008**: Users MUST be able to view all saved plans, activate any plan, edit day assignments, and delete any plan.
- **FR-009**: Users MUST be able to build a weekly plan day by day without importing text, using the same exercise-selection tools available in the Custom Workout Builder.
- **FR-010**: The weekday-to-workout mapping MUST be editable after the plan is created.

### Key Entities

- **WorkoutPlan**: A named collection of day assignments. Has an active/inactive state. Only one plan is active at a time.
- **PlanDay**: A named workout day within a plan (e.g. "Day 1 – Upper Body"). Contains an ordered list of exercises.
- **WeekdayAssignment**: Maps a PlanDay to one or more days of the week. Each weekday may have at most one PlanDay assigned within a plan.
- **PlanExercise**: An exercise entry within a PlanDay — name, quantity (sets or seconds), and unit. Stored as a snapshot; not linked to the live exercise library.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can go from pasting a multi-day program to having a scheduled weekly plan active in under 3 minutes.
- **SC-002**: On days with an active plan, "Today's Session" reflects the planned workout within 1 second of opening the Dashboard.
- **SC-003**: Users can build a complete 5-day manual plan in under 5 minutes.
- **SC-004**: Switching active plans requires a single tap and is reflected on the Dashboard immediately.
- **SC-005**: 100% of days with an active plan assignment show the planned workout — the auto-generated session never appears on a planned day.

## Assumptions

- A weekday may be assigned to at most one PlanDay within a given plan. The same weekday cannot have two conflicting workouts in one plan.
- Rest days (unassigned weekdays) always offer the auto-generated session as a fallback — never a blank screen.
- Plan exercises are stored as a snapshot at import/build time and do not update if the exercise library changes later.
- "Today's Session" uses the device's local calendar day, not a server clock.
- Plans are stored locally on-device, consistent with the app's offline-first design.
