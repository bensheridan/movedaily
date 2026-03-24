# Tasks: App Beautification

**Input**: Design documents from `/specs/003-app-beautification/`
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ quickstart.md ✅

**Tests**: No tests requested — visual validation via Xcode Previews and manual device/simulator runs.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)

## Path Conventions

All Swift source files live flat in `daily/` (no subdirectories). Asset catalog at `daily/Assets.xcassets/`.

---

## Phase 1: Setup

**Purpose**: Confirm project is ready for the design system.

- [x] T001 Verify `daily/DesignSystem.swift` does not yet exist and that `daily/Assets.xcassets/AppIcon.appiconset/` is present in the project (look for it in `daily.xcodeproj`); note any missing directories before proceeding

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish the shared design system and fix the LiquidGlass light-mode bug. MUST complete before any user story begins.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T002 Create `daily/DesignSystem.swift` — define `struct DesignTokens` with static constants: `cardCornerRadius: CGFloat = 20`, `cardShadowRadius: CGFloat = 8`, `cardShadowOpacity: Double = 0.08`, `cardShadowOffset: CGSize = CGSize(width: 0, height: 4)`, `cardPadding: CGFloat = 16`, `sectionSpacing: CGFloat = 20`, `gridSpacing: CGFloat = 15`
- [x] T003 Add `CardModifier: ViewModifier` to `daily/DesignSystem.swift` — applies `.regularMaterial` background, a `RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius)` clip shape, a `.stroke(Color.separator, lineWidth: 0.5)` overlay, and a `.shadow(color: .black.opacity(DesignTokens.cardShadowOpacity), radius: DesignTokens.cardShadowRadius, x: DesignTokens.cardShadowOffset.width, y: DesignTokens.cardShadowOffset.height)` modifier; add `extension View { func cardStyle() -> some View { modifier(CardModifier()) } }`
- [x] T004 Move `ScaleButtonStyle` from `daily/ContentView.swift` into `daily/DesignSystem.swift`; add `extension DesignTokens { static let scaleButton = ScaleButtonStyle() }`; add a `#Preview` block in `daily/DesignSystem.swift` showing a `.cardStyle()` card and a button with `.buttonStyle(DesignTokens.scaleButton)`
- [x] T005 Fix `LiquidGlass` in `daily/ContentView.swift`: update the `LinearGradient` overlay to use neutral opacity values that read well in Light Mode (e.g., `Color.white.opacity(0.12)` at rest, `Color.white.opacity(0.18)` animated, `Color.blue.opacity(0.08)`); remove `.environment(\.colorScheme, .dark)` from both `DailyRoutineCard` and `CategoryCard`; verify the `#Preview` at the bottom of `ContentView.swift` looks correct in both Light and Dark mode canvas

**Checkpoint**: `DesignSystem.swift` compiles, LiquidGlass works in both modes, `ScaleButtonStyle` is no longer defined in `ContentView.swift` — all user stories can now begin.

---

## Phase 3: User Story 1 — Consistent Visual Identity (Priority: P1) 🎯 MVP

**Goal**: All 6 screens share the same card style, typography scale, and interactive feedback — Dashboard, Onboarding, Routine Detail, Exercise List, Exercise Detail, and Profile.

**Independent Test**: Navigate every screen in both Light Mode and Dark Mode; every content card must have rounded corners (~20pt), subtle shadow, and `.regularMaterial` background; no screen uses plain `List` rows or `Form` cells for content display; all buttons scale on press.

### Implementation for User Story 1

- [x] T006 [P] [US1] Update `DashboardView` in `daily/ContentView.swift`: in the `LazyVGrid` `ForEach`, replace `.buttonStyle(ScaleButtonStyle())` with `.buttonStyle(DesignTokens.scaleButton)` on the `NavigationLink` wrapping `CategoryCard`; do the same for the `NavigationLink` wrapping `DailyRoutineCard`
- [x] T007 [P] [US1] Update `StatsView` in `daily/ContentView.swift`: wrap the `HStack(spacing: 20)` containing all `StatItem` views in a `VStack` and apply `.cardStyle()` to it; update `StatItem` to use `DesignTokens.cardPadding` for its internal `.padding()` and remove its standalone `.background(Color(uiColor: .secondarySystemBackground)).cornerRadius(15).shadow(...)` — the shared card style handles this
- [x] T008 [US1] Rewrite `RoutineDetailView.body` in `daily/RoutineDetailView.swift`: replace the outer `VStack { ... List { Section { ... } } ... Button ... }` with `ZStack(alignment: .bottom) { ScrollView { LazyVStack(spacing: DesignTokens.sectionSpacing) { ... } .padding() } }` containing the title block and the exercise cards; the action button moves to a `.safeAreaInset(edge: .bottom)` block (see T010)
- [x] T009 [US1] Add `ExerciseProgressCard` view inline in `daily/RoutineDetailView.swift`: accepts `index: Int`, `exercise: Exercise`, `currentIndex: Int`; shows step number, name (`.headline`), duration (`.caption`), and trailing checkmark/play icon matching existing logic; background tint: `.green.opacity(0.08)` if `index < currentIndex`, `.blue.opacity(0.08)` if `index == currentIndex`, `.clear` if upcoming; apply `.cardStyle()` to the card container; make the card tappable (`onTapGesture`) to start the exercise when `index == currentIndex`
- [x] T010 [US1] In `daily/RoutineDetailView.swift`, add `.safeAreaInset(edge: .bottom)` to the `ScrollView`: inside, render the Start/Continue/Restart `Button` with `.frame(maxWidth: .infinity)`, `.buttonStyle(.borderedProminent)`, and `.buttonStyle(DesignTokens.scaleButton)`; show the "Complete & Reset" link when all exercises are done; add a light `.ultraThinMaterial` background to the inset bar for visual separation
- [x] T011 [P] [US1] Replace `Form { ... }` in `daily/ProfileView.swift` with `ScrollView { VStack(alignment: .leading, spacing: DesignTokens.sectionSpacing) { ... } .padding() }`; keep all existing state variables, bindings, and business logic intact — only the layout container changes
- [x] T012 [US1] Add profile hero card at the top of the `ScrollView` in `daily/ProfileView.swift`: `VStack(spacing: 12)` containing the existing profile photo logic (UIImage or SF Symbol placeholder) + a "Edit" button styled with `.buttonStyle(DesignTokens.scaleButton)` + gender label + an `HStack` with three inline stat chips (streak, level, XP) using icon + value + label each; wrap the whole block in `.cardStyle()`
- [x] T013 [US1] Add reminders section card in `daily/ProfileView.swift`: a `VStack(alignment: .leading, spacing: 12)` with a section title ("Reminders", `.headline`) + the existing `Toggle("Enable Reminder", isOn: $reminderEnabled)` + the existing `DatePicker` with its `.disabled(!reminderEnabled)` and `.onChange` handlers; wrap in `.cardStyle()`; preserve all existing notification scheduling logic
- [x] T014 [US1] Add reset section card in `daily/ProfileView.swift`: a `VStack(alignment: .leading, spacing: 12)` with the existing destructive `Button(role: .destructive)` reset button; wrap in `.cardStyle()`; preserve existing `.alert` presentation
- [x] T015 [US1] Update `#Preview` in `daily/RoutineDetailView.swift` to use `inMemory: true` model container; update `#Preview` in `daily/ProfileView.swift` to include a `NavigationStack` wrapper so the navigation title renders in preview

**Checkpoint**: At this point, Dashboard, Routine Detail, and Profile all visually match — same card style, same typography, same button animations.

---

## Phase 4: User Story 2 — Engaging Onboarding (Priority: P2)

**Goal**: First-time users see a branded, visually polished onboarding screen with a hero section and styled selection buttons.

**Independent Test**: Delete app data (or install fresh), launch app, see hero section with icon + tagline above the gender buttons; gender buttons have card styling and scale on press.

### Implementation for User Story 2

- [x] T016 [P] [US2] Add hero section to `OnboardingView` in `daily/OnboardingView.swift`: above the gender buttons `VStack`, add a `VStack(spacing: 16)` containing: (a) a `ZStack` with a `Circle().fill(LinearGradient(colors: [.blue, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(width: 120, height: 120)` and `Image(systemName: "figure.run").font(.system(size: 50)).foregroundStyle(.white)` centered inside; (b) `Text("Daily")` in `.largeTitle` + `.bold`; (c) `Text("Move a little every day.")` in `.subheadline` + `.foregroundStyle(.secondary)` + `.multilineTextAlignment(.center)`; remove the existing standalone `Text("Welcome to Daily")` and `Text("Select your gender...")` which are superseded by the hero
- [x] T017 [US2] Update `GenderButton` in `daily/OnboardingView.swift`: remove the `.background(color.opacity(0.1)).foregroundColor(color).cornerRadius(15).overlay(RoundedRectangle(cornerRadius: 15).stroke(color, lineWidth: 2))` styling; replace with `.cardStyle()` on the `HStack` container; foreground color becomes `.primary`; add a leading colored circle indicator `Circle().fill(color).frame(width: 12, height: 12)` before the icon; apply `.buttonStyle(DesignTokens.scaleButton)` to the outer `Button`
- [x] T018 [US2] Update `#Preview` in `daily/OnboardingView.swift` to verify the hero section and styled buttons render at the correct scale in the canvas

**Checkpoint**: Onboarding visually matches the app's design language and passes the independent test.

---

## Phase 5: User Story 5 — App Icon (Priority: P2)

**Goal**: A custom app icon appears on the home screen, Spotlight, and Settings — replacing the Xcode default placeholder.

**Independent Test**: Build and run the app on a Simulator (⌘R), press the Home button — a custom icon appears (not the grey default grid); also check Settings → scroll to the app.

### Implementation for User Story 5

*Note: Phase 5 can run in parallel with Phase 4 — no shared files.*

- [x] T019 [P] [US5] Create `daily/AppIconView.swift`: define `struct AppIconView: View` that renders the icon design — a `ZStack` with `LinearGradient(colors: [Color(red: 0.2, green: 0.5, blue: 1.0), Color(red: 0.3, green: 0.2, blue: 0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)` filling the full frame, then `Image(systemName: "figure.run").font(.system(size: 100, weight: .bold)).foregroundStyle(.white).shadow(color: .black.opacity(0.2), radius: 4)` centered; add a `#Preview` at 1024×1024 using `.previewLayout(.fixed(width: 1024, height: 1024))`
- [x] T020 [P] [US5] Create `tools/generate-icons.swift` (a standalone macOS Swift script): import Foundation + SwiftUI; use `ImageRenderer` to render `AppIconView()` at sizes `[1024, 180, 120, 87, 80, 58]`; for each size, set `renderer.proposedSize = ProposedViewSize(width: CGFloat(size), height: CGFloat(size))`; save the rendered `NSImage` (macOS) as PNG to `daily/Assets.xcassets/AppIcon.appiconset/AppIcon-\(size).png`; run this script with `swift tools/generate-icons.swift` from the repo root to produce all PNG files
- [x] T021 [US5] Create/replace `daily/Assets.xcassets/AppIcon.appiconset/Contents.json` with a valid JSON structure listing all icon entries: `{"images": [{"filename":"AppIcon-1024.png","idiom":"universal","platform":"ios","size":"1024x1024"}, {"filename":"AppIcon-180.png","idiom":"iphone","scale":"3x","size":"60x60"}, {"filename":"AppIcon-120.png","idiom":"iphone","scale":"2x","size":"60x60"}, {"filename":"AppIcon-120.png","idiom":"iphone","scale":"3x","size":"40x40"}, {"filename":"AppIcon-80.png","idiom":"iphone","scale":"2x","size":"40x40"}, {"filename":"AppIcon-87.png","idiom":"iphone","scale":"3x","size":"29x29"}, {"filename":"AppIcon-58.png","idiom":"iphone","scale":"2x","size":"29x29"}], "info": {"author":"xcode","version":1}}`; build the project and verify no Xcode warnings about missing icon files

**Checkpoint**: App icon appears on Simulator home screen and in Settings.

---

## Phase 6: User Story 3 — Polished Exercise List and Detail Views (Priority: P3)

**Goal**: Exercise list cells show icon, name, difficulty badge, and duration; detail view has styled cards for instructions/tips and a visual completion state on the timer.

**Independent Test**: Navigate to any category → see rich exercise cards with difficulty badge + duration; tap an exercise → timer circle present; let timer run to zero → circle turns green; tip/instruction sections use card style.

### Implementation for User Story 3

- [x] T022 [P] [US3] Rewrite `ExerciseListView.body` in `daily/ExerciseListView.swift`: replace `List(exercises) { exercise in NavigationLink(...) }` with `ScrollView { LazyVStack(spacing: DesignTokens.gridSpacing) { ForEach(exercises) { exercise in NavigationLink(destination: ExerciseDetailView(exercise: exercise)) { ExerciseRowCard(exercise: exercise, category: category) }.buttonStyle(PlainButtonStyle()) } } .padding() }`; add `if exercises.isEmpty { ExerciseEmptyState() }` before the `ScrollView`
- [x] T023 [P] [US3] Add `ExerciseRowCard` view inline in `daily/ExerciseListView.swift`: `HStack(spacing: 12)` with (a) `ZStack { Circle().fill(Color.blue.opacity(0.12)).frame(width: 44, height: 44); Image(systemName: category.icon).font(.system(size: 20)).foregroundStyle(.blue) }`; (b) `VStack(alignment: .leading, spacing: 4) { Text(exercise.name).font(.headline); Text(exercise.exerciseDescription).font(.subheadline).foregroundStyle(.secondary).lineLimit(2) }`; (c) `Spacer()`; (d) `VStack(alignment: .trailing, spacing: 4) { DifficultyBadge(difficulty: exercise.difficulty); Text("\(exercise.durationSeconds / 60)m").font(.caption).foregroundStyle(.secondary) }`; apply `.padding(DesignTokens.cardPadding).cardStyle()` to the outer `HStack`
- [x] T024 [US3] Add `DifficultyBadge` view inline in `daily/ExerciseListView.swift`: accepts `difficulty: Difficulty`; renders `Text(difficulty.rawValue).font(.caption).fontWeight(.medium).padding(.horizontal, 6).padding(.vertical, 3).background(badgeColor.opacity(0.15)).foregroundStyle(badgeColor).clipShape(Capsule())`; `badgeColor` is `.green` for `.beginner`, `.orange` for `.intermediate`, `.red` for `.advanced`
- [x] T025 [US3] Add `ExerciseEmptyState` view inline in `daily/ExerciseListView.swift`: `VStack(spacing: 16) { Image(systemName: "figure.walk.circle").font(.system(size: 60)).foregroundStyle(.secondary); Text("No exercises available").font(.headline); Text("This category has no exercises for your current profile.").font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center) }.frame(maxWidth: .infinity, maxHeight: .infinity).padding()`
- [x] T026 [US3] In `ExerciseDetailView` in `daily/ExerciseListView.swift`, update the Instructions `VStack` container: replace `.background(Color(.secondarySystemBackground)).cornerRadius(15)` with `.cardStyle()`; keep the padding already present on the container
- [x] T027 [US3] In `ExerciseDetailView` in `daily/ExerciseListView.swift`, update the Safety & Form `VStack` container: replace `.background(Color(.secondarySystemBackground)).cornerRadius(15)` with `.cardStyle()`
- [x] T028 [US3] Add timer completion visual in `daily/ExerciseListView.swift` `TimerCircle`: add a `timerCompleted: Bool` parameter (default `false`); in the progress `Circle().trim(...)` stroke, change `.foregroundColor(.blue)` to `.foregroundColor(timerCompleted ? .green : .blue).animation(.easeInOut(duration: 0.5), value: timerCompleted)`; in the background `Circle().stroke(...)`, do the same; in `ExerciseDetailView`, pass `.init(timeRemaining: timeRemaining, totalTime: exercise.durationSeconds, timerCompleted: timerCompleted)` to `TimerCircle`
- [x] T029 [US3] Update `#Preview` blocks in `daily/ExerciseListView.swift` to show both a populated list and the empty state (add a second `#Preview` with `exercises = []` using an in-memory model container with no seeded data for the selected category)

**Checkpoint**: Exercise list shows rich cards; timer turns green on completion; instruction/tip sections use card style.

---

## Phase 7: User Story 4 — Micro-Interactions (Priority: P4)

**Goal**: Every interactive button in the app responds to tap with a scale animation; stats in the profile hero animate on update.

**Independent Test**: Tap every button across all screens — each scales down ~4% on press; change XP/streak by completing a routine and returning to profile — numbers animate to new values.

### Implementation for User Story 4

- [x] T030 [P] [US4] Audit all `Button` elements in `daily/ExerciseListView.swift` (Start/Pause, Reset, audio toggle) and apply `.buttonStyle(DesignTokens.scaleButton)` to any that don't already have it; apply the same to the Finish button toolbar item in `RoutineDetailView.swift` (note: toolbar buttons don't support custom `ButtonStyle` — skip and leave as-is if not applicable)
- [x] T031 [P] [US4] Apply `.buttonStyle(DesignTokens.scaleButton)` to the "Edit" photo button in the profile hero card in `daily/ProfileView.swift`; apply it to the Reset Profile destructive button too (note: `role: .destructive` buttons can coexist with a `ButtonStyle` — the role only affects color, not the style)
- [x] T032 [US4] Add `.contentTransition(.numericText())` to the XP value `Text`, streak value `Text`, and level value `Text` inside the profile hero card in `daily/ProfileView.swift` so that number changes animate smoothly when the view updates after a routine completion

**Checkpoint**: All interactive elements across all 6 screens have consistent tap animation feedback.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and cleanup across all modified files.

- [x] T033 [P] Open `daily.xcodeproj` in Xcode and build (⌘B) — resolve any compile errors introduced by the refactoring (common issues: `ScaleButtonStyle` reference in `ContentView.swift` after move to `DesignSystem.swift`, `TimerCircle` call sites needing the new `timerCompleted` parameter)
- [x] T034 [P] Run the app on an iPhone 15 simulator: navigate all 6 screens in Light Mode, then switch to Dark Mode (Settings → Display & Brightness) and repeat — verify card backgrounds adapt correctly, no text is illegible, and `.dark` environment override is gone
- [x] T035 Verify `#Preview` blocks exist in all modified files: `DesignSystem.swift`, `ContentView.swift`, `OnboardingView.swift`, `RoutineDetailView.swift`, `ExerciseListView.swift`, `ProfileView.swift`; add any missing `#Preview` blocks per Constitution Principle I

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Phase 2 completion — Dashboard + Routine Detail + Profile
- **US2 (Phase 4)**: Depends on Phase 2 completion — can run in parallel with Phase 3
- **US5 (Phase 5)**: Depends on Phase 2 completion — can run in parallel with Phases 3 & 4
- **US3 (Phase 6)**: Depends on Phase 2 completion — can run in parallel with Phases 3, 4, 5
- **US4 (Phase 7)**: Depends on Phases 3–6 completion (auditing all modified views)
- **Polish (Phase 8)**: Depends on all prior phases

### User Story Dependencies

- **US1 (P1)**: No dependency on other stories — start after Phase 2
- **US2 (P2)**: No dependency on US1 — start after Phase 2
- **US5 App Icon (P2)**: No dependency on any story — start after Phase 2
- **US3 (P3)**: No dependency on US1/US2 — start after Phase 2
- **US4 (P4)**: Depends on all prior stories (audits their buttons)

### Within Each User Story

- Tasks marked `[P]` touch different files and can be done in parallel
- Within a screen refactor: outer container change → inner component additions → `#Preview` update

### Parallel Opportunities

- T006, T007 (`ContentView.swift`) — same file, do sequentially
- T008–T010 (`RoutineDetailView.swift`) — same file, do sequentially
- T011–T014 (`ProfileView.swift`) — same file, do sequentially
- T016–T018 (`OnboardingView.swift`) — same file, do sequentially
- T019–T021 (App Icon) — can all run in parallel with Phase 3 & 4 (different files)
- T022–T029 (`ExerciseListView.swift`) — same file, do sequentially
- T033, T034, T035 — independent validations, can run in parallel

---

## Parallel Example: Phase 3 + Phase 5

```text
After Phase 2 completes:

Thread A (US1):
  T006 → T007 → T008 → T009 → T010 → T011 → T012 → T013 → T014 → T015

Thread B (US2):
  T016 → T017 → T018

Thread C (US5 - App Icon):
  T019 → T020 → T021
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational (T002–T005) — CRITICAL
3. Complete Phase 3: User Story 1 (T006–T015)
4. **STOP and VALIDATE**: Navigate all 6 screens in Light + Dark Mode, confirm visual consistency
5. The app is now visually cohesive — Phases 4–7 add incremental polish

### Incremental Delivery

1. Phase 2 → Foundation ready (DesignSystem + LiquidGlass fix)
2. Phase 3 → US1 MVP: consistent visual identity on main screens
3. Phase 4 → US2: polished onboarding (first impression improved)
4. Phase 5 → US5: custom app icon (visible on home screen)
5. Phase 6 → US3: rich exercise browsing and workout experience
6. Phase 7 → US4: micro-interaction polish everywhere
7. Phase 8 → Final validation and cleanup

### Parallel Strategy (Single Developer)

Complete phases sequentially in priority order. Each phase produces a fully working, testable increment before the next begins.

---

## Notes

- `[P]` tasks operate on different files and can be done concurrently if desired
- `[Story]` label maps each task to its user story for traceability
- Commit after each phase checkpoint (or after each logical group of tasks)
- **Do NOT** use `sed`/`awk` to modify Swift files — use targeted Edit tool calls with exact old/new strings
- **Do NOT** add `.environment(\.colorScheme, .dark)` anywhere in the new code
- All new `View` types MUST have a `#Preview` block (Constitution Principle I)
- No new `@Model` types needed — no SwiftData schema changes required
