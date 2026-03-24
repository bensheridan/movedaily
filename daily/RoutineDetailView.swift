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
        .sheet(isPresented: $showingExercise) {
            if currentExerciseIndex < routineExercises.count {
                NavigationView {
                    ExerciseDetailView(exercise: routineExercises[currentExerciseIndex])
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                Button("Finish") {
                                    currentExerciseIndex += 1
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

// MARK: - Exercise Progress Card

struct ExerciseProgressCard: View {
    let index: Int
    let exercise: Exercise
    let currentIndex: Int
    let onTap: () -> Void

    var isCompleted: Bool { index < currentIndex }
    var isCurrent: Bool { index == currentIndex }

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
                Text("\(exercise.durationSeconds / 60) min")
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
