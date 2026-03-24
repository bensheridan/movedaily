import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isFirstTime: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Welcome to Daily")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .padding(.top, 50)
            
            Text("Select your gender to tailor your exercises.")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 20) {
                GenderButton(title: "Male", icon: "figure.arms.open", color: .blue) {
                    saveProfile(gender: .male)
                }
                
                GenderButton(title: "Female", icon: "figure.arms.open", color: .pink) {
                    saveProfile(gender: .female)
                }
                
                Button("Skip for now") {
                    saveProfile(gender: .unspecified)
                }
                .foregroundColor(.secondary)
            }
            .padding(.bottom, 50)
        }
        .padding()
    }
    
    private func saveProfile(gender: Gender) {
        let profile = UserProfile(gender: gender)
        modelContext.insert(profile)
        isFirstTime = false
    }
}

struct GenderButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(color, lineWidth: 2)
            )
        }
        .padding(.horizontal)
    }
}

#Preview {
    OnboardingView(isFirstTime: .constant(true))
        .modelContainer(for: UserProfile.self, inMemory: true)
}
