# Research: App Beautification

**Branch**: `003-app-beautification` | **Phase**: 0 | **Date**: 2026-03-24

---

## Decision 1: Shared Design Token Strategy

**Question**: How should shared visual constants (corner radius, shadow, spacing) be distributed across views without violating Constitution Principle V (no premature abstraction)?

**Decision**: A single `DesignSystem.swift` file containing a `struct DesignTokens` with static constants and a `CardModifier: ViewModifier` for consistent card styling.

**Rationale**:
- A plain `struct` with `static let` properties is the simplest possible sharing mechanism — no protocols, no generics, no DI.
- A single `ViewModifier` for the card style is justified: the pattern is used across 6+ screens (DashboardCard, CategoryCard, ExerciseCell, RoutineExerciseCard, ProfileHeader, OnboardingButton). Without it, the same padding/background/cornerRadius/shadow would be duplicated 6+ times — the exact duplication that Constitution Principle V warns about via "three concrete, clear implementations."
- Environment values (a more SwiftUI-idiomatic approach) were considered but rejected: they require a custom `EnvironmentKey`, `EnvironmentValues` extension, and a wrapper property — more code for the same outcome when the token values are compile-time constants.

**Alternatives considered**:
- Protocols/generic wrappers: rejected (over-engineered for static constants)
- Multiple separate files: rejected (unnecessary fragmentation)
- Inline duplication across all views: rejected (>6 identical code blocks)

---

## Decision 2: LiquidGlass Light/Dark Mode Compatibility

**Question**: The existing `LiquidGlass` component and its consumers (`DailyRoutineCard`, `CategoryCard`) force `.environment(\.colorScheme, .dark)` to maintain legibility. How do we remove this override while keeping the glassmorphism aesthetic?

**Decision**: Refactor `LiquidGlass` to use adaptive foreground colors (`.primary`/`.secondary`) and adaptive background materials. Cards will use white text only when placed on a dark/image background, and system-standard text otherwise.

**Rationale**:
- `.ultraThinMaterial` already adapts to light/dark mode; the forced dark override was added because the original overlay colors (white opacity) look washed out in light mode.
- The fix is to use `Color.primary` for card text (which is dark in light mode, light in dark mode) instead of hardcoded `.white`, and to adjust the gradient overlay to use neutral tones that work in both modes.
- This approach requires no conditional code — SwiftUI's semantic colors handle the adaptation automatically.

**Alternatives considered**:
- Keeping the `.dark` override but limiting its scope: rejected (masks the root cause and prevents proper Dark Mode support)
- Different card designs for light vs dark mode (`@Environment(\.colorScheme)`): rejected (conditional branching for pure aesthetics violates simplicity)

---

## Decision 3: App Icon Design Direction

**Question**: What visual design should the app icon convey, and what is the technical delivery format?

**Decision**: The app icon uses a bold, minimalist circular gradient background (conveying energy/wellness) with a stylized figure or symbol representing daily movement. Delivered as a set of PNG assets in `Assets.xcassets/AppIcon.appiconset/`.

**Rationale**:
- iOS 17 requires a single 1024×1024 PNG in the App Store icon slot, with the OS automatically generating device-sized variants from a single source or from an explicit set.
- iOS 18 introduced adaptive icons (dark variant, tinted variant) but the minimum viable requirement is a single light-mode icon.
- The design direction (gradient background + simple symbol) reflects the `LiquidGlass` aesthetic of the app: modern, clean, slightly translucent feel.
- SF Symbols cannot be used directly as app icon content (they are for in-app UI), but can inspire the symbol shape used in the icon artwork.

**Required sizes** (for a complete iOS icon set):
| Size (pt) | Scale | Pixels | Use |
|-----------|-------|--------|-----|
| 1024×1024 | 1x | 1024×1024 | App Store |
| 60 | 3x | 180×180 | iPhone home screen (@3x) |
| 60 | 2x | 120×120 | iPhone home screen (@2x) |
| 40 | 3x | 120×120 | Spotlight (@3x) |
| 40 | 2x | 80×80 | Spotlight (@2x) |
| 29 | 3x | 87×87 | Settings (@3x) |
| 29 | 2x | 58×58 | Settings (@2x) |

**Alternatives considered**:
- SF Symbol rendered as icon programmatically: not possible for App Store submission (must be PNG/PDF)
- Single 1024×1024 with automatic scaling only: acceptable minimum, but a full icon set avoids any OS-level interpolation artifacts

---

## Decision 4: Animation & Micro-Interaction Strategy

**Question**: How should the `ScaleButtonStyle` be extended to other interactive elements without creating bespoke animation code in each view?

**Decision**: The existing `ScaleButtonStyle` in `ContentView.swift` is extracted to `DesignSystem.swift` and applied via `.buttonStyle(DesignTokens.scaleButton)` at the point of each `Button`. No new animation framework needed.

**Rationale**:
- `ButtonStyle` is the SwiftUI-idiomatic way to apply consistent interaction animations to `Button` views — it requires zero additional state management.
- Moving `ScaleButtonStyle` to `DesignSystem.swift` makes it available across all view files without import overhead.
- Timer progress and completion animations in `ExerciseDetailView` already use `.animation(.linear, value: timeRemaining)` — extending this to a color-change completion state requires only adding a conditional foreground color on the `TimerCircle` arcs, no new animation primitives.

**Alternatives considered**:
- Custom `ViewModifier` for press animations: rejected (ButtonStyle already handles this for Button; for non-button tappable elements like list rows, `onTapGesture` + `@State` is simpler)
- Third-party animation library: rejected (Constitution Principle, zero third-party deps)

---

## Decision 5: Exercise List Cell Design

**Question**: How should exercise cells in `ExerciseListView` be enhanced to show difficulty and duration without a full custom list implementation?

**Decision**: Replace the `List` with a `ScrollView` + `LazyVStack` using a custom `ExerciseRowView` card that shows: category icon (from the category's `icon` property via `ExerciseCategory`), exercise name, difficulty badge (color-coded chip), and duration.

**Rationale**:
- `List` rows have limited layout customization and add separator lines that clash with the card aesthetic.
- `LazyVStack` within `ScrollView` provides the same scrolling performance as `List` for the expected content volume (~30 exercises per category) while allowing full visual control.
- The `ExerciseCategory.icon` property (SF Symbol name) already exists — reusing it in exercise cells adds visual consistency between the category grid and the exercise list.

**Alternatives considered**:
- Custom `UITableViewCell` via UIKit: rejected (violates Constitution Principle I — SwiftUI-first)
- Keeping `List` with `.listRowBackground`: rejected (achieves less visual control than LazyVStack approach)

---

## Decision 6: Routine Detail View Redesign

**Question**: The `RoutineDetailView` uses a plain `List` for exercises. Should this become a `ScrollView + VStack` like the exercise list, or a different layout?

**Decision**: Replace the `List` with a `ScrollView` + `LazyVStack` using `ExerciseRoutineCard` styled components. The Start/Continue button moves to a sticky bottom bar using `.safeAreaInset(edge: .bottom)`.

**Rationale**:
- The `.safeAreaInset` modifier (iOS 15+) allows a button to be pinned to the bottom without wrapping everything in a `ZStack`, which is the SwiftUI-idiomatic approach.
- The exercise progress state (completed = green checkmark, current = blue indicator, upcoming = gray) maps naturally to card backgrounds (subtle green/blue/gray tint on the card).
- Using cards with the shared `cardStyle()` modifier ensures the routine detail matches the dashboard aesthetic.

---

## Decision 7: Profile View Layout

**Question**: The `ProfileView` uses a `Form` which creates a very "settings app" feel. What's the right replacement?

**Decision**: Replace `Form` with a `ScrollView` + `VStack` layout. The profile photo and stats display at the top in a hero-style section; reminders and reset remain in clearly delineated sections below using styled `GroupBox`-inspired containers.

**Rationale**:
- `Form` cannot be styled to match the app's card aesthetic without UIKit intervention.
- `GroupBox` (SwiftUI native, iOS 14+) provides a ready-made grouped container visual that can be further styled. However, for maximum control, plain `VStack` + card modifier is preferred.
- The reminder `Toggle` and `DatePicker` remain functional components — only their container styling changes.
