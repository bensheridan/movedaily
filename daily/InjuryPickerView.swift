import SwiftUI
import SwiftData

struct InjuryPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            List(InjuryType.allCases) { injury in
                Button(action: { toggle(injury) }) {
                    HStack {
                        Image(systemName: injury.icon)
                            .frame(width: 28)
                            .foregroundStyle(.blue)
                        Text(injury.displayName)
                            .foregroundStyle(.primary)
                        Spacer()
                        if isActive(injury) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .navigationTitle("Active Injuries")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func isActive(_ injury: InjuryType) -> Bool {
        profile?.activeInjuries.contains(injury.rawValue) ?? false
    }

    private func toggle(_ injury: InjuryType) {
        guard let profile else { return }
        if isActive(injury) {
            profile.activeInjuries.removeAll { $0 == injury.rawValue }
        } else {
            profile.activeInjuries.append(injury.rawValue)
        }
    }
}

#Preview {
    InjuryPickerView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
