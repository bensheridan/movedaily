# Implementation Plan: App Beautification

**Branch**: `003-app-beautification` | **Date**: 2026-03-24 | **Spec**: [spec.md](spec.md)

## Summary

Establish a unified visual design language across all 6 screens of the `daily` app — Dashboard, Onboarding, Routine Detail, Exercise List, Exercise Detail, and Profile — by creating a shared design system (`DesignSystem.swift`) and refactoring each screen to use it. Remove the forced `.environment(\.colorScheme, .dark)` override on cards and replace all plain `List`/`Form` layouts with styled `ScrollView + LazyVStack` card layouts. Also add a custom app icon to replace the Xcode default placeholder.

---

## Technical Context

**Language/Version**: Swift 5.9+ (Xcode 26.2 / toolchain 2630)
**Primary Dependencies**: SwiftUI, SwiftData, AVFoundation, UserNotifications, PhotosUI (all system frameworks)
**Storage**: SwiftData (unchanged — no new models); `@AppStorage` for reminder preferences (unchanged)
**Testing**: XCTest (manual visual regression via Xcode Previews and device/simulator runs)
**Target Platform**: iOS 17.0+
**Project Type**: Mobile app (SwiftUI-first, offline-only)
**Performance Goals**: 60 fps animations; LiquidGlass blur must not cause visible frame drops on iPhone XS or newer
**Constraints**: Zero third-party dependencies; offline-capable; all views must have `#Preview` blocks
**Scale/Scope**: 6 Swift view files to refactor, 1 new `DesignSystem.swift` to create, 1 app icon asset set to populate

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. SwiftUI-First | ✅ PASS | All UI changes use SwiftUI. No new UIKit code. Existing `ImagePicker` (UIKit) is unchanged — it wraps a system-provided picker with no SwiftUI equivalent. All new views include `#Preview` blocks. |
| II. SwiftData for Persistence | ✅ PASS | No new `@Model` types. No schema changes. `dailyApp.sharedModelContainer` is unchanged. |
| III. Offline-First | ✅ PASS | All changes are purely visual. No network calls introduced. |
| IV. Personalization Without Gatekeeping | ✅ PASS | Removing `.environment(\.colorScheme, .dark)` improves adaptive rendering. No changes to gender-based content filtering. |
| V. Simplicity & No Premature Abstraction | ✅ PASS | One `DesignSystem.swift` file with a plain struct + one ViewModifier. No ViewModels, Coordinators, or DI. Justified: the card style pattern appears 6+ times across the codebase — below the abstraction threshold, we'd have 6+ blocks of duplicated style code. |

**Post-Phase-1 Re-check**: All gates still pass. `DesignTokens` struct and `CardModifier` are the minimum viable abstraction.

---

## Project Structure

### Documentation (this feature)

```text
specs/003-app-beautification/
├── plan.md              ← this file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
├── checklists/
│   └── requirements.md
└── tasks.md             ← Phase 2 output (/speckit.tasks)
```

### Source Code

```text
daily/                          ← all Swift source compiled by Xcode
├── DesignSystem.swift           ← NEW: shared tokens, CardModifier, ScaleButtonStyle
├── ContentView.swift            ← MODIFY: LiquidGlass light-mode fix, remove .dark env override
├── OnboardingView.swift         ← MODIFY: hero section, styled buttons
├── RoutineDetailView.swift      ← MODIFY: List → ScrollView cards, sticky bottom button
├── ExerciseListView.swift       ← MODIFY: List → ScrollView cards, DifficultyBadge, empty state
├── ProfileView.swift            ← MODIFY: Form → ScrollView styled sections
└── Assets.xcassets/
    └── AppIcon.appiconset/      ← NEW: custom icon PNGs + Contents.json
```

**Structure Decision**: Single-project mobile app (Option 1). All `.swift` files live flat in `daily/`. No subdirectories — consistent with the existing project structure.

---

## Complexity Tracking

> No Constitution violations — table intentionally empty.

---

## Implementation Phases

### Phase A — Foundation (P0: blocks all other work)

**Goal**: Establish the shared design system so all subsequent phases can reference it.

**Task A1**: Create `DesignSystem.swift`
- Define `struct DesignTokens` with all static constants (see data-model.md)
- Move `ScaleButtonStyle` from `ContentView.swift` into `DesignSystem.swift`
- Define `CardModifier: ViewModifier` applying `.regularMaterial` background, border overlay, and drop shadow
- Add `View.cardStyle()` convenience extension
- Add `#Preview` demonstrating a card and a scaled button

**Task A2**: Fix `LiquidGlass` for light/dark mode
- In `ContentView.swift`, update `LiquidGlass.body`:
  - Replace hardcoded `Color.white.opacity(…)` gradient values with values that look good in both modes (use adaptive system colors or reduce opacity to work on light backgrounds)
  - Remove `.environment(\.colorScheme, .dark)` from `DailyRoutineCard` and `CategoryCard`
- Verify in both Light Mode and Dark Mode preview

**Dependency**: None. Must complete before Phase B–E.

---

### Phase B — Dashboard Polish (P1)

**Goal**: Ensure the dashboard already looks cohesive and correct after LiquidGlass fix.

**Task B1**: Update `HeaderView`
- Add a personalized greeting that uses the user's name if available, falls back to gender-based greeting, then falls back to "Hello!"
- Apply consistent typography: `.title` for the primary greeting, `.subheadline` for the sub-label

**Task B2**: Update `StatsView` / `StatItem`
- Apply `.cardStyle()` to the outer `HStack` container wrapping all stat items
- Apply consistent icon sizes and typography scale

**Task B3**: Apply `ScaleButtonStyle` to all dashboard navigation links
- Replace references to the local `ScaleButtonStyle()` with `DesignTokens.scaleButton`

**Dependency**: Phase A complete.

---

### Phase C — Onboarding (P2)

**Goal**: Replace minimal onboarding with an engaging first-impression screen.

**Task C1**: Redesign `OnboardingView`
- Add a hero section at the top: large SF Symbol (e.g., `figure.run` or `sun.max.fill`) with a gradient background pill/circle, and a tagline ("Move a little every day.")
- Style the `GenderButton` views using `.cardStyle()` instead of the plain `.cornerRadius` + `.stroke` border
- Apply `DesignTokens.scaleButton` to all buttons

**Dependency**: Phase A complete.

---

### Phase D — Exercise Flows (P3)

**Goal**: Replace plain List views with visually rich card layouts.

**Task D1**: Redesign `ExerciseListView`
- Replace `List` with `ScrollView { LazyVStack(spacing: DesignTokens.sectionSpacing) }`
- Create `ExerciseRowCard` view (inline in file):
  - Left: category icon (from `category.icon`) in a small colored circle
  - Center: exercise name (`.headline`) + description (`.subheadline`, 2-line limit)
  - Right: `DifficultyBadge` + duration in `.caption`
  - Card: full width, `.cardStyle()`, `NavigationLink` tap target
- Add empty state: centered icon + "No exercises available for this category" text, shown when `exercises.isEmpty`
- Add `#Preview` for populated and empty states

**Task D2**: Update `ExerciseDetailView`
- Apply `.cardStyle()` to the Instructions section container (currently `Color(.secondarySystemBackground)` + `.cornerRadius(15)`)
- Apply `.cardStyle()` to the Safety & Form tips section container
- Add a timer completion visual state: when `timerCompleted == true`, change the `TimerCircle` arc color from `.blue` to `.green` with `.animation(.easeInOut, value: timerCompleted)`
- Apply `DesignTokens.scaleButton` to Start/Pause and Reset buttons

**Dependency**: Phase A complete.

---

### Phase E — Routine Detail (P3)

**Goal**: Replace plain List with styled exercise progress cards.

**Task E1**: Redesign `RoutineDetailView`
- Replace `List` + `Section` with `ScrollView { LazyVStack }` + `ExerciseProgressCard` view (inline):
  - Shows step number, exercise name, duration
  - Background tint: green tint if completed, blue tint if current, neutral if upcoming
  - Checkmark/play icon on trailing edge (existing logic preserved)
- Move the Start/Continue button to a `.safeAreaInset(edge: .bottom)` sticky bar with `.cardStyle()` applied to the button container
- Apply `DesignTokens.scaleButton` to the action button

**Dependency**: Phase A complete.

---

### Phase F — Profile (P4)

**Goal**: Replace Form with a styled scrollable layout.

**Task F1**: Redesign `ProfileView`
- Replace `Form` with `ScrollView { VStack(spacing: DesignTokens.sectionSpacing) }`
- Create a hero header card: profile photo (existing logic) + gender label + XP/Level/Streak stats displayed inline below the photo — all in a single `.cardStyle()` card
- Reminders section: styled card container wrapping the `Toggle` and `DatePicker` (no `Form` section)
- Reset section: styled card with a destructive button, red tint
- Apply `DesignTokens.scaleButton` to the Edit Photo button

**Dependency**: Phase A complete.

---

### Phase G — App Icon (P2)

**Goal**: Replace the Xcode default placeholder with a custom app icon.

**Task G1**: Design and create app icon assets
- Create icon artwork: gradient circle background (blue → indigo/teal) + a bold movement symbol
- Export PNGs at all required sizes (see data-model.md for the full table)
- Ensure no alpha channel in any PNG (required by App Store)

**Task G2**: Configure asset catalog
- Populate `daily/Assets.xcassets/AppIcon.appiconset/` with all PNG files
- Update `Contents.json` to reference all sizes correctly
- Build and verify icon appears in Simulator home screen and Settings

**Dependency**: None. Can run in parallel with Phase A–F.

---

### Phase H — Micro-Interactions (P4)

**Goal**: Ensure every interactive element has tap feedback.

**Task H1**: Audit and apply `DesignTokens.scaleButton`
- Systematically check every `Button` in all modified views
- Apply `.buttonStyle(DesignTokens.scaleButton)` wherever missing

**Task H2**: Streak/XP/Level animation on profile update
- In `ProfileView` hero card, apply `.contentTransition(.numericText())` to XP and streak `Text` views (iOS 16+) so number changes animate smoothly

**Dependency**: Phases B–F complete (auditing modified views).

---

## Phase Execution Order

```
Phase A (Foundation)
    ↓
Phase B, C, D, E, F (can run in parallel, all depend on A)
Phase G (parallel with all — no dependency)
    ↓
Phase H (depends on B–F)
```

---

## Risk Register

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| `LiquidGlass` blur looks different after removing dark env override | Medium | Test thoroughly in both Light + Dark Mode before merging Phase A; adjust gradient opacity values as needed |
| App icon PNG has alpha channel → Xcode error | Low | Export from design tool with "Remove Alpha" option; verify with `file` command or Preview app |
| `LazyVStack` performance on large exercise lists | Low | Exercise count per category is ~10–15; LazyVStack initializes lazily, so no issue expected |
| `contentTransition(.numericText())` requires iOS 16 minimum | Low | App targets iOS 17+, so this API is available |
