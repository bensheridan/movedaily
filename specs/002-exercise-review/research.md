# Research: Exercise Library Review & Reorganization

**Feature**: 002-exercise-review | **Date**: 2026-03-24

## R1: SwiftData Enum Migration Strategy

### Decision: Keep `.kegels` in enum, add `.balance`, use filtered display list

### Rationale

SwiftData stores `ExerciseCategory` as its raw string value (`"Kegels"`, `"Stretching"`, etc.) in the underlying SQLite database. If `.kegels` is removed from the `CaseIterable` enum, SwiftData will fail to decode any `Exercise` entity whose stored category is `"Kegels"` — this causes a crash or silent data loss on app launch for existing users.

The safest approach is to:
1. **Keep `.kegels` in the enum** for backward compatibility (old data can still decode)
2. **Add `.balance` as a new case** (5 total enum cases)
3. **Add a static `displayCategories` property** that returns the 4 categories shown in the UI (excluding `.kegels`)
4. **Run a migration on app launch** that fetches any exercises still categorized as `.kegels` and re-assigns them to `.stretching`

After migration runs once, no exercises will have `.kegels` as their category — the enum case becomes a dead value, preserved only for decode safety.

### Alternatives Considered

| Alternative | Rejected Because |
|------------|-----------------|
| Remove `.kegels` entirely from enum | SwiftData will crash when decoding existing `"Kegels"` raw values from the database |
| Use `SchemaMigrationPlan` | The schema shape hasn't changed — same fields, same types. This is a data value migration, not a schema migration. Adding a migration plan would be over-engineered for a raw-value update. |
| Use `init(from decoder:)` fallback | Would require custom Codable implementation on the enum, adding complexity for a one-time migration. The runtime migration approach is simpler and explicit. |

---

## R2: Balance Exercise Content — Safety-First Design

### Decision: All balance exercises include chair/support safety instructions in both `instructions` and `tips`

### Rationale

Balance exercises carry a higher fall risk than other categories, particularly for elderly users. The user specifically requested that exercises instruct users to grab a chair for support. Every balance exercise will:

1. **Instructions**: First step is always a safety setup (e.g., "Stand near a chair or wall for support")
2. **Tips**: Include at least one tip about keeping a chair within arm's reach
3. **Audio cues**: The first audio cue (at 0 seconds) reinforces the safety positioning before beginning the movement
4. **Difficulty**: 5 of 6 exercises are Beginner; only Clock Reach is Intermediate

This ensures the TTS system speaks the safety advice immediately when the user starts the timer.

### Balance Exercise Content

#### Single-Leg Stand (Beginner, 60s)
- **Instructions**: Stand near a chair or wall for support. Shift weight to one leg. Lift opposite foot off the ground. Hold as long as comfortable. Switch legs.
- **Tips**: Keep a chair within arm's reach for safety. Focus eyes on a fixed point ahead. Start with short holds and build up gradually.
- **Audio cues**: [0] "Hold onto a chair if needed. Lift your right foot." [30] "Switch to your left foot."

#### Heel-to-Toe Walk (Beginner, 60s)
- **Instructions**: Stand near a wall or counter for support. Place heel of one foot directly in front of toes of the other. Walk in a straight line. Take 10 to 15 steps. Turn carefully and repeat.
- **Tips**: Walk alongside a wall you can touch for safety. Keep your gaze forward, not down. Go slowly — speed is not the goal.
- **Audio cues**: [0] "Stay near a wall. Place your heel in front of your toes." [30] "Keep going, nice and steady."

#### Tree Pose (Beginner, 60s)
- **Instructions**: Stand near a chair or wall. Shift weight to one leg. Place other foot on inner calf or thigh, never on the knee. Bring hands to chest or overhead. Switch legs.
- **Tips**: Use a chair for support until you feel confident. Never place your foot directly on the knee joint. Start with your foot on the calf before progressing higher.
- **Audio cues**: [0] "Keep a chair close. Balance on your right leg." [30] "Switch to your left leg."

#### Standing Knee Lifts (Beginner, 60s)
- **Instructions**: Stand tall near a chair for support. Slowly lift one knee to hip height. Hold briefly at the top. Lower the leg slowly and with control. Alternate legs.
- **Tips**: Hold the back of a chair if you feel unsteady. Keep your standing leg slightly bent. Maintain an upright posture throughout.
- **Audio cues**: [0] "Hold a chair for support. Lift your right knee." [15] "Lower and switch." [30] "Lift your left knee." [45] "Lower and switch."

#### Weight Shifts (Beginner, 60s)
- **Instructions**: Stand with feet hip-width apart. Keep a chair nearby. Slowly shift your weight to your right foot. Hold for a few seconds. Shift your weight to your left foot. Repeat smoothly side to side.
- **Tips**: Keep a chair nearby for safety. This is an excellent starter exercise for balance. Move gently and deliberately — no sudden shifts.
- **Audio cues**: [0] "Feet hip-width apart. Shift weight to your right." [15] "Now shift to your left." [30] "Back to the right." [45] "And to the left."

#### Clock Reach (Intermediate, 60s)
- **Instructions**: Stand on one leg near a chair for support. Imagine you are standing at the center of a clock. Reach your opposite foot toward 12 o'clock, then 3, then 6, then 9. Return to center each time. Switch standing legs.
- **Tips**: Use a chair for support when starting out. Keep the reaching leg light — just a gentle tap. This exercise challenges balance in all directions.
- **Audio cues**: [0] "Hold a chair. Stand on your right leg." [10] "Reach to 12 o'clock." [20] "Reach to 3 o'clock." [30] "Switch legs. Stand on your left." [40] "Reach to 12." [50] "Reach to 9."

---

## R3: Balance Category Icon

### Decision: Use `"figure.stand"` SF Symbol

### Rationale

Reviewed available SF Symbols for balance/stability:
- `figure.stand` — Clean, recognizable silhouette of a standing figure. Directly conveys the "standing balance" concept.
- `figure.walk` — More associated with movement/walking than static balance
- `figure.mind.and.body` — Available in iOS 17+, but more associated with yoga/mindfulness
- `figure.flexibility` — Already used by Stretching category

`figure.stand` is distinct from all other category icons and communicates "balance and stability" clearly.

---

## R4: New Exercises for Other Categories

### Decision: Add 8 new exercises across Stretching (3), Breathing (2), and Bodyweight (3)

### Rationale

Reviewed the current exercise library for gaps:

**Stretching gaps identified**:
- No wrist/forearm exercises (important for desk workers who are the primary audience for a daily wellness app)
- No deep hip opener (Pigeon Pose is one of the most popular flexibility exercises globally)
- No spinal rotation exercise (Seated Spinal Twist addresses rotational mobility)

**Breathing gaps identified**:
- All existing techniques are calm/quiet — no energizing breath technique (Lion's Breath fills this gap)
- No vibration-based technique (Humming Bee / Bhramari is well-evidenced for anxiety relief)

**Bodyweight gaps identified**:
- No back extension exercise (Superman Hold addresses posterior chain, critical for posture)
- No deep core stability exercise (Dead Bug is a rehabilitation staple, beginner-friendly)
- No balance + core combination (Bird Dog bridges these two areas)

All new exercises are:
- Equipment-free and home-suitable
- 60-second timer format (consistent with existing exercises)
- Beginner difficulty (except Pigeon Pose at Intermediate)
- Gender-neutral (no `genderFocus`)
