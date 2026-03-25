import SwiftUI
import SwiftData
import UIKit
import PhotosUI
import UserNotifications

// MARK: - Profile View

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var selectedGender: Gender = .unspecified
    @State private var showingResetAlert = false
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?

    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderTime") private var reminderTime = "08:00"

    private var reminderDate: Binding<Date> {
        Binding<Date>(
            get: {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                return formatter.date(from: reminderTime) ?? Date()
            },
            set: { newValue in
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                reminderTime = formatter.string(from: newValue)
            }
        )
    }

    var profile: UserProfile? {
        profiles.first
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.sectionSpacing) {
                profileHeroCard
                remindersCard
                resetCard
            }
            .padding(DesignTokens.cardPadding)
            .padding(.bottom, DesignTokens.sectionSpacing)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Profile")
        .onAppear {
            if let gender = profile?.gender {
                selectedGender = gender
            }
        }
        .alert("Reset Profile?", isPresented: $showingResetAlert) {
            Button("Reset", role: .destructive) { resetProfile() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset your streak, XP, and level but keep your gender selection.")
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $inputImage)
        }
        .onChange(of: inputImage) { newImage in
            if let newImage = newImage {
                profile?.setProfileImage(newImage)
            }
        }
    }

    // MARK: - Profile Hero Card

    private var profileHeroCard: some View {
        VStack(spacing: DesignTokens.sectionSpacing) {
            // Photo
            VStack(spacing: 10) {
                if let uiImage = profile?.profileImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 90, height: 90)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                        .foregroundStyle(.secondary)
                }

                Button("Edit Photo") {
                    showingImagePicker = true
                }
                .font(.subheadline)
                .buttonStyle(DesignTokens.scaleButton)
            }

            Divider()

            // Gender picker
            HStack {
                Label("Gender", systemImage: "person")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("Gender", selection: $selectedGender) {
                    ForEach(Gender.allCases) { gender in
                        Text(gender.rawValue).tag(gender)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedGender) { newValue in
                    if let profile = profile {
                        profile.gender = newValue
                    }
                }
            }

            Divider()

            // Stats row
            HStack(spacing: 0) {
                statChip(value: "\(profile?.streakCount ?? 0)", label: "Streak", icon: "flame.fill", color: .orange)
                Divider().frame(height: 40)
                statChip(value: "\(profile?.level ?? 1)", label: "Level", icon: "star.fill", color: .yellow)
                Divider().frame(height: 40)
                statChip(value: "\(profile?.xp ?? 0)", label: "XP", icon: "bolt.fill", color: .blue)
                Divider().frame(height: 40)
                statChip(
                    value: profile?.experienceTier.displayName ?? "Beginner",
                    label: "Tier",
                    icon: profile?.experienceTier.icon ?? "figure.walk",
                    color: tierAccentColor
                )
            }
        }
        .padding(DesignTokens.cardPadding)
        .cardStyle()
    }

    // MARK: - Reminders Card

    private var remindersCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Reminders")
                .font(.headline)

            Toggle("Enable daily reminder", isOn: $reminderEnabled)
                .onChange(of: reminderEnabled) { isEnabled in
                    if isEnabled {
                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
                            DispatchQueue.main.async {
                                if granted {
                                    NotificationManager.shared.scheduleDailyReminder(at: reminderTime)
                                } else {
                                    reminderEnabled = false
                                }
                            }
                        }
                    } else {
                        NotificationManager.shared.removeReminder()
                    }
                }

            DatePicker("Reminder time", selection: reminderDate, displayedComponents: [.hourAndMinute])
                .disabled(!reminderEnabled)
                .onChange(of: reminderDate.wrappedValue) { _ in
                    if reminderEnabled {
                        NotificationManager.shared.scheduleDailyReminder(at: reminderTime)
                    }
                }
        }
        .padding(DesignTokens.cardPadding)
        .cardStyle()
    }

    // MARK: - Reset Card

    private var resetCard: some View {
        VStack {
            Button(role: .destructive) {
                showingResetAlert = true
            } label: {
                Label("Reset Profile", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(DesignTokens.scaleButton)
        }
        .padding(DesignTokens.cardPadding)
        .cardStyle()
    }

    // MARK: - Helpers

    private func statChip(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var tierAccentColor: Color {
        switch profile?.experienceTier {
        case .intermediate: return .blue
        case .advanced:     return .purple
        default:            return .green
        }
    }

    private func resetProfile() {
        guard let profile = profile else { return }
        profile.xp = 0
        profile.level = 1
        profile.streakCount = 0
        profile.lastExerciseDate = nil
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    class Coordinator: NSObject, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
        var parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider else { return }
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        if let uiImage = image as? UIImage {
                            self.parent.image = uiImage
                        }
                    }
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProfileView()
            .modelContainer(for: UserProfile.self, inMemory: true)
    }
}
