# daily Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-03-24

## Active Technologies

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

- 001-app-review-audit: Added Swift 5.9+ (project created with Xcode 26.2 / toolchain 2630) + SwiftUI, SwiftData, AVFoundation, UserNotifications, PhotosUI (all system frameworks, zero third-party)

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
