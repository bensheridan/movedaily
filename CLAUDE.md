# daily Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-03-25

## Active Technologies
- SwiftData — local on-device SQLite; `UserDefaults` via `@AppStorage` for lightweight preferences (002-exercise-review)
- Swift 5.9+ (Xcode 26.2 / toolchain 2630) + SwiftUI, SwiftData, AVFoundation, UserNotifications, PhotosUI (all system frameworks) (003-app-beautification)
- SwiftData (unchanged — no new models); `@AppStorage` for reminder preferences (unchanged) (003-app-beautification)
- Swift 5.9+ (Xcode 26.2 toolchain) + AVFoundation / `TTSManager` (existing) — no new dependencies (004-rich-voice-guidance)
- SwiftData (`Exercise.audioCues: [Int: String]`) — schema unchanged (004-rich-voice-guidance)
- Swift 5.9+ (Xcode 26.2 toolchain) + SwiftUI, SwiftData, `@AppStorage` — all system frameworks, zero third-party (005-session-tiers)
- SwiftData for model-level data (`UserProfile`, `Routine`, `Exercise`); `@AppStorage` for the lightweight `preferredSessionTier` preference (005-session-tiers)

- Swift 5.9+ (project created with Xcode 26.2 / toolchain 2630) + SwiftUI, SwiftData, AVFoundation, UserNotifications, PhotosUI (all system frameworks, zero third-party) (001-app-review-audit)

## Project Structure

```text
daily/                  ← iOS app source (auto-synced by Xcode, all .swift files compiled)
daily.xcodeproj/        ← Xcode project (do not put .swift source files here)
specs/                  ← speckit feature specs
.specify/               ← speckit templates, scripts, memory
```

## Commands

# Build: open daily.xcodeproj in Xcode → ⌘B
# Clean build: ⇧⌘K then ⌘B
# No CLI build tool configured (Xcode-only project)

## Code Style

Swift: Follow SwiftUI idioms. Views must have #Preview blocks. No nested NavigationView.
SwiftData: All @Model types registered in dailyApp.sharedModelContainer schema.

## Recent Changes
- 005-session-tiers: Added Swift 5.9+ (Xcode 26.2 toolchain) + SwiftUI, SwiftData, `@AppStorage` — all system frameworks, zero third-party
- 005-session-tiers: Added Swift 5.9+ (Xcode 26.2 toolchain) + SwiftUI, SwiftData, `@AppStorage` — all system frameworks, zero third-party
- 004-rich-voice-guidance: Added Swift 5.9+ (Xcode 26.2 toolchain) + AVFoundation / `TTSManager` (existing) — no new dependencies


<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
