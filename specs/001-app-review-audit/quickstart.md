# Quickstart: Verifying the Bug Fixes

**Branch**: `001-app-review-audit`
**Date**: 2026-03-24

Manual verification steps for each fix. Run these after implementation to
confirm all five bugs are resolved.

---

## Prerequisites

- Xcode open on the `daily` project
- Simulator or device running iOS 17+
- App installed fresh (or data reset via Profile → Reset Profile)

---

## Fix 1 — Streak and XP track correctly

**What to verify**: The routine completion logic awards XP once per day,
resets streak on missed days, and grants milestone bonuses.

Because calendar-day checks can't be easily simulated in the UI, verify using
Xcode's Swift REPL or by temporarily setting `lastExerciseDate` in the
debugger.

**Manual check — same-day duplicate**:
1. Complete a routine (note XP value)
2. Complete the same routine again immediately
3. XP and streak MUST remain unchanged after the second completion

**Manual check — streak milestone (shortcut)**:
1. In `Models.swift`, temporarily change the milestone check to trigger at
   streak day 2 instead of 7: `[2, 30, 100].contains(streakCount)`
2. Reset profile, complete a routine on day 1 (streak = 1, XP = 20)
3. Advance date by 1 day in the simulator (Settings → General → Date & Time,
   disable Set Automatically, set to next day)
4. Complete a routine (streak = 2, XP should = 20 base + 50 bonus = 70 total)
5. Revert the test change

**Expected after fix**: Streak increments daily, resets on missed days,
milestone bonus fires exactly once per milestone.

---

## Fix 2 — Exercise timer completes exactly once

**What to verify**: Completion haptic and speech fire once; no repeat.

1. Open any exercise (e.g., Neck Tilts — 60 seconds)
2. Tap **Start**
3. Wait for timer to count to 00:00 (or use the Simulator's fast-forward for
   time — or temporarily change `durationSeconds` to 3 in `seedInitialData`)
4. Observe: one haptic pulse and one "Exercise complete. Great job!" spoken
5. Wait 5 more seconds with the screen still visible
6. **Expected**: No additional haptics or speech after the initial completion
7. Tap the reset (↺) button and verify `timerCompleted` resets (timer starts
   from full duration again)

---

## Fix 3 — Button styling in ExerciseDetailView

**What to verify**: Start/Pause and Reset buttons render with correct styles.

1. Open any exercise
2. **Expected**: The Start/Pause button has a filled blue bordered-prominent
   style (blue pill background)
3. **Expected**: The Reset (↺) button has a bordered style (outlined)
4. These were invisible/unstyled before the fix

---

## Fix 4 — Profile screen navigation

**What to verify**: Single navigation bar, read-only stats, no "Close" button.

1. Launch app to Dashboard
2. Tap the person icon (top-right)
3. **Expected**: One navigation bar showing "Profile" title with a back
   chevron (no duplicate bars, no "Close" button)
4. Verify Level and XP are shown as plain text (cannot tap or swipe to edit)
5. Verify the gender picker still works
6. Tap back — return to Dashboard successfully

---

## Fix 4b — Profile photo and reset (new features enabled)

1. On Profile screen, tap the profile photo area → **Expected**: system photo
   picker opens
2. Select any image → **Expected**: photo appears in the circular frame
3. Close and reopen the Profile screen → **Expected**: photo persists
4. Tap **Reset Profile** → confirm → **Expected**: Level = 1, XP = 0,
   Streak = 0; gender and photo are preserved

---

## Fix 5 — Daily reminder scheduling

1. On Profile screen, toggle **Enable Reminder** ON
2. System permission prompt appears → tap **Allow**
3. Set reminder time to 1 minute from now
4. Background the app (or wait in foreground)
5. **Expected**: Notification arrives at the set time with title "Don't forget
   your routine!"
6. Change the time and verify the old notification does not fire (only the
   new time fires)

---

## Build Verification

After all changes, do a clean build:

```
Product → Clean Build Folder (⇧⌘K)
Product → Build (⌘B)
```

**Expected**: Zero errors, zero warnings related to the changed files.
