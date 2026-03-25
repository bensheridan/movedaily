# Quickstart: Session Duration Tiers

**Branch**: `005-session-tiers` | **Date**: 2026-03-24

---

## How the System Works (After Implementation)

1. `ExperienceTier` is a computed property on `UserProfile` derived from `level`.
2. `DashboardView` reads the user's `experienceTier` and renders a `SessionTierPicker` showing only available tiers.
3. The user's `preferredSessionTier` is stored in `UserDefaults` via `@AppStorage`.
4. When the user taps "Start Routine", `DashboardView` calls `Routine.buildSession(tier:exercises:profile:)` to generate an ordered exercise list, then navigates to `RoutineDetailView`.
5. When `routineCompleted` fires, `DashboardView` calls `profile?.completeRoutine()`, checks if the return value is non-nil (tier change), and if so sets `levelUpTier` to trigger the `LevelUpView` sheet.

---

## Integration Scenarios

### Scenario 1 — Beginner User Sees Only 10-12 Min Option

**Setup**: Fresh install, `level = 1` (Beginner tier)

**Steps**:
1. Open app → `DashboardView`
2. Observe `SessionTierPicker`

**Expected**:
- "10-12 min" option is selected (default) and enabled
- "15-20 min" shows label "Unlocks at Intermediate" and is not selectable
- "20-30 min" shows label "Unlocks at Advanced" and is not selectable
- Tapping a locked option does nothing (or shows tooltip)

---

### Scenario 2 — Intermediate User Unlocks 15-20 Min

**Setup**: User has `level = 7` (crosses Intermediate threshold)

**Steps**:
1. Open app
2. Observe `SessionTierPicker`

**Expected**:
- "10-12 min" and "15-20 min" are both enabled
- "20-30 min" still locked
- User selects "15-20 min"
- Starts routine → exercises fill 900–1200 seconds of content

---

### Scenario 3 — Session Generation Fills the Budget

**Setup**: Intermediate user, "15-20 min" selected, 61 exercises in pool

**Steps**:
1. Select "15-20 min" tier
2. Tap "Start Routine"

**Expected**:
- `Routine.buildSession` returns 8–12 exercises
- Sum of `durationSeconds` across selected exercises: 900–1200 seconds (15-20 min)
- No exercise name appears twice in the list

---

### Scenario 4 — Level-Up Celebration on Tier Change

**Setup**: User is at `level = 6` (Beginner) and earns enough XP to cross level 7 (Intermediate)

**Steps**:
1. Complete a routine
2. `completeRoutine()` returns `.intermediate` (level crossed from 6 → 7)

**Expected**:
- `LevelUpView` sheet appears
- Sheet displays: "You've reached Intermediate!" and "15-20 min sessions are now unlocked."
- Dismissing the sheet returns to `DashboardView`
- `SessionTierPicker` now shows "15-20 min" as available

---

### Scenario 5 — Tier Preference Persists Across Restarts

**Setup**: Advanced user has previously selected "20-30 min"

**Steps**:
1. Force-quit the app
2. Relaunch

**Expected**:
- `SessionTierPicker` defaults to "20-30 min" (restored from `@AppStorage`)
- No selection prompt shown

---

### Scenario 6 — Preference Clamped to Available Tier

**Setup**: Hypothetical scenario where stored preference exceeds current tier (e.g., debug build or future feature)

**Steps**:
1. `@AppStorage` contains `"20-30 min"`
2. User's `level = 3` (Beginner)

**Expected**:
- Displayed selection silently falls back to "10-12 min"
- No crash, no error shown to user
- `@AppStorage` value is updated to reflect the clamped selection on next interaction

---

## Verification Checklist

| Criterion | How to Verify |
|-----------|---------------|
| SC-001: Sessions within ±2 min of selected tier | Sum `durationSeconds` of generated exercise list; verify 600–720s for Basic, 900–1200s for Intermediate, 1200–1800s for Advanced |
| SC-002: 30/90-day progression | In a test build, simulate `completeRoutine()` calls and verify level 7 is reached after 30 calls (no streak bonus) and level 20 after 90 calls |
| SC-003: Tier picker discoverable in < 10s | Open workout screen as Intermediate user; confirm tier options are immediately visible without scrolling or tapping |
| SC-004: No crash on level-up | Tap "Finish" on a routine when level is about to cross a tier boundary; verify `LevelUpView` appears cleanly |
| SC-005: Locked tiers visually distinct | Compare the visual treatment of locked vs. available tiers at Beginner level; confirm 100% recognition without tutorial text |
