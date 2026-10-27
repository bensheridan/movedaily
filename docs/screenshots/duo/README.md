# iPhone Duo screenshots

Captured on the iPhone Duo simulator (iOS 27.1). The unfolded inner screen is 951×669 pt
(2853×2007 px); the folded cover screen is 466×678 pt (1398×2034 px).

| File | Screen |
| --- | --- |
| `00-dashboard-folded.png` | Dashboard on the cover screen (same layout as any iPhone) |
| `01-dashboard-unfolded.png` | Dashboard, two columns |
| `02-program-unfolded.png` | Program: exercise list beside "Up next" |
| `03-exercise-timer-unfolded.png` | Exercise timer beside instructions |
| `04-programs-unfolded.png` | All programs: list beside the selected program |

The simulator only accepts taps on the cover screen, so Debug builds take a
`-screenshotRoute programs|program|exercise` launch argument that opens those screens directly:

```bash
xcrun simctl launch <udid> com.bensheridan.movedaily -screenshotRoute program
```
