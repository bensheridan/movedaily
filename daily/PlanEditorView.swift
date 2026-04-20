import SwiftUI
import SwiftData

// MARK: - Draft Type

/// Value-type draft used while the editor is open. Converted to PlanDay only on save.
struct DraftPlanDay: Identifiable {
    let id: UUID
    var name: String
    var weekdays: [Int]
    var exercises: [PlanExercise]
    /// Non-nil when editing an existing persisted PlanDay.
    var sourceModelID: PersistentIdentifier?

    init(id: UUID = UUID(), name: String, weekdays: [Int] = [], exercises: [PlanExercise] = [], sourceModelID: PersistentIdentifier? = nil) {
        self.id = id
        self.name = name
        self.weekdays = weekdays
        self.exercises = exercises
        self.sourceModelID = sourceModelID
    }
}

// MARK: - Plan Editor View

struct PlanEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutPlan.createdAt, order: .forward) private var allPlans: [WorkoutPlan]

    let plan: WorkoutPlan?  // nil = create mode

    @State private var planName: String = ""
    @State private var activateOnSave: Bool = false
    @State private var days: [DraftPlanDay] = []

    @State private var showingDayBuilder = false
    @State private var dayToEdit: DraftPlanDay? = nil

    @State private var showImport = false
    @State private var pastedText = ""
    @State private var isParsing = false
    @State private var parseError: String? = nil
    @State private var parsedDays: [ParsedDay] = []
    @State private var weekdaySelections: [UUID: Set<Int>] = [:]
    @State private var parsedDayIDs: [UUID] = []

    private var isEditMode: Bool { plan != nil }

    private var takenWeekdays: Set<Int> {
        Set(days.flatMap(\.weekdays))
    }

    private var saveHint: String? {
        let name = planName.trimmingCharacters(in: .whitespaces)
        if name.isEmpty && days.isEmpty { return "Enter a plan name and add at least one day." }
        if name.isEmpty { return "Enter a plan name to save." }
        if days.isEmpty { return "Add at least one workout day to save." }
        return nil
    }

    private var canSave: Bool { saveHint == nil }

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                daysSection
                importSection
                activateSection
            }
            .navigationTitle(isEditMode ? "Edit Plan" : "New Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { savePlan() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                        .help(saveHint ?? "")
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let hint = saveHint {
                    Text(hint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(.ultraThinMaterial)
                        .frame(maxWidth: .infinity)
                }
            }
            .onAppear {
                if let plan {
                    planName = plan.name
                    activateOnSave = plan.isActive
                    days = plan.days.map {
                        DraftPlanDay(name: $0.name, weekdays: $0.weekdays, exercises: $0.exercises, sourceModelID: $0.persistentModelID)
                    }
                }
            }
            .sheet(isPresented: $showingDayBuilder) {
                let editingWeekdays = dayToEdit.map { Set($0.weekdays) } ?? []
                PlanDayBuilderView(
                    existingDay: dayToEdit,
                    takenWeekdays: takenWeekdays.subtracting(editingWeekdays)
                ) { saved in
                    if let idx = days.firstIndex(where: { $0.id == saved.id }) {
                        days[idx] = saved
                    } else {
                        days.append(saved)
                    }
                    dayToEdit = nil
                }
            }
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        Section("Plan Name") {
            TextField("e.g. 5-Day Physio", text: $planName)
        }
    }

    private var daysSection: some View {
        Section {
            if days.isEmpty {
                Text("No days added yet.")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            } else {
                ForEach(days) { day in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(day.name)
                                .font(.subheadline)
                            Text(weekdayLabel(day.weekdays))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { dayToEdit = day; showingDayBuilder = true }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            days.removeAll { $0.id == day.id }
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
            }

            Button(action: { dayToEdit = nil; showingDayBuilder = true }) {
                Label("Add a day manually", systemImage: "plus.circle")
            }
        } header: {
            Text("Workout Days")
        }
    }

    private var importSection: some View {
        Section {
            DisclosureGroup("Import a program", isExpanded: $showImport) {
                VStack(alignment: .leading, spacing: 12) {
                    TextEditor(text: $pastedText)
                        .frame(minHeight: 100)
                        .font(.subheadline)
                        .overlay(alignment: .topLeading) {
                            if pastedText.isEmpty {
                                Text("Paste a workout program here…")
                                    .foregroundStyle(Color(uiColor: .placeholderText))
                                    .font(.subheadline)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }

                    if let err = parseError {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    Button(action: extractExercises) {
                        if isParsing {
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            Label("Extract & Schedule", systemImage: "doc.text.magnifyingglass")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(pastedText.trimmingCharacters(in: .whitespaces).isEmpty || isParsing)
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, 4)

                if !parsedDays.isEmpty {
                    parsedDaysSection
                }
            }
        }
    }

    private var activateSection: some View {
        Section {
            Toggle("Activate on save", isOn: $activateOnSave)
        } footer: {
            Text("Only one plan can be active at a time. Activating this plan will deactivate any current plan.")
        }
    }

    // MARK: - Parsed Days Section

    private var parsedDaysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            Text("Extracted Days")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.top, 4)

            Button(action: addAllExtractedDays) {
                Label("Add All to Plan", systemImage: "tray.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            ForEach(Array(zip(parsedDayIDs, parsedDays)), id: \.0) { uid, pDay in
                ParsedDayCard(
                    parsedDay: pDay,
                    takenWeekdays: takenWeekdays,
                    selectedWeekdays: Binding(
                        get: { weekdaySelections[uid] ?? [] },
                        set: { weekdaySelections[uid] = $0 }
                    ),
                    onAdd: { addExtractedDay(pDay, uid: uid) }
                )
            }
        }
    }

    // MARK: - Actions

    private func extractExercises() {
        isParsing = true
        parseError = nil
        parsedDays = []
        parsedDayIDs = []
        weekdaySelections = [:]
        Task {
            do {
                let result = try await WorkoutParser.parse(text: pastedText)
                await MainActor.run {
                    parsedDays = result
                    parsedDayIDs = result.map { _ in UUID() }
                    isParsing = false
                }
            } catch {
                await MainActor.run {
                    parseError = (error as? WorkoutParserError)?.errorDescription ?? error.localizedDescription
                    isParsing = false
                }
            }
        }
    }

    private func addExtractedDay(_ pd: ParsedDay, uid: UUID) {
        let selected = weekdaySelections[uid] ?? []
        let planExercises = pd.exercises.map { PlanExercise(name: $0.name, value: $0.value, unit: $0.unit) }
        days.append(DraftPlanDay(name: pd.name, weekdays: Array(selected).sorted(), exercises: planExercises))
        // Remove from parsed list so it can't be added again
        if let idx = parsedDayIDs.firstIndex(of: uid) {
            parsedDays.remove(at: idx)
            parsedDayIDs.remove(at: idx)
            weekdaySelections.removeValue(forKey: uid)
        }
    }

    private func addAllExtractedDays() {
        // Auto-assign weekdays Mon→Sun for days that have none selected
        let weekdayOrder = [2, 3, 4, 5, 6, 7, 1]
        var nextAvailable = weekdayOrder.filter { !takenWeekdays.contains($0) }

        for (idx, pd) in parsedDays.enumerated() {
            let uid = parsedDayIDs[idx]
            let manualSelection = weekdaySelections[uid] ?? []
            var weekdays: [Int]
            if !manualSelection.isEmpty {
                weekdays = Array(manualSelection).sorted()
            } else if let next = nextAvailable.first {
                weekdays = [next]
                nextAvailable.removeFirst()
            } else {
                weekdays = []
            }
            let planExercises = pd.exercises.map { PlanExercise(name: $0.name, value: $0.value, unit: $0.unit) }
            days.append(DraftPlanDay(name: pd.name, weekdays: weekdays, exercises: planExercises))
        }
        parsedDays = []
        parsedDayIDs = []
        weekdaySelections = [:]
    }

    private func savePlan() {
        let trimmedName = planName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, !days.isEmpty else { return }

        if activateOnSave {
            allPlans.forEach { $0.isActive = false }
        }

        if let plan {
            plan.name = trimmedName
            if activateOnSave { plan.isActive = true }

            let persistedIDs = Set(plan.days.map(\.persistentModelID))
            let keptSourceIDs = Set(days.compactMap(\.sourceModelID))

            // Delete days that were removed
            for day in plan.days where !keptSourceIDs.contains(day.persistentModelID) {
                modelContext.delete(day)
            }
            // Update kept days
            for draft in days {
                if let sid = draft.sourceModelID,
                   let existing = plan.days.first(where: { $0.persistentModelID == sid }) {
                    existing.name = draft.name
                    existing.weekdays = draft.weekdays
                    existing.exercises = draft.exercises
                }
            }
            // Insert new days
            for draft in days where draft.sourceModelID == nil {
                let newDay = PlanDay(name: draft.name, weekdays: draft.weekdays, exercises: draft.exercises)
                newDay.plan = plan
                modelContext.insert(newDay)
            }
        } else {
            let newPlan = WorkoutPlan(name: trimmedName)
            if activateOnSave { newPlan.isActive = true }
            modelContext.insert(newPlan)
            for draft in days {
                let day = PlanDay(name: draft.name, weekdays: draft.weekdays, exercises: draft.exercises)
                day.plan = newPlan
                modelContext.insert(day)
            }
        }

        dismiss()
    }

    private func weekdayLabel(_ weekdays: [Int]) -> String {
        guard !weekdays.isEmpty else { return "No days assigned" }
        let symbols = Calendar.current.shortWeekdaySymbols
        return weekdays.compactMap { wd in
            guard wd >= 1 && wd <= 7 else { return nil }
            return symbols[wd - 1]
        }.joined(separator: ", ")
    }
}

// MARK: - Parsed Day Card

private struct ParsedDayCard: View {
    let parsedDay: ParsedDay
    let takenWeekdays: Set<Int>
    @Binding var selectedWeekdays: Set<Int>
    let onAdd: () -> Void

    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols
    private let displayOrder = [2, 3, 4, 5, 6, 7, 1]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(parsedDay.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("\(parsedDay.exercises.count) exercise\(parsedDay.exercises.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: onAdd) {
                    Text("Add")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundStyle(Color.white)
                        .clipShape(Capsule())
                }
            }

            if selectedWeekdays.isEmpty {
                Text("Tap a day to assign, or just Add now and assign later.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                ForEach(displayOrder, id: \.self) { wd in
                    let symbol = weekdaySymbols[wd - 1]
                    let isTaken = takenWeekdays.contains(wd) && !selectedWeekdays.contains(wd)
                    let isSelected = selectedWeekdays.contains(wd)

                    Text(symbol)
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 30, height: 30)
                        .background(
                            isSelected ? Color.blue :
                            isTaken ? Color(uiColor: .tertiarySystemGroupedBackground) :
                            Color(uiColor: .secondarySystemGroupedBackground)
                        )
                        .foregroundStyle(isSelected ? Color.white : isTaken ? Color(uiColor: .tertiaryLabel) : Color.primary)
                        .clipShape(Circle())
                        .opacity(isTaken ? 0.5 : 1.0)
                        .onTapGesture {
                            guard !isTaken else { return }
                            if isSelected { selectedWeekdays.remove(wd) }
                            else { selectedWeekdays.insert(wd) }
                        }
                }
            }
        }
        .padding(12)
        .background(Color(uiColor: .tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Preview

#Preview("Plan Editor — Create") {
    PlanEditorView(plan: nil)
        .modelContainer(for: [WorkoutPlan.self, PlanDay.self], inMemory: true)
}
