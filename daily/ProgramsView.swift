import SwiftUI
import SwiftData

// MARK: - Program Presentation

/// Display metadata for seeded routines, shown to the user as "Programs".
/// Focus-area programs are listed first; unknown routines fall back to a generic style.
extension Routine {
    private static let styles: [String: (icon: String, color: Color)] = [
        "Shoulder Mobility":      ("figure.arms.open", .orange),
        "Diaphragm Training":     ("lungs.fill", .teal),
        "Lower Back Mobility":    ("figure.flexibility", .indigo),
        "Morning Wake-Up":        ("sunrise.fill", .yellow),
        "Gentle Morning":         ("sun.horizon.fill", .yellow),
        "Desk Break":             ("desktopcomputer", .blue),
        "Relax & De-Stress":      ("moon.stars.fill", .purple),
        "Breathwork & Calm":      ("wind", .teal),
        "Deep Stretch":           ("figure.cooldown", .indigo),
        "Balance & Stability":    ("figure.stand", .mint),
        "Core & Mobility":        ("figure.core.training", .green),
        "Lower Body Burn":        ("figure.strengthtraining.functional", .red),
        "Upper Body Strength":    ("figure.strengthtraining.traditional", .red),
        "Full Body Strength":     ("figure.mixed.cardio", .red),
        "Power Circuit":          ("bolt.heart.fill", .pink),
    ]

    static let focusProgramNames = ["Shoulder Mobility", "Diaphragm Training", "Lower Back Mobility"]

    /// Earlier names of the focus-area programs, renamed on existing installs by `Exercise.seedInitialData`.
    static let renamedPrograms = [
        "Frozen Shoulder Relief": "Shoulder Mobility",
        "Reflux Breathing": "Diaphragm Training",
        "Lower Back Relief": "Lower Back Mobility",
    ]

    var programIcon: String { Self.styles[name]?.icon ?? "list.bullet.rectangle" }
    var programColor: Color { Self.styles[name]?.color ?? .blue }
    var isFocusProgram: Bool { Self.focusProgramNames.contains(name) }

    /// The exercises this routine will actually run for the given profile (matches RoutineDetailView).
    func programExercises(from allExercises: [Exercise], profile: UserProfile?) -> [Exercise] {
        exerciseNames.compactMap { name in
            allExercises.first { $0.name == name && ($0.genderFocus == nil || $0.genderFocus == profile?.gender) }
        }
    }

    /// Focus-area programs first (in their defined order), then the rest alphabetically.
    static func sortedForDisplay(_ routines: [Routine]) -> [Routine] {
        routines.sorted { a, b in
            let ia = focusProgramNames.firstIndex(of: a.name) ?? Int.max
            let ib = focusProgramNames.firstIndex(of: b.name) ?? Int.max
            return ia != ib ? ia < ib : a.name < b.name
        }
    }
}

// MARK: - Dashboard Section

struct ProgramsSection: View {
    let allExercises: [Exercise]
    let profile: UserProfile?
    var routineCompleted: (() -> Void)? = nil

    @Query private var routines: [Routine]

    private var sortedRoutines: [Routine] { Routine.sortedForDisplay(routines) }

    var body: some View {
        if !routines.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Programs")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    NavigationLink(destination: ProgramsListView(
                        allExercises: allExercises,
                        profile: profile,
                        routineCompleted: routineCompleted
                    )) {
                        Text("See all")
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(sortedRoutines) { routine in
                            NavigationLink(destination: RoutineDetailView(
                                routine: routine,
                                allExercises: allExercises,
                                profile: profile,
                                routineCompleted: routineCompleted
                            )) {
                                ProgramCard(
                                    routine: routine,
                                    exercises: routine.programExercises(from: allExercises, profile: profile)
                                )
                            }
                            .buttonStyle(DesignTokens.scaleButton)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

// MARK: - Program Card

struct ProgramCard: View {
    let routine: Routine
    let exercises: [Exercise]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Image(systemName: routine.programIcon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(routine.programColor.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                Spacer()
                if routine.isFocusProgram {
                    Text("Focus")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(routine.programColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(routine.programColor.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            Text(routine.name)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Text(routine.routineDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            ProgramMetaLabel(exercises: exercises)
        }
        .padding(DesignTokens.cardPadding)
        .frame(width: 200, height: 190, alignment: .topLeading)
        .cardStyle()
    }
}

struct ProgramMetaLabel: View {
    let exercises: [Exercise]

    private var minutes: Int {
        max(1, Int((Double(exercises.reduce(0) { $0 + $1.durationSeconds }) / 60).rounded()))
    }

    var body: some View {
        Label("\(exercises.count) exercise\(exercises.count == 1 ? "" : "s") · \(minutes) min", systemImage: "clock")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
    }
}

// MARK: - All Programs

struct ProgramsListView: View {
    let allExercises: [Exercise]
    let profile: UserProfile?
    var routineCompleted: (() -> Void)? = nil

    @Query private var routines: [Routine]
    @Environment(\.isUnfolded) private var isUnfolded
    @State private var selectedName: String?

    private var sorted: [Routine] { Routine.sortedForDisplay(routines) }

    private var selectedRoutine: Routine? {
        sorted.first { $0.name == selectedName } ?? sorted.first
    }

    var body: some View {
        Group {
            if isUnfolded {
                // Inner screen: program list beside the selected program.
                SideBySide {
                    List(selection: $selectedName) { sections }
                } trailing: {
                    if let routine = selectedRoutine {
                        detail(for: routine)
                            .id(routine.name)
                            // The detail pane is phone-width, so it keeps its single-column layout.
                            .environment(\.isUnfolded, false)
                    }
                }
                .onAppear { if selectedName == nil { selectedName = sorted.first?.name } }
            } else {
                List { sections }
            }
        }
        .navigationTitle("Programs")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var sections: some View {
        section("Focus areas", routines: sorted.filter(\.isFocusProgram))
        section("Workouts & routines", routines: sorted.filter { !$0.isFocusProgram })
    }

    private func detail(for routine: Routine) -> RoutineDetailView {
        RoutineDetailView(
            routine: routine,
            allExercises: allExercises,
            profile: profile,
            routineCompleted: routineCompleted
        )
    }

    @ViewBuilder
    private func section(_ title: String, routines: [Routine]) -> some View {
        if !routines.isEmpty {
            Section(title) {
                ForEach(routines) { routine in
                    if isUnfolded {
                        ProgramRow(routine: routine, allExercises: allExercises, profile: profile)
                            .tag(routine.name)
                    } else {
                        NavigationLink(destination: detail(for: routine)) {
                            ProgramRow(routine: routine, allExercises: allExercises, profile: profile)
                        }
                    }
                }
            }
        }
    }
}

struct ProgramRow: View {
    let routine: Routine
    let allExercises: [Exercise]
    let profile: UserProfile?

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: routine.programIcon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(routine.programColor.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(routine.name)
                    .font(.headline)
                Text(routine.routineDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ProgramMetaLabel(exercises: routine.programExercises(from: allExercises, profile: profile))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Previews

#Preview("Programs Section") {
    let container = try! ModelContainer(
        for: Routine.self, Exercise.self, UserProfile.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    Exercise.seedInitialData(context: container.mainContext)
    return NavigationStack {
        ScrollView {
            ProgramsSection(allExercises: [], profile: nil)
                .padding(.vertical)
        }
    }
    .modelContainer(container)
}

#Preview("Program Row") {
    List {
        ProgramRow(
            routine: Routine(name: "Shoulder Mobility", routineDescription: "Gentle stretches for a stiff shoulder", exerciseNames: []),
            allExercises: [],
            profile: nil
        )
    }
}

#Preview("All Programs") {
    let container = try! ModelContainer(
        for: Routine.self, Exercise.self, UserProfile.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    Exercise.seedInitialData(context: container.mainContext)
    return NavigationStack {
        ProgramsListView(allExercises: [], profile: nil)
    }
    .modelContainer(container)
}
