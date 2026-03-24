//
//  ContentView.swift
//  daily
//
//  Created by Ben Sheridan on 14/01/2026.
//

import SwiftUI
import SwiftData

// Custom LiquidGlass view for glassy background effect
struct LiquidGlass: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            // Ultra thin material background with blur
            Rectangle()
                .fill(.ultraThinMaterial)
                .blur(radius: 2)

            // Subtle animated color reflections
            LinearGradient(
                colors: [
                    Color.white.opacity(animate ? 0.25 : 0.15),
                    Color.blue.opacity(animate ? 0.15 : 0.1),
                    Color.white.opacity(animate ? 0.2 : 0.1)
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
                    VStack(alignment: .leading, spacing: 20) {
                        HeaderView(profile: profile)

                        if let routine = dailyRoutine {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Routine of the Day")
                                    .font(.title2)
                                    .fontWeight(.bold)

                                NavigationLink(destination: RoutineDetailView(routine: routine, allExercises: allExercises, profile: profile, routineCompleted: {
                                    profile?.completeRoutine()
                                    refreshTrigger.toggle()
                                })) {
                                    DailyRoutineCard(routine: routine)
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                            .padding(.horizontal)
                        }

                        Text("Exercise Categories")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                            ForEach(categories) { category in
                                NavigationLink(destination: ExerciseListView(category: category, profile: profile)) {
                                    CategoryCard(category: category)
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                        .padding(.horizontal)

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

struct DailyRoutineCard: View {
    let routine: Routine

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(routine.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(routine.routineDescription)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))

                HStack {
                    Image(systemName: "play.circle.fill")
                    Text("Start Now")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.2))
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.top, 5)
            }
            Spacer()
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            LiquidGlass()
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .environment(\.colorScheme, .dark)
    }
}

struct HeaderView: View {
    let profile: UserProfile?

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Ready for your daily?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(profile?.gender == .male ? "Keep it up!" : profile?.gender == .female ? "Stay strong!" : "Hello!")
                    .font(.title)
                    .fontWeight(.bold)
            }
        }
        .padding()
    }
}

struct CategoryCard: View {
    let category: ExerciseCategory

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.system(size: 30))
                .foregroundColor(.white)

            Text(category.rawValue)
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .background(
            LiquidGlass()
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
        .environment(\.colorScheme, .dark)
    }
}

struct StatsView: View {
    let profile: UserProfile?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your Progress")
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 20) {
                StatItem(title: "Streak", value: "\(profile?.streakCount ?? 0) days", icon: "flame.fill", color: .orange)
                StatItem(title: "Level", value: "\(profile?.level ?? 1)", icon: "star.fill", color: .yellow)
                StatItem(title: "XP", value: "\(profile?.xp ?? 0)", icon: "bolt.fill", color: .blue)
            }
        }
        .padding()
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// ButtonStyle to provide smooth tap scale animation for cards
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Exercise.self, inMemory: true)
}

