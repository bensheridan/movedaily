import SwiftUI
import SwiftData

// MARK: - Plan Day Builder View

struct PlanDayBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var allExercises: [Exercise]
    @Query private var customExercises: [CustomExercise]

    let existingDay: DraftPlanDay?
    let takenWeekdays: Set<Int>
    let onSave: (DraftPlanDay) -> Void

    // Day fields
    @State private var dayName: String = ""
    @State private var selectedWeekdays: Set<Int> = []
    @State private var selectedCategories: Set<ExerciseCategory> = []
    @State private var selectedCustomIDs: Set<PersistentIdentifier> = []

    // Custom exercise inline form
    @State private var showAddCustom = false
    @State private var newName = ""
    @State private var newValue = ""
    @State private var newUnit = "seconds"
    @State private var customValidationError: String? = nil

    private let displayOrder = [2, 3, 4, 5, 6, 7, 1]  // Mon–Sun in Calendar.weekday ints

    private var canSave: Bool {
        !dayName.trimmingCharacters(in: .whitespaces).isEmpty && !selectedWeekdays.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                weekdaySection
                categorySection
                customExercisesSection
                if showAddCustom {
                    addCustomSection
                }
            }
            .navigationTitle(existingDay == nil ? "Add Day" : "Edit Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveDay() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
            .onAppear { populateFromExisting() }
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        Section("Day Name") {
            TextField("e.g. Day 1 – Upper Body", text: $dayName)
        }
    }

    private var weekdaySection: some View {
        Section {
            HStack(spacing: 8) {
                ForEach(displayOrder, id: \.self) { wd in
                    let symbol = Calendar.current.veryShortWeekdaySymbols[wd - 1]
                    let isTaken = takenWeekdays.contains(wd)
                    let isSelected = selectedWeekdays.contains(wd)

                    Text(symbol)
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 36, height: 36)
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
            .padding(.vertical, 4)

            if selectedWeekdays.isEmpty {
                Text("Select at least one day to save.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        } header: {
            Text("Assigned Days")
        }
    }

    private var categorySection: some View {
        Section("Exercise Categories") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(ExerciseCategory.displayCategories) { cat in
                    let isSelected = selectedCategories.contains(cat)
                    Button(action: {
                        if isSelected { selectedCategories.remove(cat) }
                        else { selectedCategories.insert(cat) }
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: cat.icon)
                                .font(.system(size: 24))
                                .foregroundStyle(isSelected ? .white : .blue)
                            Text(cat.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(isSelected ? .white : .primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isSelected ? Color.blue : Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)

            let catCount = selectedCategories.reduce(0) { count, cat in
                count + allExercises.filter({ $0.category == cat }).count
            }
            if !selectedCategories.isEmpty {
                Text("\(catCount) exercise\(catCount == 1 ? "" : "s") from selected categories will be added.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var customExercisesSection: some View {
        Section {
            if customExercises.isEmpty {
                Text("No saved custom exercises yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(customExercises) { ce in
                    let isSelected = selectedCustomIDs.contains(ce.persistentModelID)
                    Toggle(isOn: Binding(
                        get: { isSelected },
                        set: { on in
                            if on { selectedCustomIDs.insert(ce.persistentModelID) }
                            else { selectedCustomIDs.remove(ce.persistentModelID) }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ce.name)
                                .font(.subheadline)
                            Text(ce.unit == "sets" ? "\(ce.durationSeconds) sets" : "\(ce.durationSeconds) sec")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            selectedCustomIDs.remove(ce.persistentModelID)
                            modelContext.delete(ce)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }

            Button(action: { showAddCustom.toggle() }) {
                Label(showAddCustom ? "Hide form" : "Add custom exercise", systemImage: showAddCustom ? "chevron.up" : "plus.circle")
                    .font(.subheadline)
            }
        } header: {
            Text("My Exercises")
        }
    }

    private var addCustomSection: some View {
        Section("New Custom Exercise") {
            TextField("Exercise name", text: $newName)

            Picker("Unit", selection: $newUnit) {
                Text("Seconds").tag("seconds")
                Text("Sets").tag("sets")
            }
            .pickerStyle(.segmented)

            TextField(newUnit == "seconds" ? "Duration (seconds)" : "Number of sets", text: $newValue)
                .keyboardType(.numberPad)

            if let err = customValidationError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button("Save Custom Exercise") {
                saveCustomExercise()
            }
            .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty || newValue.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    // MARK: - Actions

    private func populateFromExisting() {
        guard let day = existingDay else { return }
        dayName = day.name
        selectedWeekdays = Set(day.weekdays)
        // We can't easily reverse-map exercises back to categories, so leave categories empty for edit
    }

    private func saveCustomExercise() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        guard let value = Int(newValue.trimmingCharacters(in: .whitespaces)), value > 0 else {
            customValidationError = "Enter a valid number greater than 0."
            return
        }
        customValidationError = nil
        let ce = CustomExercise(name: name, durationSeconds: value, unit: newUnit)
        modelContext.insert(ce)
        selectedCustomIDs.insert(ce.persistentModelID)
        newName = ""
        newValue = ""
        showAddCustom = false
    }

    private func saveDay() {
        let name = dayName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !selectedWeekdays.isEmpty else { return }

        var planExercises: [PlanExercise] = existingDay?.exercises ?? []

        for cat in ExerciseCategory.displayCategories where selectedCategories.contains(cat) {
            planExercises += allExercises.filter { $0.category == cat }
                .map { PlanExercise(name: $0.name, value: $0.durationSeconds, unit: "seconds") }
        }
        for ce in customExercises where selectedCustomIDs.contains(ce.persistentModelID) {
            planExercises.append(PlanExercise(name: ce.name, value: ce.durationSeconds, unit: ce.unit))
        }

        let draft = DraftPlanDay(
            id: existingDay?.id ?? UUID(),
            name: name,
            weekdays: Array(selectedWeekdays).sorted(),
            exercises: planExercises,
            sourceModelID: existingDay?.sourceModelID
        )
        onSave(draft)
        dismiss()
    }
}

// MARK: - Preview

#Preview("Plan Day Builder — New") {
    PlanDayBuilderView(
        existingDay: nil,
        takenWeekdays: [2, 3],
        onSave: { _ in }
    )
    .modelContainer(for: [Exercise.self, CustomExercise.self, WorkoutPlan.self, PlanDay.self], inMemory: true)
}
