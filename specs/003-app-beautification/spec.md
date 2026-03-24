# Feature Specification: App Beautification

**Feature Branch**: `003-app-beautification`
**Created**: 2026-03-24
**Status**: Draft

## Overview

The daily app currently has an inconsistent visual experience. The dashboard uses a polished glassmorphism aesthetic (animated LiquidGlass backgrounds, rounded cards, subtle shadows), but all other screens — routine detail, exercise list, exercise detail, onboarding, and profile — use generic system-default styling that clashes with the dashboard's premium feel. This feature brings visual cohesion, polish, and delight throughout the entire app.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Consistent Visual Identity Across All Screens (Priority: P1)

A user opens the app, completes their daily routine, and visits their profile — and throughout the entire journey, the app feels like a single, cohesive product with a consistent design language, not a mix of polished and plain screens.

**Why this priority**: Visual inconsistency is immediately noticeable and reduces perceived quality. The dashboard already sets a high bar with glassmorphism cards; every other screen currently falls below it. This is the highest-impact story because it touches every navigation path.

**Independent Test**: Launch app → navigate to each of the 5 main screens (Dashboard, Routine Detail, Exercise List, Exercise Detail, Profile) → verify each screen shares the same design language (typography scale, card style, background treatment, color palette) as the Dashboard.

**Acceptance Scenarios**:

1. **Given** the user is on the Dashboard, **When** they tap a category card or the routine card, **Then** the destination screen feels visually continuous — same font style, same card radius, same background treatment — with no jarring shift to plain system UI.
2. **Given** the user navigates to Routine Detail, **When** the screen appears, **Then** the exercise list uses styled cards consistent with the Dashboard's card language rather than a plain List.
3. **Given** the user opens the Profile screen, **When** it loads, **Then** it uses a styled layout that matches the app's visual identity rather than a default Form view.

---

### User Story 2 - Engaging Onboarding Experience (Priority: P2)

A first-time user sees a welcoming, visually appealing onboarding screen that communicates the app's quality and makes the gender selection feel intentional and delightful rather than a bare form.

**Why this priority**: Onboarding is the user's first impression. The current onboarding is functional but minimal — no imagery, no brand story, no visual hierarchy beyond a title and two plain buttons. Improving it sets the tone for the entire app experience.

**Independent Test**: Delete app → reinstall → launch → verify onboarding screen has a branded hero visual, clear value proposition text, and styled selection buttons that match the overall app aesthetic.

**Acceptance Scenarios**:

1. **Given** the app is freshly installed, **When** the user opens it for the first time, **Then** the onboarding screen displays a visually appealing hero section that communicates the app's purpose.
2. **Given** the user is on the onboarding screen, **When** they view the gender selection options, **Then** the buttons are styled consistently with the rest of the app and feel premium rather than placeholder-like.
3. **Given** the user taps "Skip for now", **When** they land on the Dashboard, **Then** the transition feels smooth and visually connected to onboarding.

---

### User Story 3 - Polished Exercise List and Detail Views (Priority: P3)

A user browsing exercises sees rich, informative list cells with category icons and difficulty indicators, and the exercise detail screen feels engaging and motivating — not like a plain form with a timer bolted on.

**Why this priority**: Users spend significant time in the exercise browsing and workout flows. These screens directly affect the workout experience. Improving them increases engagement and sense of quality, but the app is still usable before this story is addressed.

**Independent Test**: Navigate to any category in Exercise Categories → verify list cells show exercise icon, name, difficulty badge, and duration → tap an exercise → verify detail view has a visually styled header, the timer circle is prominent and polished, and the instructions/tips sections use cards consistent with the design system.

**Acceptance Scenarios**:

1. **Given** the user taps an exercise category, **When** the exercise list appears, **Then** each cell shows an icon relevant to the exercise category, the exercise name, a color-coded difficulty badge, and the duration — not just name and description text.
2. **Given** the user is on an exercise detail screen, **When** the timer is inactive, **Then** the screen has a clear visual hierarchy with the timer circle as the focal point, well-spaced instructions below, and the start/pause button styled prominently.
3. **Given** the exercise timer reaches zero, **When** the completion state appears, **Then** the screen provides clear visual feedback (e.g., success state with color change or celebratory element) beyond just an audio cue.

---

### User Story 4 - Smooth Navigation Transitions and Micro-Interactions (Priority: P4)

Throughout the app, interactive elements respond with subtle, fluid animations that reinforce the premium feel — buttons scale on press, screens transition smoothly, and state changes animate gracefully.

**Why this priority**: The `ScaleButtonStyle` already exists on dashboard cards, showing this was an intentional design direction. Extending micro-interactions throughout the app completes the experience but has lower priority than structural visual consistency.

**Independent Test**: Interact with buttons across multiple screens — verify tap animations are present and consistent, verify stat updates in Profile animate rather than jump to new values, verify timer progress animates smoothly.

**Acceptance Scenarios**:

1. **Given** the user taps any primary action button in the app, **When** they press it, **Then** a scale-down micro-animation provides tactile feedback before the action executes.
2. **Given** the routine completion state triggers, **When** the progress stats update, **Then** the streak/XP/level values animate to their new state rather than snapping immediately.

---

### Edge Cases

- What happens when the user has a very long exercise name that would overflow a styled card? Cards must handle multi-line text gracefully without breaking layout.
- What happens on smaller devices (iPhone SE) where glassmorphism backgrounds may be more performance-intensive? Visual fidelity should degrade gracefully if needed.
- What happens in Dark Mode vs Light Mode? The forced `.dark` environment on current category cards must be resolved so cards look correct in both system modes.
- What happens when there are no exercises in a category? An empty state with icon and message should be shown rather than a blank list.
- What happens when the user has no profile photo? The placeholder state in Profile must be visually styled, not just a gray system icon.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST use a consistent design language across all screens — Dashboard, Onboarding, Routine Detail, Exercise List, Exercise Detail, and Profile.
- **FR-002**: The app MUST NOT use forced `.environment(\.colorScheme, .dark)` on individual components; instead, all components MUST render correctly in both Light Mode and Dark Mode natively.
- **FR-003**: All card-style UI elements MUST share a consistent corner radius, shadow style, and background treatment throughout the app.
- **FR-004**: The Exercise List screen MUST display a difficulty badge (color-coded) and duration for each exercise in the list.
- **FR-005**: The Exercise List screen MUST display an empty state with an explanatory message when no exercises exist for the selected category.
- **FR-006**: The Routine Detail screen MUST present exercises using styled cards consistent with the Dashboard's card design, not a plain system List.
- **FR-007**: The Profile screen MUST be redesigned with a visual layout that matches the app's design language rather than using a default Form view.
- **FR-008**: The Onboarding screen MUST include a hero visual or branded section above the gender selection options.
- **FR-009**: All primary action buttons across the app MUST respond to tap with a scale micro-animation.
- **FR-010**: The Exercise Detail screen MUST display a visual completion state when the timer reaches zero, in addition to the existing audio cue.
- **FR-011**: The app's typography MUST follow a consistent scale: large titles for screen headers, title2 for section headers, headline for card titles, subheadline for supporting text, and caption for metadata.

### Key Entities

- **Design Token**: The shared set of visual constants (corner radius, shadow, spacing, typography scale, primary/accent colors) applied consistently across all views.
- **Card Style**: The reusable visual treatment for content containers — rounded corners, subtle border, shadow, and background fill — used throughout the app.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All 6 primary screens (Dashboard, Onboarding, Routine Detail, Exercise List, Exercise Detail, Profile) use the same card corner radius, shadow depth, and background treatment — verifiable by visual inspection of each screen side-by-side.
- **SC-002**: Zero occurrences of forced color scheme overrides remain in the codebase — verifiable by code audit.
- **SC-003**: Every interactive button and card in the app responds to tap with a visible scale animation — verifiable by tapping each interactive element.
- **SC-004**: The Exercise List view displays difficulty and duration metadata on each cell — verifiable by navigating to any exercise category.
- **SC-005**: An empty state message is shown when an exercise category has no exercises — verifiable by inspecting a category with no matching results.
- **SC-006**: The app passes a visual consistency review where all screens are screenshot side-by-side and judged to share a unified design language by a non-technical reviewer.

### User Story 5 - App Icon (Priority: P2)

The app has a distinctive, high-quality app icon that communicates the app's brand and purpose at a glance on the home screen. Currently no custom icon exists (using the default placeholder).

**Why this priority**: The app icon is the first visual touchpoint before even opening the app. It is part of the overall beautification effort and essential for a polished App Store presence.

**Independent Test**: Build the app and view the home screen — verify a custom app icon appears (not the default Xcode placeholder), at all required sizes.

**Acceptance Scenarios**:

1. **Given** the app is installed on a device, **When** the user views the home screen, **Then** a custom app icon representing the "daily" brand is displayed.
2. **Given** the user views the app on the App Store or in Settings, **Then** the same icon appears consistently across all contexts and sizes.
3. **Given** the icon is viewed in both Light and Dark appearance contexts on iOS 18+ (adaptive icons), **Then** the icon looks intentional and polished in both.

---

- **FR-012**: The app MUST have a custom app icon replacing the default Xcode placeholder, provided at all required iOS icon sizes.
- **FR-013**: The app icon MUST visually communicate the app's purpose (daily movement/wellness) and complement the app's design language.
- **SC-007**: A custom app icon appears on the device home screen and in Settings after installation — verifiable by installing the app on a device or simulator.

## Assumptions

- The existing `LiquidGlass` component on the Dashboard defines the visual direction for the app — the beautification should extend and refine this direction, not replace it with a different aesthetic.
- The app targets iOS 17+ (given SwiftData usage), so modern SwiftUI APIs and visual effects are available.
- No new third-party dependencies are introduced — all visual effects use system frameworks (SwiftUI, UIKit) only.
- Performance on older devices (iPhone SE 2nd gen minimum) must not degrade noticeably from the changes.
- The `ScaleButtonStyle` already implemented is the correct direction for micro-interactions and should be applied universally.
