# Data Model: App Beautification

**Branch**: `003-app-beautification` | **Phase**: 1 | **Date**: 2026-03-24

---

## SwiftData Model Changes

**None.** This feature is purely visual. No new `@Model` types are introduced, and no existing `@Model` types are modified. The `dailyApp.sharedModelContainer` schema is unchanged.

---

## New UI Design Entities

These are compile-time Swift constructs (not SwiftData models) introduced to support the design system.

### `DesignTokens` (struct — `DesignSystem.swift`)

A namespace struct containing all shared visual constants. All properties are `static let`.

| Constant | Type | Value | Purpose |
|----------|------|-------|---------|
| `cardCornerRadius` | `CGFloat` | 20 | Uniform corner radius for all card containers |
| `cardShadowRadius` | `CGFloat` | 8 | Shadow blur radius for elevated cards |
| `cardShadowOpacity` | `Double` | 0.08 | Shadow opacity to keep shadow subtle |
| `cardShadowOffset` | `CGSize` | (0, 4) | Shadow direction (downward) |
| `cardPadding` | `CGFloat` | 16 | Inner padding for card content |
| `sectionSpacing` | `CGFloat` | 20 | Vertical spacing between page sections |
| `gridSpacing` | `CGFloat` | 15 | Spacing between grid cells (category grid) |
| `scaleButton` | `ScaleButtonStyle` | instance | Shared ButtonStyle for press animation |

### `CardModifier` (ViewModifier — `DesignSystem.swift`)

Applied via `.cardStyle()` convenience extension. Applies:
- Rounded rectangle clip shape with `cardCornerRadius`
- Subtle border overlay (system separator color, 0.5pt)
- Drop shadow using `cardShadowRadius`, `cardShadowOpacity`, `cardShadowOffset`
- Background: `.regularMaterial` (adaptive — light in light mode, dark-tinted in dark mode)

Usage: `myView.cardStyle()`

### `DifficultyBadge` (View — inline in `ExerciseListView.swift`)

A small pill-shaped label showing exercise difficulty.

| Property | Type | Description |
|----------|------|-------------|
| `difficulty` | `Difficulty` | The difficulty level (existing enum) |
| `color` | `Color` (computed) | `.green` / `.orange` / `.red` |

Renders as: colored text on matching opacity background, `caption` font, 6pt H padding / 3pt V padding, 6pt corner radius.

---

## App Icon Asset Specification

**Location**: `daily/Assets.xcassets/AppIcon.appiconset/`

**Design Direction**:
- Background: Circular gradient from the app's blue accent → a lighter complementary tone (e.g., teal/indigo)
- Symbol: A simplified human figure mid-movement or a stylized sun/circle representing the daily practice concept
- Style: Clean, bold, modern — consistent with the LiquidGlass aesthetic
- No text in the icon (icons with text render poorly at small sizes)

**Required files** (PNG, no alpha channel on app icon):

| Filename | Pixels | Usage |
|----------|--------|-------|
| `AppIcon-1024.png` | 1024×1024 | App Store |
| `AppIcon-180.png` | 180×180 | iPhone @3x home |
| `AppIcon-120.png` | 120×120 | iPhone @2x home / Spotlight @3x |
| `AppIcon-87.png` | 87×87 | Settings @3x |
| `AppIcon-80.png` | 80×80 | Spotlight @2x |
| `AppIcon-58.png` | 58×58 | Settings @2x |

**`Contents.json`** must reference all files with correct `idiom`, `scale`, and `size` entries per Apple's asset catalog format.

---

## Existing Model Relationships (Unchanged)

For reference — these are not modified by this feature.

```
UserProfile
  ├── gender: Gender
  ├── xp: Int
  ├── level: Int
  ├── streakCount: Int
  └── profileImage: (computed from stored data)

Exercise
  ├── name: String
  ├── category: ExerciseCategory
  ├── difficulty: Difficulty
  ├── durationSeconds: Int
  ├── genderFocus: Gender?
  ├── instructions: [String]
  ├── tips: [String]
  └── audioCues: [Int: String]

Routine
  ├── name: String
  ├── routineDescription: String
  └── exerciseNames: [String]
```
