import SwiftUI

// MARK: - Health Disclaimer

/// The app's health and safety wording, kept in one place so onboarding, programs, the
/// profile and the support page (docs/support.html) say the same thing.
enum HealthDisclaimer {
    static let full = "Move Daily offers general exercise and wellbeing guidance and is not medical advice. Check with your doctor or physiotherapist before starting a new exercise routine, especially if you have an injury, a medical condition or are pregnant. Stop any exercise that causes pain, dizziness or shortness of breath."

    static let short = "General exercise guidance, not medical advice. Check with your doctor or physiotherapist before starting, and stop if anything causes pain."

    static let focusProgram = "These exercises may help ease symptoms but don't treat the condition. Check with your doctor or physiotherapist first, and see them if symptoms persist or get worse."
}

/// A small, quiet notice: an info icon beside secondary caption text.
struct HealthNotice: View {
    let text: String

    var body: some View {
        Label {
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "stethoscope")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Health Notice") {
    VStack(spacing: 20) {
        HealthNotice(text: HealthDisclaimer.short)
        HealthNotice(text: HealthDisclaimer.focusProgram)
        HealthNotice(text: HealthDisclaimer.full)
    }
    .padding()
}
