# Data Model: App Review & Bug Fix Audit

**Branch**: `001-app-review-audit`
**Phase**: 1 — Design
**Date**: 2026-03-24

No changes to the SwiftData schema are required. All bugs are in view or
logic layers, not the data model. This document records the existing model
for reference and notes which fields are relevant to each fix.

---

## Entities (unchanged)

### UserProfile

Persisted via SwiftData `@Model`.

| Field | Type | Notes |
|-------|------|-------|
| `gender` | `Gender` (enum) | Editable via ProfileView; drives content personalization |
| `xp` | `Int` | Read-only in ProfileView; mutated only by `completeRoutine(baseXP:)` |
| `level` | `Int` | Read-only in ProfileView; mutated only by `completeRoutine(baseXP:)` |
| `streakCount` | `Int` | Read-only in ProfileView; mutated only by `completeRoutine(baseXP:)` |
| `lastExerciseDate` | `Date?` | Set by `completeRoutine(baseXP:)` to track per-day award eligibility |
| `profileImageData` | `Data?` | Stored as JPEG bytes; set via `setProfileImage(_:)` |

**Completion logic rules** (authoritative implementation in `Models.swift`):
- XP and streak awarded at most once per calendar day
- Streak increments if last exercise was yesterday; resets to 1 if gap > 1 day
- Milestone bonus XP (+50) at streak days 7, 30, 100
- Level increments by 1 per 100 XP with correct rollover (while loop)

### Exercise

Persisted via SwiftData `@Model`. Seeded once on first launch. **No changes.**

| Field | Type | Notes |
|-------|------|-------|
| `name` | `String` | Used as join key for Routine.exerciseNames |
| `exerciseDescription` | `String` | Subtitle in list |
| `durationSeconds` | `Int` | Initial value for ExerciseDetailView countdown |
| `category` | `ExerciseCategory` | Drives category browsing |
| `difficulty` | `Difficulty` | Shown as badge in ExerciseDetailView |
| `genderFocus` | `Gender?` | Optional filter; nil = universal |
| `instructions` | `[String]` | Shown in detail view |
| `tips` | `[String]` | Shown in tips sheet |
| `audioCues` | `[Int: String]` | Keyed by elapsed seconds; spoken by TTSManager |

### Routine

Persisted via SwiftData `@Model`. Seeded once on first launch. **No changes.**

| Field | Type | Notes |
|-------|------|-------|
| `name` | `String` | Display title |
| `routineDescription` | `String` | Subtitle on dashboard card |
| `exerciseNames` | `[String]` | Ordered list of Exercise.name references |

---

## AppStorage Keys (non-SwiftData)

Used by ProfileView for reminder preferences. **No schema change needed.**

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `reminderEnabled` | `Bool` | `false` | Whether daily reminder notification is scheduled |
| `reminderTime` | `String` | `"08:00"` | Reminder time in `"HH:mm"` 24-hour format |

---

## State Variables Added (view-layer only)

`ExerciseDetailView` will gain one new `@State` property:

| Variable | Type | Initial Value | Purpose |
|----------|------|---------------|---------|
| `timerCompleted` | `Bool` | `false` | Guards completion feedback to fire exactly once; reset when user resets timer |
