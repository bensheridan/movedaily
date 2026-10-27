import SwiftUI
import SwiftData

#if DEBUG
// MARK: - Screenshot Routes

/// Debug-only deep links for App Store screenshots, e.g. on the unfolded iPhone Duo where
/// the simulator can't be tapped. Launch with `-screenshotRoute programs|program|exercise`.
struct ScreenshotRouteModifier: ViewModifier {
    let allExercises: [Exercise]
    let profile: UserProfile?

    @Query private var routines: [Routine]
    @State private var isPresented = false

    private let route = UserDefaults.standard.string(forKey: "screenshotRoute")

    private var program: Routine? { Routine.sortedForDisplay(routines).first }

    func body(content: Content) -> some View {
        content
            .navigationDestination(isPresented: $isPresented) { destination }
            .task { if route != nil { isPresented = true } }
    }

    @ViewBuilder
    private var destination: some View {
        switch route {
        case "programs":
            ProgramsListView(allExercises: allExercises, profile: profile)
        case "program":
            if let program {
                RoutineDetailView(routine: program, allExercises: allExercises, profile: profile)
            }
        case "exercise":
            if let exercise = program?.programExercises(from: allExercises, profile: profile).first {
                ExerciseDetailView(exercise: exercise)
            }
        default:
            EmptyView()
        }
    }
}
#endif
