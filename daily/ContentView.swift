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
    @Query private var routines: [Routine]
    @Query private var allExercises: [Exercise]

    let profile: UserProfile?
    let categories = ExerciseCategory.displayCategories

    @State private var refreshTrigger = false

    var dailyRoutine: Routine? {
        guard !routines.isEmpty else { return nil }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let index = dayOfYear % routines.count
        return routines[index]
    }

    var body: some View {
        NavigationView {
            ZStack {
                LiquidGlass()

                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.sectionSpacing) {
                        HeaderView(profile: profile)

                        if let routine = dailyRoutine {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Routine of the Day")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)

                                NavigationLink(destination: RoutineDetailView(
                                    routine: routine,
                                    allExercises: allExercises,
                                    profile: profile,
                                    routineCompleted: {
                                        profile?.completeRoutine()
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

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: Exercise.self, inMemory: true)
}
