# Data Model: Exercise Library Review & Reorganization

**Feature**: 002-exercise-review | **Date**: 2026-03-24

## Entity Changes

### ExerciseCategory (Enum — modified)

The `ExerciseCategory` enum gains one new case (`.balance`) and retains `.kegels` for backward compatibility. A new static property provides the dashboard-visible categories.

**Before** (4 cases, all displayed):
```
stretching ("Stretching") → icon: "figure.flexibility"
breathing  ("Breathing")  → icon: "wind"
bodyweight ("Bodyweight")  → icon: "figure.strengthtraining.traditional"
kegels     ("Kegels")      → icon: "figure.highintensity.intervaltraining"
```

**After** (5 cases, 4 displayed):
```
stretching ("Stretching") → icon: "figure.flexibility"         [displayed]
breathing  ("Breathing")  → icon: "wind"                       [displayed]
bodyweight ("Bodyweight")  → icon: "figure.strengthtraining.traditional" [displayed]
kegels     ("Kegels")      → icon: "figure.highintensity.intervaltraining" [HIDDEN — kept for decode safety]
balance    ("Balance")     → icon: "figure.stand"              [displayed — NEW]
```

**New static property**: `displayCategories` returns `[.stretching, .breathing, .bodyweight, .balance]` — the 4 categories shown on the dashboard.

### Exercise (@Model — unchanged schema, new seed data)

The `Exercise` entity schema is **not modified**. All existing fields remain:
- `name: String`
- `exerciseDescription: String`
- `durationSeconds: Int`
- `category: ExerciseCategory`
- `difficulty: Difficulty`
- `genderFocus: Gender?`
- `instructions: [String]`
- `tips: [String]`
- `audioCues: [Int: String]`

**Data changes only**:
- 5 existing kegel exercises: `category` migrated from `.kegels` → `.stretching`
- 14 new exercises inserted (3 stretching, 2 breathing, 3 bodyweight, 6 balance)

### Routine (@Model — no changes)

No changes. Routines reference exercises by name (`exerciseNames: [String]`). The "Relax & De-Stress" routine references "Standard Kegels" — this still resolves correctly since exercise name is unchanged.

## Migration Strategy

### When Does Migration Run?

Migration runs in `Exercise.seedInitialData(context:)` alongside the existing first-launch seed logic. The flow becomes:

1. **First launch (fresh install)**: Exercise count is 0 → seed all exercises (kegel exercises are now seeded with `.stretching` category; balance exercises are included in seed data). No migration needed.
2. **Existing user (upgrade)**: Exercise count > 0 → skip initial seed, but **run migration**:
   - Re-categorize any `.kegels` exercises to `.stretching`
   - Insert new exercises that don't already exist (checked by name)

### Migration Logic

```text
migrateData(context):
  1. Fetch ALL exercises
  2. For each exercise where category == .kegels:
       → Set category = .stretching
  3. Collect existing exercise names into a Set
  4. For each exercise in [newExercises]:
       → If name NOT in existing names: insert into context
```

This is idempotent — running it multiple times has no effect after the first successful run.

### What Are "New Exercises"?

Only exercises that didn't exist in the previous version:

| Category   | New Exercises |
|-----------|--------------|
| Stretching | Wrist & Forearm Stretch, Pigeon Pose, Seated Spinal Twist |
| Breathing  | Lion's Breath, Humming Bee Breath |
| Bodyweight | Superman Hold, Dead Bug, Bird Dog |
| Balance    | Single-Leg Stand, Heel-to-Toe Walk, Tree Pose, Standing Knee Lifts, Weight Shifts, Clock Reach |

## Exercise Content — Full Definitions

### New Stretching Exercises

**Wrist & Forearm Stretch** (Beginner, 60s)
- Description: Desk-worker relief for wrists and forearms.
- Instructions: Extend one arm forward, palm up. Gently pull fingers down with the other hand. Hold for 15 seconds. Flip the hand palm-down and pull fingers toward you. Switch arms.
- Tips: Don't force the stretch — go to gentle tension only. Great for anyone who types or uses a phone frequently. Breathe normally throughout.
- Audio cues: [0] "Extend your right arm. Pull fingers down gently." [15] "Now flip your hand and pull fingers toward you." [30] "Switch to your left arm." [45] "Flip and stretch."

**Pigeon Pose** (Intermediate, 60s)
- Description: Deep hip opener for flexibility.
- Instructions: Start on all fours. Bring your right knee forward behind your right wrist. Extend your left leg straight back. Lower your hips toward the floor. Hold and breathe. Switch sides.
- Tips: Place a cushion under your hip if this feels too intense. Keep your hips level and square. This stretch deepens over time — don't force it.
- Audio cues: [0] "Right knee forward. Settle into the stretch." [30] "Switch to your left side."

**Seated Spinal Twist** (Beginner, 60s)
- Description: Rotational mobility for the spine.
- Instructions: Sit with legs extended. Bend your right knee and cross it over your left leg. Place your left elbow on the outside of your right knee. Twist gently to the right. Hold. Switch sides.
- Tips: Sit tall — don't round your back. Twist from your torso, not just your shoulders. Breathe into the stretch.
- Audio cues: [0] "Cross your right knee over. Twist to the right." [30] "Switch sides. Cross your left knee over."

### New Breathing Exercises

**Lion's Breath** (Beginner, 120s)
- Description: Energizing stress-release technique.
- Instructions: Sit comfortably or kneel. Inhale deeply through your nose. Open your mouth wide, stick out your tongue, and exhale forcefully with a "ha" sound. Relax your face. Repeat.
- Tips: This may feel silly at first — that's normal and part of the stress release. Let the exhale be loud and forceful. Great for releasing jaw and face tension.
- Audio cues: [0] "Inhale deeply through your nose." [5] "Open wide and roar it out. Ha!" [15] "Inhale again." [20] "And release. Ha!" [60] "Keep going. Inhale." [65] "Release!"

**Humming Bee Breath** (Beginner, 180s)
- Description: Calming vibration breath for anxiety relief.
- Instructions: Sit comfortably with eyes closed. Place your index fingers gently on the cartilage of your ears. Inhale deeply. Exhale while making a steady humming sound. Feel the vibration in your head and chest. Repeat.
- Tips: The humming should be smooth and continuous. Experiment with pitch — find what feels most soothing. This technique is excellent before sleep.
- Audio cues: [0] "Close your eyes. Fingers on your ears." [5] "Inhale deeply." [10] "Hum as you exhale." [30] "Inhale again." [35] "Long, steady hum." [90] "Continue at your own pace."]

### New Bodyweight Exercises

**Superman Hold** (Beginner, 60s)
- Description: Back extension for posture.
- Instructions: Lie face down with arms extended overhead. Simultaneously lift your arms, chest, and legs off the floor. Hold for 3 to 5 seconds. Lower slowly. Repeat.
- Tips: Lift gently — you don't need to go high. Keep your neck neutral — look at the floor. Squeeze your glutes as you lift.
- Audio cues: [0] "Lie face down. Arms overhead." [5] "Lift everything off the floor. Hold." [10] "Lower slowly." [15] "And lift again."

**Dead Bug** (Beginner, 60s)
- Description: Deep core stability exercise.
- Instructions: Lie on your back with arms pointing to the ceiling. Lift your legs to a tabletop position, knees at 90 degrees. Slowly extend your right arm overhead and left leg out straight. Return to center. Switch sides.
- Tips: Press your lower back into the floor throughout. Move slowly — this is about control, not speed. If it's too hard, keep your knees bent as you extend.
- Audio cues: [0] "Arms up, knees at 90 degrees." [5] "Right arm back, left leg out." [10] "Return to center." [15] "Left arm back, right leg out."]

**Bird Dog** (Beginner, 60s)
- Description: Balance and core coordination.
- Instructions: Start on all fours with a flat back. Extend your right arm forward and left leg back simultaneously. Hold for 3 seconds. Return to all fours. Switch to left arm and right leg.
- Tips: Keep your hips level — don't let them rotate. Move slowly and deliberately. Imagine balancing a cup of water on your lower back.
- Audio cues: [0] "On all fours. Flat back." [5] "Right arm and left leg out." [10] "Return." [15] "Left arm and right leg out."

### New Balance Exercises

**Single-Leg Stand** (Beginner, 60s)
- Description: Fundamental one-leg balance hold.
- Instructions: Stand near a chair or wall for support. Shift weight to one leg. Lift opposite foot off the ground. Hold as long as comfortable. Switch legs.
- Tips: Keep a chair within arm's reach for safety. Focus your eyes on a fixed point ahead. Start with short holds and build up gradually.
- Audio cues: [0] "Hold onto a chair if needed. Lift your right foot." [30] "Switch to your left foot."

**Heel-to-Toe Walk** (Beginner, 60s)
- Description: Straight-line tandem walking for stability.
- Instructions: Stand near a wall or counter for support. Place the heel of one foot directly in front of the toes of the other. Walk in a straight line. Take 10 to 15 steps. Turn carefully and repeat.
- Tips: Walk alongside a wall you can touch for safety. Keep your gaze forward, not down at your feet. Go slowly — speed is not the goal.
- Audio cues: [0] "Stay near a wall. Place your heel in front of your toes." [30] "Keep going, nice and steady."

**Tree Pose** (Beginner, 60s)
- Description: Yoga-inspired single-leg balance.
- Instructions: Stand near a chair or wall. Shift weight to one leg. Place the other foot on your inner calf or thigh, never on the knee. Bring hands to chest or overhead. Switch legs.
- Tips: Use a chair for support until you feel confident. Never place your foot directly on the knee joint. Start with your foot on the calf before progressing higher.
- Audio cues: [0] "Keep a chair close. Balance on your right leg." [30] "Switch to your left leg."

**Standing Knee Lifts** (Beginner, 60s)
- Description: Alternating slow knee raises for balance.
- Instructions: Stand tall near a chair for support. Slowly lift one knee to hip height. Hold briefly at the top. Lower the leg slowly and with control. Alternate legs.
- Tips: Hold the back of a chair if you feel unsteady. Keep your standing leg slightly bent. Maintain an upright posture throughout.
- Audio cues: [0] "Hold a chair for support. Lift your right knee." [15] "Lower and switch." [30] "Lift your left knee." [45] "Lower and switch."

**Weight Shifts** (Beginner, 60s)
- Description: Side-to-side weight transfer for stability.
- Instructions: Stand with feet hip-width apart. Keep a chair nearby. Slowly shift your weight to your right foot. Hold for a few seconds. Shift your weight to your left foot. Repeat smoothly side to side.
- Tips: Keep a chair nearby for safety. This is an excellent starter exercise for balance. Move gently and deliberately — no sudden shifts.
- Audio cues: [0] "Feet hip-width apart. Shift weight to your right." [15] "Now shift to your left." [30] "Back to the right." [45] "And to the left."

**Clock Reach** (Intermediate, 60s)
- Description: Single-leg reach to clock positions.
- Instructions: Stand on one leg near a chair for support. Imagine you are standing at the center of a clock. Reach your opposite foot toward 12 o'clock, then 3, then 6, then 9. Return to center each time. Switch standing legs.
- Tips: Use a chair for support when starting out. Keep the reaching leg light — just a gentle tap, not a full weight transfer. This exercise challenges balance in all directions.
- Audio cues: [0] "Hold a chair. Stand on your right leg." [10] "Reach to 12 o'clock." [20] "Reach to 3 o'clock." [30] "Switch legs. Stand on your left." [40] "Reach to 12." [50] "Reach to 9."
