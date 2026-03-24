import SwiftUI
import SwiftData

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
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 5) {
                Text(routine.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text(routine.routineDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            
            List {
                Section(header: Text("Exercises")) {
                    ForEach(0..<routineExercises.count, id: \.self) { index in
                        HStack {
                            Text("\(index + 1).")
                                .fontWeight(.bold)
                                .foregroundColor(index < currentExerciseIndex ? .green : (index == currentExerciseIndex ? .blue : .gray))
                            
                            VStack(alignment: .leading) {
                                Text(routineExercises[index].name)
                                    .fontWeight(.medium)
                                Text("\(routineExercises[index].durationSeconds / 60) min")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if index < currentExerciseIndex {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else if index == currentExerciseIndex {
                                Image(systemName: "play.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if index == currentExerciseIndex {
                                showingExercise = true
                            }
                        }
                    }
                }
            }
            
            Button(action: { showingExercise = true }) {
                Text(currentExerciseIndex == 0 ? "Start Routine" : (currentExerciseIndex < routineExercises.count ? "Continue Routine" : "Restart Routine"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            .padding()
            .disabled(currentExerciseIndex >= routineExercises.count && currentExerciseIndex != 0)
            
            if currentExerciseIndex >= routineExercises.count {
                Button(action: { currentExerciseIndex = 0 }) {
                    Text("Complete & Reset")
                        .foregroundColor(.blue)
                }
                .padding(.bottom)
            }
        }
        .sheet(isPresented: $showingExercise, onDismiss: {
            // When exercise finishes, move to next
            // In a real app, we'd check if it actually finished
        }) {
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
        .background(Color(uiColor: .systemGroupedBackground))
    }
}
