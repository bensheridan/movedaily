# Data Model: Rich Voice Guidance

**Branch**: `004-rich-voice-guidance` | **Phase**: 1 | **Date**: 2026-03-24

---

## SwiftData Model Changes

**None.** The `audioCues: [Int: String]` field already exists on `Exercise`. No new `@Model` types, no schema migrations, no `SchemaMigrationPlan` required.

---

## Cue Content Standard (the "contract" for audioCue data)

Every `Exercise.audioCues` dictionary must satisfy the following rules after this feature is implemented:

### Rule 1 — Opening Cue (mandatory for all)
- Key: `0` (or ≤ 3)
- Content: A short positioning instruction. How to get into the starting position.

### Rule 2 — Near-End Cue (mandatory for all)
- Key: `durationSeconds - 10` or later
- Content: Signals the exercise is almost over. e.g. `"Almost there."` or `"Last few seconds."`

### Rule 3 — Transition Cue (mandatory for side-switch exercises)
- Key: `durationSeconds / 2` (exact midpoint)
- Content: Names the new side explicitly. e.g. `"Switch to your left leg."` not just `"Switch."`

### Rule 4 — Mid-Exercise Cues (mandatory for exercises > 90s)
- At least one cue between the opening cue and the near-end window
- Spacing: every 15–30 seconds for cycling exercises; at meaningful phase boundaries for others

### Rule 5 — No Duplicate Timestamps
- All keys within a single exercise's `audioCues` dictionary must be unique.

### Rule 6 — Length Limit
- Maximum 8 words per cue value. TTS reads ~2.5 words/second; 8 words ≈ 3 seconds of speech.

---

## Cue Counts by Exercise (target state after implementation)

| Exercise | Duration | Category | Current cues | Target cues | Gap |
|----------|----------|----------|-------------|-------------|-----|
| Neck Tilts | 60s | Stretching | 4 | 5 | +1 near-end |
| Shoulder Rolls | 60s | Stretching | 2 | 4 | +form, +near-end |
| Chest Stretch (Doorway) | 60s | Stretching | 2 | 4 | +form, +near-end |
| Cat-Cow | 60s | Stretching | 2 | 6 | +cycling, +near-end |
| Triceps Stretch | 60s | Stretching | 2 | 3 | +near-end |
| Side Reach Stretch | 60s | Stretching | 2 | 3 | +near-end |
| Hamstring Stretch | 60s | Stretching | 2 | 3 | +near-end |
| Quadriceps Stretch | 60s | Stretching | 2 | 3 | +near-end |
| Calf Stretch | 60s | Stretching | 2 | 3 | +near-end |
| Hip Flexor Stretch | 60s | Stretching | 2 | 4 | +form, +near-end |
| Figure-4 Stretch | 60s | Stretching | 2 | 3 | +near-end |
| Butterfly Stretch | 60s | Stretching | 2 | 3 | +near-end |
| Child's Pose | 60s | Stretching | 1 | 3 | +mid, +near-end |
| IT Band Stretch | 60s | Stretching | 2 | 3 | +near-end |
| Wrist & Forearm Stretch | 60s | Stretching | 4 | 5 | +near-end |
| Pigeon Pose | 60s | Stretching | 2 | 4 | +form, +near-end |
| Seated Spinal Twist | 60s | Stretching | 2 | 4 | +form, +near-end |
| Belly Breathing | 180s | Breathing | 3 | 9 | +cycling for full 3 min |
| 4-7-8 Breathing | 120s | Breathing | 3 | 9 | +repeat cycle cues |
| Box Breathing | 300s | Breathing | 4 | 20 | +cycling every 16s for 5 min |
| Alternate Nostril | 180s | Breathing | 2 | 8 | +cycling + near-end |
| Pursed Lip Breathing | 120s | Breathing | 2 | 6 | +repeat + near-end |
| Resonant Breathing | 300s | Breathing | 2 | 15 | +cycling every 11s for 5 min |
| Gentle Breath Holds | 120s | Breathing | 3 | 7 | +repeat + near-end |
| Progressive Relaxation | 300s | Breathing | 2 | 12 | +body-scan cues throughout |
| Lion's Breath | 120s | Breathing | 6 | 7 | +near-end |
| Humming Bee Breath | 180s | Breathing | 6 | 7 | +near-end |
| Push-ups | 60s | Bodyweight | **0** | 4 | start, form, mid, near-end |
| Knee Push-ups | 60s | Bodyweight | **0** | 4 | start, form, mid, near-end |
| Plank Shoulder Taps | 60s | Bodyweight | **0** | 4 | start, form, mid, near-end |
| Triceps Dips | 60s | Bodyweight | **0** | 4 | start, form, mid, near-end |
| Arm Circles | 60s | Bodyweight | **0** | 4 | start, switch, mid, near-end |
| Inchworm Walks | 60s | Bodyweight | **0** | 4 | start, form, mid, near-end |
| Front Plank | 60s | Bodyweight | **0** | 4 | start, 2× form, near-end |
| Side Plank | 60s | Bodyweight | **0** | 4 | start, switch, form, near-end |
| Glute Bridges | 60s | Bodyweight | **0** | 4 | start, form, mid, near-end |
| Bicycle Crunches | 60s | Bodyweight | **0** | 4 | start, form, mid, near-end |
| Leg Raises | 60s | Bodyweight | **0** | 4 | start, form, mid, near-end |
| Mountain Climbers | 60s | Bodyweight | **0** | 4 | start, form, mid, near-end |
| Squats | 60s | Bodyweight | **0** | 4 | start, form, mid, near-end |
| Lunges | 60s | Bodyweight | **0** | 4 | start, form, mid, near-end |
| Calf Raises | 60s | Bodyweight | **0** | 3 | start, mid, near-end |
| Wall Sit | 60s | Bodyweight | **0** | 4 | start, form, mid, near-end |
| Burpees | 60s | Bodyweight | **0** | 4 | start, form, mid, near-end |
| Clamshells | 60s | Bodyweight | **0** | 4 | start, switch, form, near-end |
| Diamond Push-ups | 60s | Bodyweight | **0** | 4 | start, form, mid, near-end |
| Jump Squats | 60s | Bodyweight | **0** | 4 | start, form, mid, near-end |
| Superman Hold | 60s | Bodyweight | 4 | 5 | +near-end |
| Dead Bug | 60s | Bodyweight | 4 | 5 | +near-end |
| Bird Dog | 60s | Bodyweight | 4 | 5 | +near-end |
| Muscle Discovery | 60s | Stretching | 2 | 3 | +near-end |
| Standard Kegels (M) | 120s | Stretching | 3 | 7 | +cycling |
| Power Pulses | 60s | Stretching | 3 | 4 | +near-end |
| Standard Kegels (F) | 120s | Stretching | 2 | 7 | +cycling |
| Elevator Kegels | 120s | Stretching | 4 | 7 | +cycling |
| Single-Leg Stand | 60s | Balance | 2 | 4 | +form, +near-end |
| Heel-to-Toe Walk | 60s | Balance | 2 | 4 | +form, +near-end |
| Tree Pose | 60s | Balance | 2 | 4 | +form, +near-end |
| Standing Knee Lifts | 60s | Balance | 4 | 5 | +near-end |
| Weight Shifts | 60s | Balance | 4 | 5 | +near-end |
| Clock Reach | 60s | Balance | 6 | 7 | +near-end |

**Total current cues across all exercises**: ~110
**Target total cues**: ~290
**Net new cues to write**: ~180
