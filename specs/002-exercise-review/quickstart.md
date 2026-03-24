# Quickstart: Exercise Library Review & Reorganization

**Feature**: 002-exercise-review | **Date**: 2026-03-24

## Prerequisites

- Xcode 26.2 open with `daily.xcodeproj`
- iOS 17+ simulator or device

## Verification Steps

### Fix 1: Category Reorganization (US1 — P1)

**What changed**: Kegels category replaced by Balance on dashboard; kegel exercises moved to Stretching.

1. **Delete the app from the simulator** (to test fresh install seed data)
2. Build and run (`⌘R`)
3. **Dashboard check**: Confirm exactly 4 category tiles: Stretching, Breathing, Bodyweight, Balance
4. **Tap Stretching**: Scroll through the list — confirm "Muscle Discovery", "Standard Kegels", "Power Pulses", and "Elevator Kegels" appear alongside the original stretching exercises
5. **Tap Balance**: Confirm 6 exercises appear: Single-Leg Stand, Heel-to-Toe Walk, Tree Pose, Standing Knee Lifts, Weight Shifts, Clock Reach
6. **Verify no "Kegels" text**: Search the entire UI for any reference to "Kegels" as a category — it should not appear

**Expected**: 4 category tiles in 2×2 grid. Kegel exercises in Stretching. Balance exercises in Balance. No Kegels category visible.

### Fix 2: New Stretching Exercises (US2 — P2)

1. **Tap Stretching** on the dashboard
2. Scroll to find: "Wrist & Forearm Stretch", "Pigeon Pose", "Seated Spinal Twist"
3. **Tap each**: Verify description, instructions, tips, and difficulty badge are present
4. **Start timer** on "Wrist & Forearm Stretch": Confirm audio cues fire at appropriate times
5. **Let timer reach zero**: Confirm completion cue fires exactly once

**Expected**: 3 new exercises present, fully populated, timer and audio cues work.

### Fix 3: New Balance Exercises with Safety Instructions (US3 — P3)

1. **Tap Balance** on the dashboard
2. Verify 6 exercises are listed
3. **Tap "Single-Leg Stand"**:
   - Instructions should start with "Stand near a chair or wall for support"
   - Tips should include "Keep a chair within arm's reach for safety"
   - Start timer → first audio cue should mention the chair
4. **Tap "Weight Shifts"**: Verify instructions mention keeping a chair nearby
5. **Tap "Clock Reach"**: Verify it shows as Intermediate difficulty (orange badge)
6. **Start timer** on any balance exercise: Verify safety-focused audio cue fires at 0 seconds

**Expected**: All balance exercises have chair/support safety instructions in instructions, tips, and the first audio cue. 5 of 6 are Beginner difficulty.

### Fix 4: New Breathing Exercises (US4 — P4)

1. **Tap Breathing** on the dashboard
2. Find "Lion's Breath" and "Humming Bee Breath"
3. **Tap each**: Verify description, instructions, tips present
4. **Start timer** on "Lion's Breath": Verify audio cues include the "ha" exhale instruction

**Expected**: 2 new breathing exercises present, fully populated.

### Fix 5: New Bodyweight Exercises (US5 — P5)

1. **Tap Bodyweight** on the dashboard
2. Find "Superman Hold", "Dead Bug", "Bird Dog"
3. **Tap each**: Verify description, instructions, tips, difficulty badge
4. **Start timer** on "Dead Bug": Verify audio cues guide through the alternating movement

**Expected**: 3 new bodyweight exercises present, fully populated.

### Fix 6: Existing User Migration (Edge Case)

**Setup**: This test requires a previous version of the app to be installed first.

1. **Install the previous version** (from the `001-app-review-audit` branch)
2. Open the app, complete onboarding, browse some exercises (to seed the database)
3. **Build and install the new version** (from `002-exercise-review` branch) over the top — do NOT delete the app first
4. **Open the app**:
   - Dashboard should show 4 categories: Stretching, Breathing, Bodyweight, Balance
   - Tap Stretching → kegel exercises should now appear here (re-categorized)
   - Tap Balance → 6 new balance exercises should appear
   - All previously existing exercises should still be present with their data intact

**Expected**: Seamless migration. No data loss. Kegel exercises moved to Stretching. New exercises inserted.

### Fix 7: Routine Compatibility

1. Open the app (fresh or migrated)
2. **Check daily routine card**: Tap it and verify the routine loads with its exercises
3. **Specifically check "Relax & De-Stress"**: This routine references "Standard Kegels" — verify the exercise still appears in the routine detail view even though its category changed

**Expected**: All 4 routines work correctly. Exercise lookup by name is unaffected by category changes.

## Exercise Count Verification

| Category   | Expected Count |
|-----------|---------------|
| Stretching | 22 (14 original + 5 from kegels + 3 new) |
| Breathing  | 10 (8 original + 2 new) |
| Bodyweight | 23 (20 original + 3 new) |
| Balance    | 6 (all new) |
| **Total**  | **61** |

Note: Gender-focused exercises are filtered by user profile. If gender is set to Male, female-focused exercises won't appear in the list. Set gender to "Unspecified" to see all universal exercises, or check both Male and Female views to see gender-specific ones.
