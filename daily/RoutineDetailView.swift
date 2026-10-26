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
        ScrollView {
            LazyVStack(spacing: DesignTokens.sectionSpacing) {
                // Header card
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
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(DesignTokens.cardPadding)
                .cardStyle()

                // Exercise list
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

                // Bottom spacer to prevent content hiding behind sticky button
                Color.clear.frame(height: 80)
            }
            .padding(DesignTokens.cardPadding)
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
                NavigationView {
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
            }
        }
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
