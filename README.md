# daily

A personal wellness iOS app that builds short, focused workout sessions every day — stretching, breathing, bodyweight, and balance — with voice-guided coaching and a progression system that unlocks longer sessions over time.

## Features

### 🏋️ Exercise Library (61 exercises)
- **Stretching** — 18 exercises covering full-body mobility
- **Breathing** — Box breathing, 4-7-8, resonant breathing, progressive relaxation, and more
- **Bodyweight** — 20 exercises from beginner push-ups to advanced burpees
- **Balance** — 6 stability exercises with safety-aware coaching

### 📅 Daily Workouts
Sessions are dynamically generated from the exercise library to fill your chosen time budget. Every session is different.

### 🎙️ Voice Guidance
Real-time audio coaching cues at timed intervals throughout each exercise — form reminders, breathing cues, side-switch prompts, and countdowns. Exercise names are announced at the start of each set.

### 🏆 Session Tiers & Progression
| Tier | Duration | Unlocks at |
|------|----------|------------|
| Beginner | 10-12 min | Default |
| Intermediate | 15-20 min | Level 7 (≈30 days) |
| Advanced | 20-30 min | Level 20 (≈95 days) |

Complete one routine per day to earn XP. Streak bonuses (+50 XP) at 7, 30, and 100 consecutive days. Level up celebrations announce newly unlocked tiers.

### 👤 Profile
- Gender selection for personalised exercise recommendations
- Photo, streak count, XP, level, and tier badge
- Daily reminder notifications (optional)

## Tech Stack

- **Swift 5.9+** / Xcode 26.2
- **SwiftUI** — all UI, zero UIKit views
- **SwiftData** — on-device persistence (exercises, routines, user profile)
- **AVFoundation** — text-to-speech via `AVSpeechSynthesizer`
- **UserNotifications** — daily reminder scheduling
- **PhotosUI** — profile photo picker
- Zero third-party dependencies

**Minimum deployment target**: iOS 17.0

## Building

1. Clone the repo
2. Open `daily.xcodeproj` in Xcode
3. Select a Simulator or connected device
4. **⌘B** to build, **⌘R** to run

No package dependencies to resolve — everything is system frameworks.

## Project Structure

```
daily/                  ← iOS app source (all .swift files compiled)
├── Models.swift        ← SwiftData models, ExperienceTier, SessionTier, seed data
├── ContentView.swift   ← Dashboard, SessionTierPicker, LevelUpView
├── ExerciseListView.swift  ← Category browser + exercise timer with audio cues
├── RoutineDetailView.swift ← Routine runner with step-through flow
├── ProfileView.swift   ← Profile stats, reminders, gender picker
├── BreathingView.swift ← Breathing exercise UI
├── TTSManager.swift    ← AVSpeechSynthesizer wrapper with queue support
├── NotificationManager.swift
├── DesignSystem.swift  ← Design tokens, card styles, shared components
├── OnboardingView.swift
└── dailyApp.swift      ← App entry point + SwiftData model container

daily.xcodeproj/        ← Xcode project
specs/                  ← Feature specifications (speckit workflow)
```

## Development Workflow

Features are planned and tracked using [speckit](https://speckit.dev):

```
speckit.specify → speckit.plan → speckit.tasks → speckit.implement
```

Feature specs live in `specs/###-feature-name/`.

| # | Feature | Status |
|---|---------|--------|
| 001 | App review & audit | ✅ |
| 002 | Exercise review | ✅ |
| 003 | App beautification | ✅ |
| 004 | Rich voice guidance | ✅ |
| 005 | Session duration tiers | ✅ |

## License

Private — all rights reserved.
