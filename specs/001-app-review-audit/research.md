# Research: App Review & Bug Fix Audit

**Branch**: `001-app-review-audit`
**Phase**: 0 — Research
**Date**: 2026-03-24

All five bugs were identified by reading every Swift source file. Each section
below documents what was found, the decision taken, and the alternatives
considered.

---

## Bug 1 — Duplicate completeRoutine() shadows correct implementation

### Finding

`ContentView.swift` defines an extension on `UserProfile` with signature
`func completeRoutine()` (no parameters). `Models.swift` defines the correct
implementation with signature `func completeRoutine(baseXP: Int = 20)`.

In Swift, when a call site invokes `profile?.completeRoutine()`, the compiler
resolves to the exact-match no-parameter overload in `ContentView.swift` rather
than the default-parameter overload in `Models.swift`. The `ContentView.swift`
version:

- Does not check whether the user already exercised today (can award duplicate XP)
- Does not reset the streak when a day is missed (streak always increments)
- Does not award milestone bonus XP (7/30/100-day streaks)
- Uses a single `if` for level-up instead of a `while` loop (may under-level on large XP gains)

The correct implementation in `Models.swift` handles all of these cases.

### Decision

Remove the `extension UserProfile { func completeRoutine() { ... } }` block
from `ContentView.swift` entirely. After removal, `profile?.completeRoutine()`
resolves to `completeRoutine(baseXP: 20)` in `Models.swift` via the default
parameter — no call-site changes needed.

### Alternatives Considered

- **Rename the Models.swift method** — rejected; would require updating all
  callers and the model's public API unnecessarily.
- **Add a redirect in the ContentView extension** — rejected; redundant indirection
  with no benefit.

---

## Bug 2 — Timer fires completion feedback on every tick after reaching zero

### Finding

`ExerciseDetailView` in `ExerciseListView.swift` has a 1-second timer and this
`onReceive` handler:

```
if timerActive && timeRemaining > 0 {
    timeRemaining -= 1
    checkAudioCues()
} else if timeRemaining == 0 {
    timerActive = false
    // haptic fires here
    // TTS fires here
}
```

When `timeRemaining` reaches zero, `timerActive` is set to `false` but the
timer is never cancelled. On every subsequent tick the `else if timeRemaining == 0`
branch is taken, re-firing the haptic and TTS indefinitely.

### Decision

Add a `@State private var timerCompleted = false` flag. Set it to `true`
the first time zero is reached. Guard the completion branch with
`&& !timerCompleted`. Reset it to `false` along with `timeRemaining` when the
reset button is pressed.

This is the minimum change — one new state variable and two uses of it.

### Alternatives Considered

- **Cancel the Combine timer publisher** — requires converting the `let timer`
  constant to a `@State var cancellable` and managing `AnyCancellable`
  lifecycle. More complex than a boolean guard and not necessary since
  `autoconnect()` publishers cancel on view disappearance anyway.
- **Change the else-if condition to `timeRemaining == 0 && timerActive`** —
  rejected; after the first tick `timerActive` is already `false`, so the
  condition would never be true and the completion feedback would never fire.

---

## Bug 3 — Button styling applied to label content, not to Button

### Finding

In `ExerciseDetailView`, two buttons apply `.buttonStyle()` inside the label
closure rather than on the Button itself:

```swift
Button(action: { ... }) {
    Label(...)
        .buttonStyle(.borderedProminent)  // ← no effect here
}
```

When a view modifier is applied inside a Button's label, SwiftUI ignores it
(`.buttonStyle` is a view preference that propagates up, not down). The
buttons render as plain unstyled text/images.

### Decision

Move `.buttonStyle()` and `.tint()` to be modifiers on the `Button` itself
(outside the label closure). This is the standard SwiftUI pattern.

---

## Bug 4 — ProfileView has redundant NavigationView and editable Level/XP

### Finding

`daily/ProfileView.swift` wraps its `Form` in a `NavigationView { }`. The view
is presented via `NavigationLink` inside `DashboardView`, which already lives
inside a `NavigationView`. The result is nested navigation, producing:

- A duplicate navigation bar
- A "Close" dismiss button that does nothing (there is no modal to dismiss)
- Broken back-navigation behaviour

Additionally, the current ProfileView shows Level and XP as `Stepper` controls
(range 1–999 and 0–99 respectively), allowing users to manually override their
gamification progress.

### Decision

Replace `daily/ProfileView.swift` with the improved version found in
`daily.xcodeproj/ProfileView.swift`. That version:

- Has no inner `NavigationView` (correct for a nav-link destination)
- Shows Level, XP, and Streak as read-only `Text` values
- Supports gender picker, profile photo, reminder toggle, and reset profile

---

## Bug 5 — NotificationManager API signature mismatch

### Finding

`NotificationManager.scheduleDailyReminder` has signature:
```swift
func scheduleDailyReminder(at hour: Int, minute: Int)
```

The improved `ProfileView` (from `daily.xcodeproj/ProfileView.swift`) calls:
```swift
NotificationManager.shared.scheduleDailyReminder(at: reminderTime)
```
where `reminderTime` is a `String` in `"HH:mm"` format stored in `@AppStorage`.
This call does not compile against the existing signature.

Additionally, the improved ProfileView uses `PHPickerViewController` via
`PHPickerViewControllerDelegate` but does not `import PhotosUI`, which would
also prevent compilation.

### Decision

Add a convenience overload to `NotificationManager`:
```swift
func scheduleDailyReminder(at timeString: String)
```
This method parses the `"HH:mm"` string using `DateFormatter` and delegates
to the existing `(at hour: Int, minute: Int)` method. The existing method is
unchanged and remains callable by any future callers that already have
integers.

Add `import PhotosUI` to the new `ProfileView.swift`.

### Alternatives Considered

- **Change the existing method to accept a String** — rejected; the current
  integer-parameter signature is clean and explicit. Adding an overload is
  less disruptive.
- **Parse the string in ProfileView before calling** — viable, but pushes
  parsing responsibility into the UI layer. The convenience overload keeps
  that logic in NotificationManager where it belongs.

---

## Summary Table

| Bug | File(s) Affected | Change Type | Lines Estimated |
|-----|-----------------|-------------|-----------------|
| 1 — Duplicate completeRoutine | ContentView.swift | Delete ~20-line extension | −20 |
| 2 — Timer fires forever | ExerciseListView.swift | Add 1 state var + 2 guards | +4 |
| 3 — Button style in label | ExerciseListView.swift | Move modifiers outside label | ~6 |
| 4 — Nested NavView + steppers | ProfileView.swift | Replace file with better version | full replacement |
| 5 — NotificationManager mismatch | NotificationManager.swift, ProfileView.swift | Add overload + import | +10 |

Total scope: small, all in existing files.
