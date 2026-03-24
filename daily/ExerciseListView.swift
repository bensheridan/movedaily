import SwiftUI
import SwiftData
internal import Combine
import UIKit

// MARK: - Exercise List View

struct ExerciseListView: View {
    let category: ExerciseCategory
    let profile: UserProfile?

    @Query private var allExercises: [Exercise]

    var exercises: [Exercise] {
        allExercises.filter { exercise in
            exercise.category == category &&
            (exercise.genderFocus == nil || exercise.genderFocus == profile?.gender)
        }
    }

    var body: some View {
        Group {
            if exercises.isEmpty {
                ExerciseEmptyState()
            } else {
                ScrollView {
                    LazyVStack(spacing: DesignTokens.gridSpacing) {
                        ForEach(exercises) { exercise in
                            NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                                ExerciseRowCard(exercise: exercise, category: category)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(DesignTokens.cardPadding)
                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(category.rawValue)
    }
}

// MARK: - Exercise Row Card

struct ExerciseRowCard: View {
    let exercise: Exercise
    let category: ExerciseCategory

    var body: some View {
        HStack(spacing: 14) {
            // Category icon circle
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 46, height: 46)
                Image(systemName: category.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(.blue)
            }

            // Name + description
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(exercise.exerciseDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            // Metadata column
            VStack(alignment: .trailing, spacing: 6) {
                DifficultyBadge(difficulty: exercise.difficulty)
                Text("\(exercise.durationSeconds / 60)m")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(DesignTokens.cardPadding)
        .cardStyle()
    }
}

// MARK: - Difficulty Badge

struct DifficultyBadge: View {
    let difficulty: Difficulty

    var body: some View {
        Text(difficulty.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(badgeColor.opacity(0.15))
            .foregroundStyle(badgeColor)
            .clipShape(Capsule())
    }

    private var badgeColor: Color {
        switch difficulty {
        case .beginner:     return .green
        case .intermediate: return .orange
        case .advanced:     return .red
        }
    }
}

// MARK: - Empty State

struct ExerciseEmptyState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.walk.circle")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("No exercises available")
                .font(.headline)
            Text("This category has no exercises for your current profile.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Exercise Detail View

struct ExerciseDetailView: View {
    let exercise: Exercise
    @State private var timeRemaining: Int
    @State private var timerActive = false
    @State private var timerCompleted = false
    @State private var showingTips = false
    @State private var audioEnabled = true

    init(exercise: Exercise) {
        self.exercise = exercise
        _timeRemaining = State(initialValue: exercise.durationSeconds)
    }

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.sectionSpacing) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(exercise.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        DifficultyBadge(difficulty: exercise.difficulty)
                    }
                    Spacer()
                    Button(action: { audioEnabled.toggle() }) {
                        Image(systemName: audioEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.title2)
                            .foregroundStyle(audioEnabled ? .blue : .secondary)
                    }
                    .buttonStyle(DesignTokens.scaleButton)
                }

                // Timer
                TimerCircle(
                    timeRemaining: timeRemaining,
                    totalTime: exercise.durationSeconds,
                    timerCompleted: timerCompleted
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical)

                // Controls
                HStack(spacing: 12) {
                    Button(action: {
                        let isFreshStart = !timerActive && !timerCompleted && timeRemaining == exercise.durationSeconds
                        timerActive.toggle()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if isFreshStart && timerActive && audioEnabled {
                            TTSManager.shared.speak(exercise.name)
                            if let openingCue = exercise.audioCues[0] {
                                TTSManager.shared.queue(openingCue)
                            }
                        }
                    }) {
                        Label(timerActive ? "Pause" : "Start", systemImage: timerActive ? "pause.fill" : "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(timerCompleted ? .green : .blue)

                    Button(action: {
                        timeRemaining = exercise.durationSeconds
                        timerActive = false
                        timerCompleted = false
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        TTSManager.shared.stop()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .tint(.secondary)
                }

                // Completion banner
                if timerCompleted {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Exercise complete — great work!")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(DesignTokens.cardPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius, style: .continuous))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Instructions
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

                // Tips
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
            .padding(DesignTokens.cardPadding)
        }
        .onReceive(timer) { _ in
            if timerActive && timeRemaining > 0 {
                timeRemaining -= 1
                checkAudioCues()
            } else if timeRemaining == 0 && !timerCompleted {
                timerActive = false
                timerCompleted = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                if audioEnabled {
                    TTSManager.shared.speak("Exercise complete. Great job!")
                }
            }
        }
        .onDisappear {
            TTSManager.shared.stop()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !exercise.tips.isEmpty {
                    Button(action: { showingTips = true }) {
                        Image(systemName: "info.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingTips) {
            TipsView(exerciseName: exercise.name, tips: exercise.tips)
        }
        .animation(.easeInOut(duration: 0.3), value: timerCompleted)
    }

    private func checkAudioCues() {
        guard audioEnabled else { return }
        let elapsedTime = exercise.durationSeconds - timeRemaining
        if let cue = exercise.audioCues[elapsedTime] {
            TTSManager.shared.speak(cue)
        }
    }
}

// MARK: - Tips View

struct TipsView: View {
    let exerciseName: String
    let tips: [String]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Helper Tips")) {
                    ForEach(tips, id: \.self) { tip in
                        HStack(alignment: .top) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                                .padding(.top, 2)
                            Text(tip)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle(exerciseName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Timer Circle

struct TimerCircle: View {
    let timeRemaining: Int
    let totalTime: Int
    var timerCompleted: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 20)
                .opacity(0.15)
                .foregroundStyle(timerCompleted ? Color.green : Color.blue)

            Circle()
                .trim(from: 0.0, to: CGFloat(timeRemaining) / CGFloat(max(totalTime, 1)))
                .stroke(
                    style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round)
                )
                .foregroundStyle(timerCompleted ? Color.green : Color.blue)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: timeRemaining)
                .animation(.easeInOut(duration: 0.5), value: timerCompleted)

            VStack(spacing: 4) {
                Text(timeString(time: timeRemaining))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(timerCompleted ? .green : .primary)
                Text(timerCompleted ? "Complete!" : "remaining")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 240, height: 240)
    }

    private func timeString(time: Int) -> String {
        let minutes = time / 60
        let seconds = time % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Previews

#Preview("Exercise List — Populated") {
    NavigationView {
        ExerciseListView(category: .stretching, profile: nil)
    }
    .modelContainer(for: Exercise.self, inMemory: true)
}

#Preview("Exercise List — Empty") {
    NavigationView {
        ExerciseEmptyState()
            .navigationTitle("Balance")
    }
}
