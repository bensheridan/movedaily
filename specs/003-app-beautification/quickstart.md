# Quickstart: App Beautification

**Branch**: `003-app-beautification` | **Date**: 2026-03-24

---

## What Was Changed

This feature refactors all screens in the `daily` app to share a cohesive visual design language. It also adds a custom app icon.

**Files modified**:
- `daily/DesignSystem.swift` ← **new file** (shared tokens + CardModifier + ScaleButtonStyle)
- `daily/ContentView.swift` — LiquidGlass fixed for light mode, forced dark env removed
- `daily/OnboardingView.swift` — hero section + styled buttons
- `daily/RoutineDetailView.swift` — List → ScrollView + styled exercise cards
- `daily/ExerciseListView.swift` — List → ScrollView + rich exercise row cards
- `daily/ProfileView.swift` — Form → ScrollView + styled sections
- `daily/Assets.xcassets/AppIcon.appiconset/` ← **new assets**

---

## Design System

### Using DesignTokens

```swift
import SwiftUI

// Spacing / sizing constants
let padding = DesignTokens.cardPadding        // 16
let radius  = DesignTokens.cardCornerRadius   // 20

// Apply consistent card style to any container
myView
    .padding(DesignTokens.cardPadding)
    .cardStyle()   // extension on View — applies background, border, shadow

// Consistent button press animation
Button("Start") { … }
    .buttonStyle(DesignTokens.scaleButton)
```

### Adding a New Screen

1. Use `ScrollView` + `LazyVStack(spacing: DesignTokens.sectionSpacing)` as your scroll container.
2. Wrap each content section in `.cardStyle()`.
3. Use `.buttonStyle(DesignTokens.scaleButton)` on all `Button` elements.
4. Use semantic font styles: `.largeTitle` for screen title, `.title2` for section headers, `.headline` for card titles, `.subheadline` for supporting text, `.caption` for metadata.
5. Do NOT use `.environment(\.colorScheme, .dark)` — all components must adapt natively.

---

## App Icon

The app icon assets live in `daily/Assets.xcassets/AppIcon.appiconset/`. To update the icon:

1. Replace the PNG files with new artwork at the same pixel dimensions.
2. Ensure no alpha channel is present (Xcode will warn if detected).
3. Build and run on a simulator or device to verify the icon appears correctly.
4. Check at all sizes: home screen, Spotlight, and Settings.

---

## Build & Test

```
# Build: open daily.xcodeproj in Xcode → ⌘B
# Preview each view: open the file → click the Preview canvas → ⌘⌥P
# Run on simulator to verify icon: ⌘R, then press Home button
```

**Regression checks after any visual change**:
- [ ] Launch app in Light Mode (Settings → Display & Brightness → Light): all cards legible
- [ ] Launch app in Dark Mode: all cards legible, no color inversions
- [ ] Navigate to every screen and verify card corner radius, shadow, and typography match
- [ ] Tap every button: verify scale animation on press
- [ ] Navigate to an empty exercise category (if seeding allows): verify empty state shows

---

## Known Constraints

- No third-party dependencies may be added (Constitution Principle).
- All Views must have `#Preview` blocks (Constitution Principle I).
- `LiquidGlass` uses `.ultraThinMaterial` — this requires a visible background layer beneath it to show the blur effect. In previews, add a colored background behind views that use `LiquidGlass`.
