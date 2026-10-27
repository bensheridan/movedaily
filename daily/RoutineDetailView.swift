import SwiftUI
import SwiftData

// MARK: - Routine Detail View

struct RoutineDetailView: View {
    let routine: Routine
    let allExercises: [Exercise]
    let profile: UserProfile?
    var routineCompleted: (() -> Void)? = nil

    @State private var currentExerciseIndex = 0
    @State private var showingExercise = false
    @Environment(\.isUnfolded) private var isUnfolded
    @Environment(\.horizontalSizeClass) private var sizeClass

    var routineExercises: [Exercise] {
        routine.exerciseNames.compactMap { name in
            allExercises.first { exercise in
                exercise.name == name && (exercise.genderFocus == nil || exercise.genderFocus == profile?.gender)
            }
        }
    }

    var isCompleted: Bool {
        currentExerciseIndex >= routineExercises.count && !routineExercises.isEmpty
    }

    var actionTitle: String {
        if currentExerciseIndex == 0 { return "Start Routine" }
        if isCompleted { return "Restart Routine" }
        return "Continue Routine"
    }

    /// Restores today's progress so a routine can be finished in pieces through the day.
    private func restoreProgress() {
        let done = RoutineProgressStore.completedToday(for: routine.name)
        currentExerciseIndex = routineExercises.prefix { done.contains($0.name) }.count
    }

    private func saveProgress() {
        RoutineProgressStore.save(
            completed: routineExercises.prefix(currentExerciseIndex).map(\.name),
            for: routine.name
        )
    }

    var body: some View {
        Group {
            if isUnfolded {
                // Inner screen: the exercise list beside a preview of the exercise that's up next.
                SideBySide(leadingWidth: 380) {
                    ScrollView {
                        LazyVStack(spacing: DesignTokens.sectionSpacing) {
                            headerCard
                            exerciseList
                            Color.clear.frame(height: 80)
                        }
                        .padding(DesignTokens.cardPadding)
                    }
                } trailing: {
                    ScrollView {
                        upNextPanel
                            .padding(DesignTokens.cardPadding)
                        Color.clear.frame(height: 80)
                    }
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: DesignTokens.sectionSpacing) {
                        headerCard
                        exerciseList

                        // Bottom spacer to prevent content hiding behind sticky button
                        Color.clear.frame(height: 80)
                    }
                    .padding(DesignTokens.cardPadding)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                if isCompleted {
                    Button("Reset & Start Over") {
                        currentExerciseIndex = 0
                        saveProgress()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Button(action: { showingExercise = true }) {
                    Text(actionTitle)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            isCompleted
                                ? Color.green
                                : Color.blue
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius, style: .continuous))
                }
                .buttonStyle(DesignTokens.scaleButton)
                .disabled(isCompleted)
            }
            .padding(DesignTokens.cardPadding)
            .background(.ultraThinMaterial)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(routine.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { restoreProgress() }
        .sheet(isPresented: $showingExercise) {
            if currentExerciseIndex < routineExercises.count {
                NavigationStack {
                    ExerciseDetailView(exercise: routineExercises[currentExerciseIndex])
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Finish") {
                                    currentExerciseIndex += 1
                                    saveProgress()
                                    if currentExerciseIndex == routineExercises.count {
                                        routineCompleted?()
                                    }
                                    showingExercise = false
                                }
                            }
                        }
                }
                // From the real size class: this view may sit in a narrow pane that overrides isUnfolded.
                .environment(\.isUnfolded, sizeClass == .regular)
                // Only affects regular width: a roomy sheet so the timer can sit beside the instructions.
                .presentationSizing(.page)
            }
        }
    }

    // MARK: Sections

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(routine.name)
                .font(.largeTitle)
                .fontWeight(.bold)
            Text(routine.routineDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if currentExerciseIndex > 0 && !isCompleted {
                Label("\(currentExerciseIndex) of \(routineExercises.count) done today — pick up any time", systemImage: "clock.arrow.circlepath")
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .padding(.top, 2)
            }
            if routine.isFocusProgram {
                HealthNotice(text: HealthDisclaimer.focusProgram)
                    .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.cardPadding)
        .cardStyle()
    }

    private var exerciseList: some View {
        VStack(spacing: 10) {
            Text("Exercises")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(0..<routineExercises.count, id: \.self) { index in
                ExerciseProgressCard(
                    index: index,
                    exercise: routineExercises[index],
                    currentIndex: currentExerciseIndex
                ) {
                    if index == currentExerciseIndex {
                        showingExercise = true
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var upNextPanel: some View {
        if currentExerciseIndex < routineExercises.count {
            UpNextPanel(
                exercise: routineExercises[currentExerciseIndex],
                position: currentExerciseIndex + 1,
                total: routineExercises.count
            )
        } else if isCompleted {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)
                Text("Routine complete — great work!")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 80)
        }
    }
}

// MARK: - Up Next Panel

/// The unfolded routine screen's preview of the next exercise: what it is and how to do it.
struct UpNextPanel: View {
    let exercise: Exercise
    let position: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.sectionSpacing) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Up next · \(position) of \(total)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
                Text(exercise.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                HStack(spacing: 8) {
                    DifficultyBadge(difficulty: exercise.difficulty)
                    Label(durationText, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !exercise.exerciseDescription.isEmpty {
                    Text(exercise.exerciseDescription)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }

            if !exercise.instructions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Instructions")
                        .font(.title2)
                        .fontWeight(.bold)
                    ForEach(0..<exercise.instructions.count, id: \.self) { index in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1).")
                                .fontWeight(.bold)
                                .foregroundStyle(.blue)
                            Text(exercise.instructions[index])
                        }
                    }
                }
                .padding(DesignTokens.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
            }

            if !exercise.tips.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Safety & Form")
                        .font(.headline)
                    ForEach(exercise.tips, id: \.self) { tip in
                        Label(tip, systemImage: "checkmark.shield.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(DesignTokens.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
            }
        }
    }

    private var durationText: String {
        let mins = exercise.durationSeconds / 60
        return mins > 0 ? "\(mins) min" : "\(exercise.durationSeconds) sec"
    }
}

// MARK: - Routine Progress Store

/// Remembers which exercises of each routine were finished today (UserDefaults, keyed by
/// routine name). Progress from an earlier day is ignored, so routines start fresh each day.
enum RoutineProgressStore {
    private struct Entry: Codable {
        var day: Date
        var completed: [String]
    }

    private static func key(_ routineName: String) -> String { "routineProgress.\(routineName)" }

    static func completedToday(for routineName: String) -> Set<String> {
        guard let data = UserDefaults.standard.data(forKey: key(routineName)),
              let entry = try? JSONDecoder().decode(Entry.self, from: data),
              Calendar.current.isDateInToday(entry.day) else { return [] }
        return Set(entry.completed)
    }

    static func save(completed: [String], for routineName: String) {
        let entry = Entry(day: Date(), completed: completed)
        if let data = try? JSONEncoder().encode(entry) {
            UserDefaults.standard.set(data, forKey: key(routineName))
        }
    }
}

// MARK: - Exercise Progress Card

struct ExerciseProgressCard: View {
    let index: Int
    let exercise: Exercise
    let currentIndex: Int
    let onTap: () -> Void

    var isCompleted: Bool { index < currentIndex }
    var isCurrent: Bool { index == currentIndex }

    /// Shows "20 sets" or "30 sec" for plan-imported exercises; falls back to "X min" for timed library exercises.
    var durationLabel: String {
        let desc = exercise.exerciseDescription.trimmingCharacters(in: .whitespaces)
        if desc.range(of: #"^\d+\s*(sets?|sec)$"#, options: [.regularExpression, .caseInsensitive]) != nil {
            return desc
        }
        let mins = exercise.durationSeconds / 60
        return mins > 0 ? "\(mins) min" : "\(exercise.durationSeconds) sec"
    }

    var body: some View {
        HStack(spacing: 14) {
            // Step indicator
            ZStack {
                Circle()
                    .fill(indicatorColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.green)
                } else if isCurrent {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.blue)
                } else {
                    Text("\(index + 1)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
            }

            // Exercise info
            VStack(alignment: .leading, spacing: 3) {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundStyle(isCurrent ? .primary : (isCompleted ? .secondary : .primary))
                Text(durationLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isCurrent {
                Text("Tap to start")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
        .padding(DesignTokens.cardPadding)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius, style: .continuous)
                .stroke(borderColor, lineWidth: isCurrent ? 1.5 : 0.5)
        )
        .shadow(color: Color.black.opacity(isCompleted ? 0.03 : DesignTokens.cardShadowOpacity),
                radius: DesignTokens.cardShadowRadius,
                x: DesignTokens.cardShadowOffset.width,
                y: DesignTokens.cardShadowOffset.height)
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    private var indicatorColor: Color {
        if isCompleted { return .green }
        if isCurrent { return .blue }
        return .gray
    }

    private var cardBackground: some View {
        Group {
            if isCompleted {
                Color.green.opacity(0.07)
            } else if isCurrent {
                Color.blue.opacity(0.07)
            } else {
                Color(uiColor: .secondarySystemGroupedBackground)
            }
        }
    }

    private var borderColor: Color {
        if isCurrent { return .blue.opacity(0.4) }
        return Color(uiColor: .separator).opacity(0.5)
    }
}

// MARK: - Preview

#Preview("Up Next Panel") {
    ScrollView {
        UpNextPanel(
            exercise: Exercise(
                name: "Pendulum Swing",
                exerciseDescription: "Let the arm hang and swing gently",
                durationSeconds: 60,
                category: .stretching,
                instructions: ["Lean on a table with your good arm.", "Let the sore arm hang down.", "Swing it in small circles."],
                tips: ["Keep the shoulder relaxed."]
            ),
            position: 2,
            total: 5
        )
        .padding()
    }
    .modelContainer(for: Exercise.self, inMemory: true)
}

#Preview {
    NavigationView {
        RoutineDetailView(
            routine: Routine(name: "Morning Mobility", routineDescription: "Start the day right", exerciseNames: []),
            allExercises: [],
            profile: nil
        )
    }
    .modelContainer(for: [Routine.self, Exercise.self], inMemory: true)
}
