import SwiftUI
import SwiftData

// MARK: - Onboarding View

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isFirstTime: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero section
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green, Color(red: 0.0, green: 0.6, blue: 0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: .green.opacity(0.35), radius: 16, x: 0, y: 8)

                    Image(systemName: "figure.run")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 8) {
                    Text("Welcome to Daily")
                        .font(.system(size: 36, weight: .bold, design: .rounded))

                    Text("Move a little every day.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.bottom, 48)

            Spacer()

            // Selection section
            VStack(spacing: 16) {
                Text("Personalise your experience")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                GenderButton(title: "I'm Male", icon: "figure.arms.open", color: .blue) {
                    saveProfile(gender: .male)
                }

                GenderButton(title: "I'm Female", icon: "figure.arms.open", color: .pink) {
                    saveProfile(gender: .female)
                }

                Button("Skip for now") {
                    saveProfile(gender: .unspecified)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)

                Text(HealthDisclaimer.short)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .padding(.bottom, 32)
        }
        .padding(.horizontal, DesignTokens.cardPadding)
    }

    private func saveProfile(gender: Gender) {
        let profile = UserProfile(gender: gender)
        modelContext.insert(profile)
        isFirstTime = false
    }
}

// MARK: - Gender Button

struct GenderButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundStyle(color)
                    )

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(DesignTokens.cardPadding)
            .cardStyle()
        }
        .buttonStyle(DesignTokens.scaleButton)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(isFirstTime: .constant(true))
        .modelContainer(for: UserProfile.self, inMemory: true)
}
