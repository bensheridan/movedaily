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
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        Group {
            if showingOnboarding {
                OnboardingView(isFirstTime: $showingOnboarding)
            } else {
                DashboardView(profile: profiles.first)
            }
        }
        .environment(\.isUnfolded, sizeClass == .regular)
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

    @Query private var allPlans: [WorkoutPlan]

    @AppStorage("preferredSessionTierRaw") private var preferredSessionTierRaw: String = SessionTier.basic.rawValue
    @State private var sessionExerciseNames: [String] = []
    @State private var unlockedTier: ExperienceTier? = nil
    @State private var refreshTrigger = false
    @State private var showingCustomBuilder = false
    @State private var showingWeeklyPlanner = false
    @State private var ignorePlanToday = false
    @Environment(\.isUnfolded) private var isUnfolded

    var activePlan: WorkoutPlan? {
        allPlans.first(where: { $0.isActive })
    }

    var todayPlanDay: PlanDay? {
        let wd = Calendar.current.component(.weekday, from: Date())
        return activePlan?.days.first(where: { $0.weekdays.contains(wd) })
    }

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

    /// True when the user has active injuries AND the pool was reduced (fewer exercises than without injury filter).
    private var injuryNoticeVisible: Bool {
        guard let profile, !profile.activeInjuries.isEmpty else { return false }
        let unfilteredCount = allExercises.filter {
            $0.genderFocus == nil || $0.genderFocus == profile.gender
        }.count
        let filteredCount = allExercises.filter {
            let genderOk = $0.genderFocus == nil || $0.genderFocus == profile.gender
            let injuryOk = Set($0.contraindications).isDisjoint(with: Set(profile.activeInjuries))
            return genderOk && injuryOk
        }.count
        return filteredCount < unfilteredCount
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
        NavigationStack {
            ZStack {
                LiquidGlass()

                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.sectionSpacing) {
                        HeaderView(profile: profile)

                        if isUnfolded {
                            // Inner screen: today + programs beside This for That + progress.
                            HStack(alignment: .top, spacing: 0) {
                                VStack(alignment: .leading, spacing: DesignTokens.sectionSpacing) {
                                    sessionSection
                                    programsSection
                                }
                                .frame(maxWidth: .infinity, alignment: .topLeading)

                                VStack(alignment: .leading, spacing: DesignTokens.sectionSpacing) {
                                    ThisForThatSection()
                                    StatsView(profile: profile)
                                }
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                            }

                            categoriesSection(columns: 4)
                        } else {
                            sessionSection
                            programsSection
                            ThisForThatSection()
                            categoriesSection(columns: 2)
                            StatsView(profile: profile)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Daily")
            #if DEBUG
            .modifier(ScreenshotRouteModifier(allExercises: allExercises, profile: profile))
            #endif
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { showingWeeklyPlanner = true }) {
                        Image(systemName: "calendar.badge.plus")
                    }
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
            .sheet(isPresented: $showingCustomBuilder) {
                CustomWorkoutBuilderView(sessionTier: selectedSessionTier)
            }
            .sheet(isPresented: $showingWeeklyPlanner) {
                WeeklyPlannerView()
            }
        }
    }

    // MARK: Sections

    /// Session duration picker and today's workout (plan day, rest day or auto session).
    @ViewBuilder
    private var sessionSection: some View {
        // Session duration tier picker
        SessionTierPicker(
            profile: profile,
            selectedTierRaw: $preferredSessionTierRaw
        )
        .padding(.horizontal)

        // Today's session area: plan day, rest day banner, or auto session
        if let planDay = todayPlanDay, !ignorePlanToday {
            TodaysPlanCard(
                activePlanName: activePlan?.name ?? "",
                planDay: planDay,
                allExercises: allExercises,
                profile: profile,
                onIgnore: { ignorePlanToday = true },
                routineCompleted: {
                    if let p = profile, let tier = p.completeRoutine() {
                        unlockedTier = tier
                    }
                    refreshTrigger.toggle()
                }
            )
        } else if activePlan != nil && todayPlanDay == nil && !ignorePlanToday {
            RestDayBanner(planName: activePlan?.name ?? "") {
                ignorePlanToday = true
            }
        } else if let routine = generatedRoutine {
            VStack(alignment: .leading, spacing: 12) {
                Text("Today's Workout")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)

                if injuryNoticeVisible {
                    HStack(spacing: 8) {
                        Image(systemName: "bandage")
                            .foregroundStyle(.orange)
                        Text("Some exercises were removed due to your active injury.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }

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

                Button(action: { showingCustomBuilder = true }) {
                    Label("Build your own workout", systemImage: "slider.horizontal.3")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(DesignTokens.scaleButton)
                .padding(.horizontal)
            }
        } else if !(profile?.activeInjuries ?? []).isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Today's Workout")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                HStack(spacing: 8) {
                    Image(systemName: "bandage")
                        .foregroundStyle(.orange)
                    Text("No exercises available for your current injury settings. Try adjusting your injury profile.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
        }
    }

    private var programsSection: some View {
        ProgramsSection(
            allExercises: allExercises,
            profile: profile,
            routineCompleted: {
                if let p = profile, let tier = p.completeRoutine() {
                    unlockedTier = tier
                }
                refreshTrigger.toggle()
            }
        )
    }

    private func categoriesSection(columns: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercise Categories")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible()), count: columns),
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

// MARK: - Synthetic Exercise Conversion

func syntheticExercise(from pe: PlanExercise) -> Exercise {
    Exercise(
        name: pe.name,
        exerciseDescription: pe.unit == "sets"
            ? "\(pe.value) set\(pe.value == 1 ? "" : "s")"
            : "\(pe.value) sec",
        durationSeconds: pe.nominalSeconds,
        category: .bodyweight,
        instructions: [],
        tips: []
    )
}

// MARK: - Today's Plan Card

struct TodaysPlanCard: View {
    let activePlanName: String
    let planDay: PlanDay
    let allExercises: [Exercise]
    let profile: UserProfile?
    let onIgnore: () -> Void
    var routineCompleted: (() -> Void)? = nil

    @State private var navigateToDetail = false

    private var syntheticExercises: [Exercise] {
        planDay.exercises.map { syntheticExercise(from: $0) }
    }

    private var syntheticRoutine: Routine {
        Routine(
            name: planDay.name,
            routineDescription: "\(activePlanName) · \(planDay.exercises.count) exercise\(planDay.exercises.count == 1 ? "" : "s")",
            exerciseNames: planDay.exercises.map(\.name)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Workout")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            Text(activePlanName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            NavigationLink(destination: RoutineDetailView(
                routine: syntheticRoutine,
                allExercises: allExercises + syntheticExercises,
                profile: profile,
                routineCompleted: routineCompleted
            )) {
                PlanDayCard(planDay: planDay)
            }
            .buttonStyle(DesignTokens.scaleButton)
            .padding(.horizontal)

            Button(action: onIgnore) {
                Text("Not today — use auto session")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
        }
    }
}

struct PlanDayCard: View {
    let planDay: PlanDay

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(planDay.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("\(planDay.exercises.count) exercise\(planDay.exercises.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
                Image(systemName: "calendar.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white.opacity(0.6))
            }

            if !planDay.exercises.isEmpty {
                let preview = planDay.exercises.prefix(3).map(\.name)
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(preview, id: \.self) { name in
                        Text("• \(name)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    if planDay.exercises.count > 3 {
                        Text("+ \(planDay.exercises.count - 3) more")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }

            HStack {
                Image(systemName: "play.circle.fill")
                Text("Start Session")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.2))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(.top, 4)
        }
        .padding(DesignTokens.cardPadding)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [.blue, Color(red: 0.1, green: 0.3, blue: 0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius, style: .continuous))
        .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Rest Day Banner

struct RestDayBanner: View {
    let planName: String
    let onAutoSession: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Workout")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            HStack(spacing: 16) {
                Image(systemName: "bed.double")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rest day")
                        .font(.headline)
                    Text(planName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(DesignTokens.cardPadding)
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius, style: .continuous))
            .padding(.horizontal)

            Button(action: onAutoSession) {
                Text("Do an auto session instead")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
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
        .modelContainer(for: [Exercise.self, Routine.self, UserProfile.self, CustomExercise.self, WorkoutPlan.self, PlanDay.self, ThisForThat.self], inMemory: true)
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
