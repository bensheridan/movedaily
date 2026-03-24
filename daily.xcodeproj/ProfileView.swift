import SwiftUI
import SwiftData
import UIKit
import UserNotifications

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
        Form {
            Section(header: Text("Your Profile")) {
                VStack(spacing: 8) {
                    if let uiImage = profile?.profileImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                    }
                    Button("Edit") {
                        showingImagePicker = true
                    }
                }
                HStack {
                    Text("Gender")
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
                HStack {
                    Text("Level")
                    Spacer()
                    Text("\(profile?.level ?? 1)")
                }
                HStack {
                    Text("XP")
                    Spacer()
                    Text("\(profile?.xp ?? 0)")
                }
                HStack {
                    Text("Streak")
                    Spacer()
                    Text("\(profile?.streakCount ?? 0) days")
                }
            }
            
            Section(header: Text("Reminders")) {
                Toggle("Enable Reminder", isOn: $reminderEnabled)
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
                DatePicker("Reminder Time", selection: reminderDate, displayedComponents: [.hourAndMinute])
                    .disabled(!reminderEnabled)
                    .onChange(of: reminderDate.wrappedValue) { newDate in
                        if reminderEnabled {
                            NotificationManager.shared.scheduleDailyReminder(at: reminderTime)
                        }
                    }
            }
            
            Section {
                Button(role: .destructive) {
                    showingResetAlert = true
                } label: {
                    Label("Reset Profile", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .navigationTitle("Profile")
        .onAppear {
            if let gender = profile?.gender {
                selectedGender = gender
            }
        }
        .alert("Reset Profile?", isPresented: $showingResetAlert) {
            Button("Reset", role: .destructive) {
                resetProfile()
            }
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
    
    private func resetProfile() {
        guard let profile = profile else { return }
        profile.xp = 0
        profile.level = 1
        profile.streakCount = 0
        profile.lastExerciseDate = nil
    }
}

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
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    DispatchQueue.main.async {
                        if let uiImage = image as? UIImage {
                            self.parent.image = uiImage
                        }
                    }
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
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

#Preview {
    NavigationView {
        ProfileView()
            .modelContainer(for: UserProfile.self, inMemory: true)
    }
}

