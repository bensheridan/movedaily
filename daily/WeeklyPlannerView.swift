import SwiftUI
import SwiftData

// MARK: - Weekly Planner View

struct WeeklyPlannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutPlan.createdAt, order: .forward) private var allPlans: [WorkoutPlan]

    @State private var showingNewPlan = false
    @State private var planToEdit: WorkoutPlan? = nil
    @State private var planToDelete: WorkoutPlan? = nil
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            Group {
                if allPlans.isEmpty {
                    emptyState
                } else {
                    planList
                }
            }
            .navigationTitle("Weekly Plans")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewPlan = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewPlan) {
                PlanEditorView(plan: nil)
            }
            .sheet(item: $planToEdit) { plan in
                PlanEditorView(plan: plan)
            }
            .alert("Delete Plan?", isPresented: $showDeleteConfirm, presenting: planToDelete) { plan in
                Button("Delete", role: .destructive) {
                    deletePlan(plan)
                }
                Button("Cancel", role: .cancel) {}
            } message: { plan in
                if plan.isActive {
                    Text("Deleting \"\(plan.name)\" will revert Today's Session to auto-generated workouts.")
                } else {
                    Text("This plan will be permanently deleted.")
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No plans yet.")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Create your first plan to schedule weekly workouts.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button(action: { showingNewPlan = true }) {
                Label("New Plan", systemImage: "plus")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var planList: some View {
        List {
            ForEach(allPlans) { plan in
                PlanCard(plan: plan,
                         onActivate: { activatePlan(plan) },
                         onEdit: { planToEdit = plan })
                    .contentShape(Rectangle())
                    .onTapGesture { planToEdit = plan }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            planToDelete = plan
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            planToEdit = plan
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
            }
        }
        .listStyle(.plain)
    }

    private func activatePlan(_ target: WorkoutPlan) {
        for plan in allPlans {
            plan.isActive = false
        }
        target.isActive = true
    }

    private func deletePlan(_ plan: WorkoutPlan) {
        modelContext.delete(plan)
    }
}

// MARK: - Plan Card

private struct PlanCard: View {
    let plan: WorkoutPlan
    let onActivate: () -> Void
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.name)
                        .font(.headline)
                    Text("\(plan.days.count) day\(plan.days.count == 1 ? "" : "s") · Tap to edit")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if plan.isActive {
                    Text("Active")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.15))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !plan.isActive {
                Button(action: onActivate) {
                    Text("Activate")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(plan.isActive ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
    }
}

// MARK: - Preview

#Preview("Weekly Planner — Empty") {
    WeeklyPlannerView()
        .modelContainer(for: [WorkoutPlan.self, PlanDay.self], inMemory: true)
}

#Preview("Weekly Planner — With Plans") {
    let container = try! ModelContainer(for: WorkoutPlan.self, PlanDay.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let plan1 = WorkoutPlan(name: "5-Day Physio")
    plan1.isActive = true
    let plan2 = WorkoutPlan(name: "3-Day Strength")
    container.mainContext.insert(plan1)
    container.mainContext.insert(plan2)
    return WeeklyPlannerView()
        .modelContainer(container)
}
