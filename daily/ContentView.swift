//
//  ContentView.swift
//  daily
//
//  Created by Ben Sheridan on 14/01/2026.
//

import SwiftUI
import SwiftData

// MARK: - LiquidGlass Background

struct LiquidGlass: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .blur(radius: 2)

            // Subtle animated overlay — works in both Light and Dark Mode
            LinearGradient(
                colors: [
                    Color.white.opacity(animate ? 0.12 : 0.07),
                    Color.blue.opacity(animate ? 0.06 : 0.03),
                    Color.white.opacity(animate ? 0.10 : 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.overlay)
            .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animate)
            .onAppear {
                animate = true
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Content View

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var showingOnboarding = false

    var body: some View {
        Group {
            if showingOnboarding {
                OnboardingView(isFirstTime: $showingOnboarding)
            } else {
                DashboardView(profile: profiles.first)
            }
        }
        .onAppear {
            Exercise.seedInitialData(context: modelContext)
            if profiles.isEmpty {
                showingOnboarding = true
            }
        }
    }
}

// MARK: - Dashboard View

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allExercises: [Exercise]

    let profile: UserProfile?
    let categories = ExerciseCategory.displayCategories

    @AppStorage("preferredSessionTierRaw") private var preferredSessionTierRaw: String = SessionTier.basic.rawValue
    @State private var sessionExerciseNames: [String] = []
    @State private var unlockedTier: ExperienceTier? = nil
    @State private var refreshTrigger = false

    /// The effective session tier — respects the stored preference if unlocked,
    /// otherwise falls back to the highest available tier for this profile.
    var selectedSessionTier: SessionTier {
        let stored = SessionTier(rawValue: preferredSessionTierRaw) ?? .basic
        guard stored.isUnlocked(for: profile) else {
            return SessionTier.allCases.reversed().first { $0.isUnlocked(for: profile) } ?? .basic
        }
        return stored
    }

    /// A transient (non-persisted) Routine built from the generated exercise names.
    var generatedRoutine: Routine? {
        guard !sessionExerciseNames.isEmpty else { return nil }
        return Routine(
            name: "Today's Session",
            routineDescription: "\(selectedSessionTier.rawValue) · \(sessionExerciseNames.count) exercises",
            exerciseNames: sessionExerciseNames
        )
    }

    /// Builds (or rebuilds) the exercise list for the current tier and profile.
    private func rebuildSession() {
        guard !allExercises.isEmpty else { return }
        sessionExerciseNames = Routine.buildSession(
            tier: selectedSessionTier,
            exercises: allExercises,
            profile: profile
        )
    }

    var body: some View {
        NavigationView {
            ZStack {
                LiquidGlass()

                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.sectionSpacing) {
                        HeaderView(profile: profile)

                        // Session duration tier picker
                        SessionTierPicker(
                            profile: profile,
                            selectedTierRaw: $preferredSessionTierRaw
                        )
                        .padding(.horizontal)

                        if let routine = generatedRoutine {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Today's Workout")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)

                                NavigationLink(destination: RoutineDetailView(
                                    routine: routine,
                                    allExercises: allExercises,
                                    profile: profile,
                                    routineCompleted: {
                                        if let p = profile, let tier = p.completeRoutine() {
                                            unlockedTier = tier
                                        }
                                        rebuildSession()
                                        refreshTrigger.toggle()
                                    }
                                )) {
                                    DailyRoutineCard(routine: routine)
                                }
                                .buttonStyle(DesignTokens.scaleButton)
                                .padding(.horizontal)
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Exercise Categories")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)

                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible())],
                                spacing: DesignTokens.gridSpacing
                            ) {
                                ForEach(categories) { category in
                                    NavigationLink(destination: ExerciseListView(category: category, profile: profile)) {
                                        CategoryCard(category: category)
                                    }
                                    .buttonStyle(DesignTokens.scaleButton)
                                }
                            }
                            .padding(.horizontal)
                        }

                        StatsView(profile: profile)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Daily")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
            .toolbarTitleDisplayMode(.large)
            .onAppear {
                rebuildSession()
            }
            .onChange(of: preferredSessionTierRaw) {
                rebuildSession()
            }
            .onChange(of: allExercises.count) {
                if !allExercises.isEmpty && sessionExerciseNames.isEmpty {
                    rebuildSession()
                }
            }
            .sheet(item: $unlockedTier) { tier in
                LevelUpView(tier: tier)
            }
        }
    }
}

// MARK: - Session Tier Picker

struct SessionTierPicker: View {
    let profile: UserProfile?
    @Binding var selectedTierRaw: String

    var selectedTier: SessionTier {
        SessionTier(rawValue: selectedTierRaw) ?? .basic
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Session Duration")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(SessionTier.allCases) { tier in
                    tierButton(tier)
                }
            }
        }
    }

    @ViewBuilder
    private func tierButton(_ tier: SessionTier) -> some View {
        let unlocked = tier.isUnlocked(for: profile)
        let isSelected = tier == selectedTier && unlocked

        Button(action: {
            if unlocked { selectedTierRaw = tier.rawValue }
        }) {
            VStack(spacing: 4) {
                Text(tier.rawValue)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundStyle(isSelected ? .white : (unlocked ? .primary : .secondary))
                    .lineLimit(1)

                if !unlocked {
                    Text(tier.unlockLabel)
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .background(
                Group {
                    if isSelected {
                        Color.blue
                    } else {
                        Color(uiColor: .secondarySystemGroupedBackground)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(
                        isSelected ? Color.clear : Color(uiColor: .separator).opacity(0.5),
                        lineWidth: 0.5
                    )
            )
        }
        .buttonStyle(DesignTokens.scaleButton)
        .opacity(unlocked ? 1.0 : 0.5)
        .disabled(!unlocked)
    }
}

// MARK: - Level Up View

struct LevelUpView: View {
    let tier: ExperienceTier
    @Environment(\.dismiss) private var dismiss

    private var unlockedSessionLabel: String {
        switch tier {
        case .intermediate: return "15-20 min sessions are now available."
        case .advanced:     return "20-30 min sessions are now available."
        case .beginner:     return ""
        }
    }

    private var accentColor: Color {
        tier == .advanced ? .purple : .blue
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: tier.icon)
                .font(.system(size: 72))
                .foregroundStyle(accentColor)
                .padding(.bottom, 8)

            VStack(spacing: 10) {
                Text("You've reached")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Text("\(tier.displayName)!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                if !unlockedSessionLabel.isEmpty {
                    Text(unlockedSessionLabel)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 4)
                }
            }

            Spacer()

            Button(action: { dismiss() }) {
                Text("Let's Go!")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(DesignTokens.scaleButton)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Daily Routine Card

struct DailyRoutineCard: View {
    let routine: Routine

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(routine.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(routine.routineDescription)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))

                HStack {
                    Image(systemName: "play.circle.fill")
                    Text("Start Now")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.2))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(.top, 5)
            }
            Spacer()
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(DesignTokens.cardPadding)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [.green, Color(red: 0.0, green: 0.6, blue: 0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius, style: .continuous))
        .shadow(color: Color.green.opacity(0.25), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Header View

struct HeaderView: View {
    let profile: UserProfile?

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Ready for your daily?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(greeting)
                    .font(.title)
                    .fontWeight(.bold)
            }
        }
        .padding(.horizontal)
    }

    private var greeting: String {
        switch profile?.gender {
        case .male: return "Keep it up!"
        case .female: return "Stay strong!"
        default: return "Let's go!"
        }
    }
}

// MARK: - Category Card

struct CategoryCard: View {
    let category: ExerciseCategory

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.system(size: 30))
                .foregroundStyle(.blue)

            Text(category.rawValue)
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 110)
        .padding(DesignTokens.cardPadding)
        .cardStyle()
    }
}

// MARK: - Stats View

struct StatsView: View {
    let profile: UserProfile?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Progress")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            HStack(spacing: 12) {
                StatItem(title: "Streak", value: "\(profile?.streakCount ?? 0) days", icon: "flame.fill", color: .orange)
                StatItem(title: "Level", value: "\(profile?.level ?? 1)", icon: "star.fill", color: .yellow)
                StatItem(title: "XP", value: "\(profile?.xp ?? 0)", icon: "bolt.fill", color: .blue)
            }
            .padding(DesignTokens.cardPadding)
            .cardStyle()
            .padding(.horizontal)
        }
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

#Preview("Content View") {
    ContentView()
        .modelContainer(for: [Exercise.self, Routine.self, UserProfile.self], inMemory: true)
}

#Preview("Session Tier Picker — Beginner") {
    SessionTierPicker(profile: nil, selectedTierRaw: .constant(SessionTier.basic.rawValue))
        .padding()
}

#Preview("Session Tier Picker — Intermediate") {
    let profile = UserProfile(gender: .unspecified, xp: 0, level: 7, streakCount: 30)
    return SessionTierPicker(profile: profile, selectedTierRaw: .constant(SessionTier.intermediate.rawValue))
        .padding()
        .modelContainer(for: UserProfile.self, inMemory: true)
}

#Preview("Level Up — Intermediate") {
    LevelUpView(tier: .intermediate)
}

#Preview("Level Up — Advanced") {
    LevelUpView(tier: .advanced)
}
