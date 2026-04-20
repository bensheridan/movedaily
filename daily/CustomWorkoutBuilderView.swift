import SwiftUI
import SwiftData

struct CustomWorkoutBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var allExercises: [Exercise]
    @Query private var savedCustomExercises: [CustomExercise]
    @Query private var profiles: [UserProfile]

    let sessionTier: SessionTier

    @State private var selectedCategories: Set<ExerciseCategory> = []
    @State private var selectedCustomExerciseIDs: Set<PersistentIdentifier> = []
    @State private var showAddForm = false
    @State private var newExerciseName = ""
    @State private var newExerciseValue = ""
    @State private var newExerciseUnit = "seconds"
    @State private var validationError: String? = nil

    // Paste & parse
    @State private var showPasteSection = false
    @State private var pastedText = ""
    @State private var isParsing = false
    @State private var parsedDays: [ParsedDayDisplay] = []
    @State private var expandedDayIDs: Set<UUID> = []
    @State private var selectedParsedIDs: Set<UUID> = []
    @State private var parseError: String? = nil
    @State private var builtSessionNames: [String] = []
    @State private var showingDetail = false

    private var profile: UserProfile? { profiles.first }

    private var activeInjuries: Set<String> {
        Set(profile?.activeInjuries ?? [])
    }

    private var estimatedDuration: Int {
        let categorySeconds = allExercises
            .filter { selectedCategories.contains($0.category) && isAllowed($0) }
            .map { $0.durationSeconds }
            .reduce(0, +)
        let savedLibrarySeconds = savedLibraryExercises
            .filter { selectedSavedExerciseIDs.contains($0.persistentModelID) }
            .map { $0.durationSeconds }
            .reduce(0, +)
        let customSeconds = savedCustomExercises
            .filter { selectedCustomExerciseIDs.contains($0.persistentModelID) }
            .map { ce in ce.unit == "sets" ? ce.durationSeconds * 45 : ce.durationSeconds }
            .reduce(0, +)
        return categorySeconds + savedLibrarySeconds + customSeconds
    }

    private var canBuild: Bool {
        !selectedCategories.isEmpty || !selectedCustomExerciseIDs.isEmpty || !selectedSavedExerciseIDs.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    categoriesSection
                    savedLibrarySection
                    pasteSection
                    customExercisesSection
                    buildButton
                }
                .padding()
            }
            .navigationTitle("Build Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .navigationDestination(isPresented: $showingDetail) {
                let augmentedExercises = allExercises + savedCustomExercises.map { ce in
                    let nominalSeconds = ce.unit == "sets" ? ce.durationSeconds * 45 : ce.durationSeconds
                    let description = ce.unit == "sets"
                        ? "\(ce.durationSeconds) set\(ce.durationSeconds == 1 ? "" : "s")"
                        : "Custom exercise"
                    return Exercise(
                        name: ce.name,
                        exerciseDescription: description,
                        durationSeconds: nominalSeconds,
                        category: .bodyweight,
                        instructions: [],
                        tips: []
                    )
                }
                RoutineDetailView(
                    routine: Routine(
                        name: "Custom Session",
                        routineDescription: "\(sessionTier.rawValue) · \(builtSessionNames.count) exercises",
                        exerciseNames: builtSessionNames
                    ),
                    allExercises: augmentedExercises,
                    profile: profile,
                    routineCompleted: { dismiss() }
                )
            }
        }
    }

    // MARK: - Categories Section

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercise Categories")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(ExerciseCategory.displayCategories) { category in
                    categoryTile(category)
                }
            }

            Text(estimatedDuration > 0 ? "Estimated duration: ~\(formattedDuration(estimatedDuration))" : "Select categories to estimate duration")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func categoryTile(_ category: ExerciseCategory) -> some View {
        let selected = selectedCategories.contains(category)
        return Button(action: { toggleCategory(category) }) {
            VStack(spacing: 10) {
                Image(systemName: category.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(selected ? .white : .blue)
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(selected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(selected ? Color.blue : Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected ? Color.clear : Color(uiColor: .separator).opacity(0.5), lineWidth: 0.5)
            )
        }
        .buttonStyle(DesignTokens.scaleButton)
    }

    // MARK: - Saved Library Exercises Section

    private var savedLibraryExercises: [Exercise] {
        let savedNames = Set(profile?.savedExerciseNames ?? [])
        guard !savedNames.isEmpty else { return [] }
        return allExercises.filter { savedNames.contains($0.name) }
    }

    @State private var selectedSavedExerciseIDs: Set<PersistentIdentifier> = []

    private var savedLibrarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saved Exercises")
                .font(.headline)

            if savedLibraryExercises.isEmpty {
                Text("Swipe any exercise in the category browser to save it here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(savedLibraryExercises) { exercise in
                    savedLibraryRow(exercise)
                }
            }
        }
    }

    private func savedLibraryRow(_ exercise: Exercise) -> some View {
        let selected = selectedSavedExerciseIDs.contains(exercise.persistentModelID)
        let blocked = !isAllowed(exercise)
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(blocked ? .secondary : .primary)
                HStack(spacing: 6) {
                    Text(exercise.category.rawValue)
                    Text("·")
                    Text("\(exercise.durationSeconds / 60)m \(exercise.durationSeconds % 60 > 0 ? "\(exercise.durationSeconds % 60)s" : "")")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                if blocked {
                    Text("Excluded by active injury")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            Spacer()
            Button(action: {
                guard !blocked else { return }
                if selectedSavedExerciseIDs.contains(exercise.persistentModelID) {
                    selectedSavedExerciseIDs.remove(exercise.persistentModelID)
                } else {
                    selectedSavedExerciseIDs.insert(exercise.persistentModelID)
                }
            }) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(blocked ? Color(UIColor.secondaryLabel) : (selected ? Color.blue : Color(UIColor.secondaryLabel)))
            }
            .disabled(blocked)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Custom Exercises Section

    private var customExercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Exercises")
                .font(.headline)

            if savedCustomExercises.isEmpty && !showAddForm {
                Text("No custom exercises yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(savedCustomExercises) { exercise in
                customExerciseRow(exercise)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            selectedCustomExerciseIDs.remove(exercise.persistentModelID)
                            modelContext.delete(exercise)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }

            if showAddForm {
                addExerciseForm
            } else {
                Button(action: { showAddForm = true }) {
                    Label("Add my own exercise", systemImage: "plus.circle")
                        .font(.subheadline)
                }
            }
        }
    }

    private func customExerciseRow(_ exercise: CustomExercise) -> some View {
        let selected = selectedCustomExerciseIDs.contains(exercise.persistentModelID)
        let label = exercise.unit == "sets"
            ? "\(exercise.durationSeconds) set\(exercise.durationSeconds == 1 ? "" : "s")"
            : formattedDuration(exercise.durationSeconds)
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: { toggleCustomExercise(exercise) }) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selected ? Color.blue : Color(UIColor.secondaryLabel))
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var addExerciseForm: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Exercise name", text: $newExerciseName)
                .textFieldStyle(.roundedBorder)

            Picker("Unit", selection: $newExerciseUnit) {
                Text("Seconds").tag("seconds")
                Text("Sets").tag("sets")
            }
            .pickerStyle(.segmented)

            TextField(newExerciseUnit == "sets" ? "Number of sets" : "Duration (seconds)", text: $newExerciseValue)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)

            if let error = validationError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Button("Cancel") {
                    showAddForm = false
                    newExerciseName = ""
                    newExerciseValue = ""
                    newExerciseUnit = "seconds"
                    validationError = nil
                }
                .foregroundStyle(.secondary)

                Spacer()

                Button("Save") { saveCustomExercise() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Build Button

    private var buildButton: some View {
        VStack(spacing: 8) {
            if !canBuild {
                Text("Select at least one category or custom exercise to build a session.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: buildSession) {
                Text("Build Session")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canBuild ? Color.blue : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(!canBuild)
            .buttonStyle(DesignTokens.scaleButton)
        }
    }

    // MARK: - Actions

    private func toggleCategory(_ category: ExerciseCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }

    private func toggleCustomExercise(_ exercise: CustomExercise) {
        if selectedCustomExerciseIDs.contains(exercise.persistentModelID) {
            selectedCustomExerciseIDs.remove(exercise.persistentModelID)
        } else {
            selectedCustomExerciseIDs.insert(exercise.persistentModelID)
        }
    }

    private func isAllowed(_ exercise: Exercise) -> Bool {
        activeInjuries.isEmpty || Set(exercise.contraindications).isDisjoint(with: activeInjuries)
    }

    private func saveCustomExercise() {
        let name = newExerciseName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else {
            validationError = "Please enter a name."
            return
        }
        let prompt = newExerciseUnit == "sets" ? "number of sets (e.g. 3)" : "duration in seconds (e.g. 60)"
        guard let value = Int(newExerciseValue), value > 0 else {
            validationError = "Please enter a valid \(prompt)."
            return
        }
        let exercise = CustomExercise(name: name, durationSeconds: value, unit: newExerciseUnit)
        modelContext.insert(exercise)
        selectedCustomExerciseIDs.insert(exercise.persistentModelID)
        newExerciseName = ""
        newExerciseValue = ""
        newExerciseUnit = "seconds"
        validationError = nil
        showAddForm = false
    }

    private func buildSession() {
        let budget = sessionTier.durationRange

        // Pool from selected categories, injury-filtered, shuffled
        var pool = allExercises
            .filter { selectedCategories.contains($0.category) && isAllowed($0) }
            .shuffled()

        var names: [String] = []
        var total = 0

        // Greedy fill
        for exercise in pool {
            if total >= budget.lowerBound { break }
            if total + exercise.durationSeconds <= budget.upperBound + 120 {
                names.append(exercise.name)
                total += exercise.durationSeconds
            }
        }

        // Fallback repeat if pool exhausted before lower bound
        if total < budget.lowerBound {
            var guard_ = 0
            while total < budget.lowerBound && guard_ < 200 {
                if pool.isEmpty { pool = allExercises.filter { selectedCategories.contains($0.category) && isAllowed($0) }.shuffled() }
                if let exercise = pool.first {
                    pool.removeFirst()
                    names.append(exercise.name)
                    total += exercise.durationSeconds
                }
                guard_ += 1
            }
        }

        // Append selected saved library exercises (not already in the greedy fill)
        let selectedNamesFromFill = Set(names)
        let savedLibraryNames = savedLibraryExercises
            .filter { selectedSavedExerciseIDs.contains($0.persistentModelID) && !selectedNamesFromFill.contains($0.name) }
            .map { $0.name }
        names.append(contentsOf: savedLibraryNames)

        // Append selected custom exercises
        let customNames = savedCustomExercises
            .filter { selectedCustomExerciseIDs.contains($0.persistentModelID) }
            .map { $0.name }
        names.append(contentsOf: customNames)

        if !names.isEmpty {
            builtSessionNames = names
            showingDetail = true
        }
    }

    // MARK: - Paste & Parse Section

    struct ParsedDisplayItem: Identifiable {
        let id = UUID()
        let name: String
        let value: Int
        let unit: String
    }

    struct ParsedDayDisplay: Identifiable {
        let id = UUID()
        let name: String
        let items: [ParsedDisplayItem]
    }

    private var pasteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: { withAnimation { showPasteSection.toggle() } }) {
                HStack {
                    Label("Paste a workout", systemImage: "doc.text.below.ecg")
                        .font(.headline)
                    Spacer()
                    Image(systemName: showPasteSection ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)

            if showPasteSection {
                TextEditor(text: $pastedText)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color(uiColor: .separator).opacity(0.5), lineWidth: 0.5)
                    )
                    .overlay(alignment: .topLeading) {
                        if pastedText.isEmpty {
                            Text("Paste or type a workout here — e.g. from a website, screenshot, or your own notes.")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                                .padding(14)
                                .allowsHitTesting(false)
                        }
                    }

                if let error = parseError {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Button(action: { Task { await parseWorkout() } }) {
                    HStack {
                        if isParsing {
                            ProgressView()
                                .tint(.white)
                                .padding(.trailing, 4)
                        } else {
                            Image(systemName: "doc.text.magnifyingglass")
                        }
                        Text(isParsing ? "Extracting…" : "Extract Exercises")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.indigo)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(DesignTokens.scaleButton)
                .disabled(pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isParsing)

                if !parsedDays.isEmpty {
                    let allItems = parsedDays.flatMap(\.items)
                    let totalCount = allItems.count
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Found \(totalCount) exercise\(totalCount == 1 ? "" : "s")")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Button("Select All") {
                                selectedParsedIDs = Set(allItems.map(\.id))
                            }
                            .font(.caption)
                        }

                        ForEach(parsedDays) { day in
                            parsedDaySection(day)
                        }

                        Button(action: addSelectedParsedExercises) {
                            Text("Add Selected to My Exercises")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selectedParsedIDs.isEmpty ? Color.gray : Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(DesignTokens.scaleButton)
                        .disabled(selectedParsedIDs.isEmpty)
                    }
                }
            }
        }
    }

    private func parsedDaySection(_ day: ParsedDayDisplay) -> some View {
        let isExpanded = expandedDayIDs.contains(day.id)
        let allSelected = day.items.allSatisfy { selectedParsedIDs.contains($0.id) }
        return VStack(alignment: .leading, spacing: 6) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded { expandedDayIDs.remove(day.id) }
                    else { expandedDayIDs.insert(day.id) }
                }
            }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 14)
                    Text(day.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    Text("(\(day.items.count))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(allSelected ? "Deselect All" : "Add All") {
                        if allSelected {
                            day.items.forEach { selectedParsedIDs.remove($0.id) }
                        } else {
                            day.items.forEach { selectedParsedIDs.insert($0.id) }
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.blue)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                ForEach(Array(day.items.enumerated()), id: \.element.id) { index, item in
                    parsedItemRow(item)
                    if index < day.items.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func parsedItemRow(_ item: ParsedDisplayItem) -> some View {
        let selected = selectedParsedIDs.contains(item.id)
        let label = item.unit == "sets"
            ? "\(item.value) set\(item.value == 1 ? "" : "s")"
            : formattedDuration(item.value)
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: {
                if selected { selectedParsedIDs.remove(item.id) }
                else { selectedParsedIDs.insert(item.id) }
            }) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selected ? Color.blue : Color(UIColor.secondaryLabel))
            }
        }
        .padding(.vertical, 8)
    }

    private func parseWorkout() async {
        parseError = nil
        isParsing = true
        defer { isParsing = false }
        do {
            let days = try await WorkoutParser.parse(text: pastedText)
            parsedDays = days.map { day in
                ParsedDayDisplay(
                    name: day.name,
                    items: day.exercises.map { ParsedDisplayItem(name: $0.name, value: $0.value, unit: $0.unit) }
                )
            }
            // Expand first day by default, select all items
            if let first = parsedDays.first {
                expandedDayIDs = [first.id]
            }
            selectedParsedIDs = Set(parsedDays.flatMap(\.items).map(\.id))
        } catch {
            parseError = error.localizedDescription
            parsedDays = []
            expandedDayIDs = []
            selectedParsedIDs = []
        }
    }

    private func addSelectedParsedExercises() {
        for item in parsedDays.flatMap(\.items) where selectedParsedIDs.contains(item.id) {
            let exercise = CustomExercise(name: item.name, durationSeconds: item.value, unit: item.unit)
            modelContext.insert(exercise)
            selectedCustomExerciseIDs.insert(exercise.persistentModelID)
        }
        parsedDays = []
        expandedDayIDs = []
        selectedParsedIDs = []
        pastedText = ""
        withAnimation { showPasteSection = false }
    }

    private func formattedDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        if secs == 0 { return "\(minutes) min" }
        return "\(minutes)m \(secs)s"
    }
}

#Preview {
    CustomWorkoutBuilderView(sessionTier: .basic)
        .modelContainer(for: [Exercise.self, CustomExercise.self, UserProfile.self, Routine.self], inMemory: true)
}
