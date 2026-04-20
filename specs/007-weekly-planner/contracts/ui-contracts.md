# UI Contracts: Weekly Workout Planner

**Feature**: 007-weekly-planner
**Date**: 2026-04-19

---

## View: WeeklyPlannerView

**Purpose**: List all saved plans; create, activate, and delete plans; navigate into plan editing.

**Entry point**: Toolbar button on DashboardView ("Weekly Plans" / calendar icon).

**Inputs**: `@Query var allPlans: [WorkoutPlan]`

**Outputs / Actions**:
- Navigate to `PlanEditorView` to create a new plan.
- Navigate to `PlanEditorView` to edit an existing plan.
- Activate a plan (sets `plan.isActive = true`, all others → false).
- Delete a plan (with confirmation).

**States**:
- **Empty**: No plans saved → prompt to create first plan.
- **List**: One or more plans shown as cards. Active plan marked with a badge.
- **Active indicator**: Active plan card has a distinct visual treatment (e.g., blue border / "Active" chip).

**#Preview required**: Yes.

---

## View: PlanEditorView

**Purpose**: Create or edit a `WorkoutPlan` — name it, manage its `PlanDay` list, import text.

**Entry point**: WeeklyPlannerView ("New Plan" / tap existing plan).

**Inputs**: Optional existing `WorkoutPlan` (nil = create mode).

**Outputs / Actions**:
- Edit plan name.
- Add a day via `PlanDayBuilderView` (sheet).
- Edit an existing day via `PlanDayBuilderView` (sheet).
- Delete a day (swipe-to-delete).
- Import text → parse → adds extracted days to the plan's day list.
- Save plan (validates name non-empty, at least one day).
- Activate on save toggle.

**States**:
- **Create mode**: Empty day list, name field focused.
- **Edit mode**: Pre-populated name and days.
- **Import in progress**: Loading indicator while parser runs.
- **Import results**: Parsed days listed; user assigns weekdays before adding.

**#Preview required**: Yes.

---

## View: PlanDayBuilderView

**Purpose**: Configure a single `PlanDay` — name it, assign weekdays, select exercises.

**Entry point**: PlanEditorView ("Add a day" / tap existing day).

**Inputs**: Optional existing `PlanDay` (nil = new day). The parent plan's already-assigned weekdays (to prevent conflicts).

**Outputs / Actions**:
- Edit day name (e.g., "Day 1 – Upper Body").
- Select weekdays using a toggle row for each day Mon–Sun; weekdays already taken by another day in this plan are shown disabled.
- Add exercises: reuses existing `CustomWorkoutBuilderView` exercise-selection components or presents a simplified picker (category grid + custom exercise list).
- Remove exercises (swipe-to-delete or edit mode).
- Save (validates name non-empty, at least one weekday assigned).

**States**:
- **No weekday selected**: Save disabled; inline hint shown.
- **No exercises**: Save allowed (rest day is valid; user is warned).
- **Weekday conflict**: Conflicted weekday shown disabled with a tooltip.

**#Preview required**: Yes.

---

## View: DashboardView modifications

**Additions** (to `daily/ContentView.swift`):

1. **Weekly Plans toolbar button**: Calendar icon in navigation bar trailing. Presents `WeeklyPlannerView` as a sheet.

2. **Today's Plan Card** (replaces `DailyRoutineCard` when a plan day is active):
   - Shows plan name + today's day name (e.g., "Upper Body – Day 1").
   - "Start Session" button navigates to `RoutineDetailView` with plan exercises.
   - "Not today" link falls back to auto-generated session.

3. **Rest Day Banner** (shown when plan is active but today is unassigned):
   - "Rest day — no workout scheduled." message.
   - "Do an auto session instead" button restores auto-generated card for this session only (does not deactivate the plan).

4. **Active plan indicator** on DailyRoutineCard area when no plan conflict.

**No new view file needed** — all additions go inside `DashboardView` in `ContentView.swift`.

---

## View: ImportScheduleView (inline in PlanEditorView)

**Purpose**: After parsing imported text, show each extracted day and let the user assign weekdays before adding to the plan.

**Implementation note**: This is an inline section inside `PlanEditorView`, not a separate file.

**States**:
- **Parsed days listed**: Each day shown as a card with its exercises and a weekday picker row.
- **Conflict warning**: If a chosen weekday is already taken by another day in the plan.
- **"Add all to plan" button**: Bulk-adds all parsed days once each has a valid weekday (or user explicitly skips weekday assignment for some days).
