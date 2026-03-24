import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var gender: Gender = Gender.allCases.first ?? { fatalError("Gender has no cases") }()
    @State private var level: Int = 1
    @State private var xp: Int = 0

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile")) {
                    Picker("Gender", selection: $gender) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Text(gender.rawValue.capitalized).tag(gender)
                        }
                    }
                }

                Section(header: Text("Progress")) {
                    Stepper(value: $level, in: 1...999) {
                        HStack {
                            Text("Level")
                            Spacer()
                            Text("\(level)")
                        }
                    }
                    Stepper(value: $xp, in: 0...99) {
                        HStack {
                            Text("XP")
                            Spacer()
                            Text("\(xp)")
                        }
                    }
                }

                if let profile = profiles.first {
                    Section(header: Text("Streak")) {
                        HStack {
                            Text("Days")
                            Spacer()
                            Text("\(profile.streakCount)")
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                }
            }
            .onAppear {
                loadProfile()
            }
        }
    }

    private func loadProfile() {
        if let profile = profiles.first {
            // UserProfile has no `name`; keep local `name` unchanged or derive from elsewhere if added later
            gender = profile.gender
            level = profile.level
            xp = profile.xp
        }
    }

    private func saveChanges() {
        if let profile = profiles.first {
            // UserProfile has no `name` property
            profile.gender = gender
            profile.level = level
            profile.xp = xp
        } else {
            let newProfile = UserProfile(gender: gender, xp: xp, level: level, streakCount: 0)
            modelContext.insert(newProfile)
        }
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserProfile.self], inMemory: true)
}
