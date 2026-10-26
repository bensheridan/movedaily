import SwiftUI
import SwiftData

// MARK: - Dashboard Section

/// Dashboard section listing the user's This-for-That pacts with quick "Did it" / "Enjoy" actions.
struct ThisForThatSection: View {
    @Query(sort: \ThisForThat.createdAt, order: .forward) private var pacts: [ThisForThat]
    @Query private var allExercises: [Exercise]

    @State private var showingManager = false
    @State private var showingNewPact = false
    @State private var earnedPact: ThisForThat? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("This for That")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                if !pacts.isEmpty {
                    Button("Manage") { showingManager = true }
                        .font(.subheadline)
                }
            }
            .padding(.horizontal)

            if pacts.isEmpty {
                emptyCard
            } else {
                VStack(spacing: 10) {
                    ForEach(pacts) { pact in
                        ThisForThatRow(
                            pact: pact,
                            exercise: allExercises.first { $0.name == pact.thisAction },
                            onDone: {
                                if pact.markDone() {
                                    earnedPact = pact
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showingManager) {
            ThisForThatManagerView()
        }
        .sheet(isPresented: $showingNewPact) {
            ThisForThatEditorView(pact: nil)
        }
        .sheet(item: $earnedPact) { pact in
            TreatEarnedView(pact: pact)
                .presentationDetents([.medium])
        }
    }

    private var emptyCard: some View {
        Button(action: { showingNewPact = true }) {
            HStack(spacing: 14) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.pink)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reward yourself")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("e.g. Shoulder stretches → Chocolate bar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.pink)
            }
            .padding(DesignTokens.cardPadding)
            .frame(maxWidth: .infinity)
            .cardStyle()
        }
        .buttonStyle(DesignTokens.scaleButton)
        .padding(.horizontal)
    }
}

// MARK: - Row

struct ThisForThatRow: View {
    let pact: ThisForThat
    /// The library exercise matching "This", if any — lets the user jump straight into the timer.
    let exercise: Exercise?
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("THIS")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    Text(pact.thisAction)
                        .font(.headline)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("THAT")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    Label(pact.thatTreat, systemImage: pact.treatIcon)
                        .font(.headline)
                        .foregroundStyle(.pink)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            ThisForThatProgressView(pact: pact)

            HStack(spacing: 8) {
                if let exercise {
                    NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                        Label("Start", systemImage: "play.fill")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(DesignTokens.scaleButton)
                }

                Button(action: onDone) {
                    Label(doneButtonTitle, systemImage: "checkmark")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(lockedForToday ? Color.green.opacity(0.5) : Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(DesignTokens.scaleButton)
                .disabled(lockedForToday)
                .sensoryFeedback(.success, trigger: pact.timesEarned)
                .sensoryFeedback(.selection, trigger: pact.completionDates.count)

                Spacer()

                if pact.bankedTreats > 0 {
                    Button(action: { pact.claimTreat() }) {
                        HStack(spacing: 4) {
                            Text("Enjoy")
                            Text("\(pact.bankedTreats)")
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .background(Color.white.opacity(0.3))
                                .clipShape(Capsule())
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.pink)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(DesignTokens.scaleButton)
                    .sensoryFeedback(.impact, trigger: pact.timesClaimed)
                }
            }
        }
        .padding(DesignTokens.cardPadding)
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    /// Weekly pacts count each day once, so further taps today do nothing.
    private var lockedForToday: Bool {
        pact.isWeekly && pact.doneToday
    }

    private var doneButtonTitle: String {
        if lockedForToday { return "Done today" }
        return !pact.isWeekly && pact.doneToday ? "Done again" : "I did it"
    }
}

// MARK: - Progress

/// Weekly pacts show a dot per day of the week; per-session pacts show a progress bar.
struct ThisForThatProgressView: View {
    let pact: ThisForThat

    var body: some View {
        let progress = pact.progress
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(pact.goalLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(statusText(progress))
                    .font(.caption)
                    .foregroundStyle(pact.isWeekly && pact.rewardedThisWeek ? .pink : .secondary)
            }

            if pact.isWeekly {
                weekDots
            } else if progress.target > 1 {
                ProgressView(value: Double(progress.done), total: Double(progress.target))
                    .tint(.green)
            }
        }
    }

    private func statusText(_ progress: (done: Int, target: Int)) -> String {
        if pact.isWeekly {
            if pact.rewardedThisWeek { return "Treat earned this week" }
            return "\(progress.done) of \(progress.target) days"
        }
        return progress.target > 1 ? "\(progress.done) of \(progress.target)" : ""
    }

    private var weekDots: some View {
        let done = pact.daysDoneThisWeek
        let calendar = Calendar.current
        let symbols = calendar.veryShortWeekdaySymbols
        return HStack(spacing: 6) {
            ForEach(ThisForThat.currentWeekDays, id: \.self) { day in
                let isDone = done.contains(calendar.startOfDay(for: day))
                let isToday = calendar.isDateInToday(day)
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(isDone ? Color.green : Color(uiColor: .secondarySystemGroupedBackground))
                        if isDone {
                            Image(systemName: "checkmark")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 26, height: 26)
                    .overlay(
                        Circle().stroke(isToday ? Color.green : Color.clear, lineWidth: 2)
                    )
                    Text(symbols[calendar.component(.weekday, from: day) - 1])
                        .font(.caption2)
                        .foregroundStyle(isToday ? .primary : .secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Treat Earned

struct TreatEarnedView: View {
    let pact: ThisForThat
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: pact.treatIcon)
                .font(.system(size: 64))
                .foregroundStyle(.pink)
                .symbolEffect(.bounce, value: pact.timesEarned)

            VStack(spacing: 8) {
                Text("Treat earned!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text(earnedMessage)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Text("\(pact.bankedTreats) waiting · \(pact.timesEarned) earned all-time")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    Text("Save for later")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                Button(action: {
                    pact.claimTreat()
                    dismiss()
                }) {
                    Text("Enjoy now")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pink)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .buttonStyle(DesignTokens.scaleButton)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}

extension TreatEarnedView {
    private var earnedMessage: String {
        let action = pact.thisAction.lowercased()
        let treat = pact.thatTreat.lowercased()
        if pact.isWeekly {
            return "You did \(action) \(pact.targetCount) day\(pact.targetCount == 1 ? "" : "s") this week — you've earned \(treat)."
        }
        if pact.targetCount > 1 {
            return "You did \(action) \(pact.targetCount) times — you've earned \(treat)."
        }
        return "You did \(action) — you've earned \(treat)."
    }
}

// MARK: - Manager

struct ThisForThatManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ThisForThat.createdAt, order: .forward) private var pacts: [ThisForThat]

    @State private var showingNewPact = false
    @State private var pactToEdit: ThisForThat? = nil

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(pacts) { pact in
                        Button(action: { pactToEdit = pact }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(pact.thisAction) → \(pact.thatTreat)")
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    Text("\(pact.goalLabel) · \(pact.timesEarned) earned · \(pact.timesClaimed) enjoyed")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: pact.treatIcon)
                                    .foregroundStyle(.pink)
                            }
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            modelContext.delete(pacts[index])
                        }
                    }
                } footer: {
                    Text("Do This to earn That. Hit your goal — every time, every few times, or a number of days a week — to bank a treat to enjoy when you like.")
                }
            }
            .navigationTitle("This for That")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewPact = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewPact) {
                ThisForThatEditorView(pact: nil)
            }
            .sheet(item: $pactToEdit) { pact in
                ThisForThatEditorView(pact: pact)
            }
        }
    }
}

// MARK: - Editor

struct ThisForThatEditorView: View {
    let pact: ThisForThat?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    @State private var thisAction = ""
    @State private var thatTreat = ""
    @State private var treatIcon = "gift.fill"
    @State private var isWeekly = true
    @State private var targetCount = 5

    private var canSave: Bool {
        !thisAction.trimmingCharacters(in: .whitespaces).isEmpty
            && !thatTreat.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g. Shoulder stretches", text: $thisAction)
                    if !allExercises.isEmpty {
                        Menu {
                            ForEach(ExerciseCategory.displayCategories) { category in
                                let names = allExercises.filter { $0.category == category }.map(\.name)
                                if !names.isEmpty {
                                    Menu(category.rawValue) {
                                        ForEach(names, id: \.self) { name in
                                            Button(name) { thisAction = name }
                                        }
                                    }
                                }
                            }
                        } label: {
                            Label("Pick from exercise library", systemImage: "list.bullet")
                        }
                    }
                } header: {
                    Text("This — the habit")
                }

                Section {
                    TextField("e.g. Chocolate bar", text: $thatTreat)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                        ForEach(ThisForThat.treatIcons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title3)
                                .frame(width: 36, height: 36)
                                .foregroundStyle(treatIcon == icon ? .white : .pink)
                                .background(treatIcon == icon ? Color.pink : Color.clear)
                                .clipShape(Circle())
                                .onTapGesture { treatIcon = icon }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("That — the treat")
                }

                Section {
                    Picker("Goal", selection: $isWeekly) {
                        Text("Per week").tag(true)
                        Text("Per session").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: isWeekly) {
                        targetCount = isWeekly ? min(targetCount, 7) : targetCount
                    }

                    if isWeekly {
                        Stepper("\(targetCount) day\(targetCount == 1 ? "" : "s") a week", value: $targetCount, in: 1...7)
                    } else {
                        Stepper(targetCount == 1 ? "Every time" : "Every \(targetCount) times", value: $targetCount, in: 1...30)
                    }
                } header: {
                    Text("Earn it")
                } footer: {
                    Text(isWeekly
                        ? "Do This on \(targetCount) different day\(targetCount == 1 ? "" : "s") in a week to earn one treat. Progress resets each week."
                        : "Earn one treat every \(targetCount == 1 ? "time" : "\(targetCount) times") you do This.")
                }
            }
            .navigationTitle(pact == nil ? "New This for That" : "Edit This for That")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                }
            }
            .onAppear {
                if let pact {
                    thisAction = pact.thisAction
                    thatTreat = pact.thatTreat
                    treatIcon = pact.treatIcon
                    isWeekly = pact.isWeekly
                    targetCount = pact.targetCount
                }
            }
        }
    }

    private func save() {
        let action = thisAction.trimmingCharacters(in: .whitespaces)
        let treat = thatTreat.trimmingCharacters(in: .whitespaces)
        if let pact {
            pact.thisAction = action
            pact.thatTreat = treat
            pact.treatIcon = treatIcon
            if pact.isWeekly != isWeekly || pact.targetCount != targetCount {
                pact.sessionProgress = min(pact.sessionProgress, targetCount - 1)
            }
            pact.isWeekly = isWeekly
            pact.targetCount = targetCount
        } else {
            modelContext.insert(ThisForThat(
                thisAction: action,
                thatTreat: treat,
                treatIcon: treatIcon,
                isWeekly: isWeekly,
                targetCount: targetCount
            ))
        }
        dismiss()
    }
}

// MARK: - Previews

#Preview("This for That — Section") {
    let container = try! ModelContainer(
        for: ThisForThat.self, Exercise.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let pact = ThisForThat(thisAction: "Shoulder stretches", thatTreat: "Chocolate bar", treatIcon: "birthday.cake.fill", isWeekly: true, targetCount: 5)
    pact.completionDates = ThisForThat.currentWeekDays.prefix(2).map { $0 }
    pact.timesEarned = 3
    pact.timesClaimed = 1
    container.mainContext.insert(pact)
    container.mainContext.insert(ThisForThat(thisAction: "Push-ups", thatTreat: "Coffee", treatIcon: "cup.and.saucer.fill", targetCount: 3))
    return NavigationStack {
        ScrollView { ThisForThatSection().padding(.vertical) }
    }
    .modelContainer(container)
}

#Preview("This for That — Empty") {
    NavigationStack {
        ThisForThatSection()
    }
    .modelContainer(for: [ThisForThat.self, Exercise.self], inMemory: true)
}

#Preview("Treat Earned") {
    TreatEarnedView(pact: ThisForThat(thisAction: "Shoulder stretches", thatTreat: "Chocolate bar"))
}

#Preview("Editor") {
    ThisForThatEditorView(pact: nil)
        .modelContainer(for: [ThisForThat.self, Exercise.self], inMemory: true)
}
