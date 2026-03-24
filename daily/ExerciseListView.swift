import SwiftUI
import SwiftData
internal import Combine
import UIKit

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
        List(exercises) { exercise in
            NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                VStack(alignment: .leading) {
                    Text(exercise.name)
                        .font(.headline)
                    Text(exercise.exerciseDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle(category.rawValue)
    }
}

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
            VStack(alignment: .leading, spacing: 25) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(exercise.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text(exercise.difficulty.rawValue)
                            .font(.subheadline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(difficultyColor.opacity(0.1))
                            .foregroundColor(difficultyColor)
                            .cornerRadius(8)
                    }
                    Spacer()
                    Button(action: { audioEnabled.toggle() }) {
                        Image(systemName: audioEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.title2)
                            .foregroundColor(audioEnabled ? .blue : .gray)
                    }
                }
                
                TimerCircle(timeRemaining: timeRemaining, totalTime: exercise.durationSeconds)
                    .padding(.vertical)
                
                HStack {
                    Button(action: {
                        timerActive.toggle()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        Label(timerActive ? "Pause" : "Start", systemImage: timerActive ? "pause.fill" : "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)

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
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("Instructions")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    ForEach(0..<exercise.instructions.count, id: \.self) { index in
                        HStack(alignment: .top) {
                            Text("\(index + 1).")
                                .fontWeight(.bold)
                            Text(exercise.instructions[index])
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(15)
                
                if !exercise.tips.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Safety & Form")
                            .font(.headline)
                        ForEach(exercise.tips, id: \.self) { tip in
                            Label(tip, systemImage: "checkmark.shield.fill")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(15)
                }
            }
            .padding()
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
    }
    
    private var difficultyColor: Color {
        switch exercise.difficulty {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
    
    private func checkAudioCues() {
        guard audioEnabled else { return }
        let elapsedTime = exercise.durationSeconds - timeRemaining
        if let cue = exercise.audioCues[elapsedTime] {
            TTSManager.shared.speak(cue)
        }
    }
}

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
                                .foregroundColor(.yellow)
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
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TimerCircle: View {
    let timeRemaining: Int
    let totalTime: Int
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 20)
                .opacity(0.3)
                .foregroundColor(.blue)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(timeRemaining) / CGFloat(totalTime))
                .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                .foregroundColor(.blue)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: timeRemaining)
            
            VStack {
                Text(timeString(time: timeRemaining))
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                Text("remaining")
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 250, height: 250)
    }
    
    private func timeString(time: Int) -> String {
        let minutes = time / 60
        let seconds = time % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
