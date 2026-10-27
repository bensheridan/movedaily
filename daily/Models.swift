import Foundation
import SwiftData
import UIKit

enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
    case stretching = "Stretching"
    case breathing = "Breathing"
    case bodyweight = "Bodyweight"
    case kegels = "Kegels"   // ⚠️ Kept for SwiftData backward-compat only — NOT shown on dashboard
    case balance = "Balance"

    var id: String { self.rawValue }

    /// The categories shown on the dashboard grid.
    /// `.kegels` is excluded — it is retained only so SwiftData can decode
    /// existing exercises stored with the old "Kegels" raw value.
    static var displayCategories: [ExerciseCategory] {
        [.stretching, .breathing, .bodyweight, .balance]
    }

    var icon: String {
        switch self {
        case .stretching: return "figure.flexibility"
        case .breathing: return "wind"
        case .bodyweight: return "figure.strengthtraining.traditional"
        case .kegels: return "figure.highintensity.intervaltraining"
        case .balance: return "figure.stand"
        }
    }
}

enum Gender: String, Codable, CaseIterable, Identifiable {
    case male = "Male"
    case female = "Female"
    case unspecified = "Unspecified"

    var id: String { self.rawValue }
}

enum Difficulty: String, Codable, CaseIterable, Identifiable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var id: String { self.rawValue }
}

// MARK: - Experience Tier

/// Derived tier based on `UserProfile.level`. Maps integer levels to named
/// progression stages. Thresholds are calibrated so one routine/day (no streak
/// bonuses) reaches Intermediate in ≈30 days and Advanced in ≈90 days.
enum ExperienceTier: String, Codable, CaseIterable, Identifiable {
    case beginner     = "Beginner"
    case intermediate = "Intermediate"
    case advanced     = "Advanced"

    var id: String { rawValue }
    var displayName: String { rawValue }

    /// Level threshold at which users unlock Intermediate (≈30 days of daily activity).
    static let intermediateLevel = 7
    /// Level threshold at which users unlock Advanced (≈90 days of daily activity).
    static let advancedLevel = 20

    var icon: String {
        switch self {
        case .beginner:     return "figure.walk"
        case .intermediate: return "figure.run"
        case .advanced:     return "figure.run.circle.fill"
        }
    }
}

// MARK: - Injury Type

enum InjuryType: String, CaseIterable, Identifiable, Codable {
    case lowerBack   = "lower_back"
    case shoulder    = "shoulder"
    case knee        = "knee"
    case wristElbow  = "wrist_elbow"
    case ankleFoot   = "ankle_foot"
    case neck        = "neck"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .lowerBack:  return "Lower Back"
        case .shoulder:   return "Shoulder / Rotator Cuff"
        case .knee:       return "Knee"
        case .wristElbow: return "Wrist / Elbow"
        case .ankleFoot:  return "Ankle / Foot"
        case .neck:       return "Neck / Cervical"
        }
    }

    var icon: String {
        switch self {
        case .lowerBack:  return "figure.walk"
        case .shoulder:   return "figure.arms.open"
        case .knee:       return "figure.run"
        case .wristElbow: return "hand.raised"
        case .ankleFoot:  return "figure.stand"
        case .neck:       return "person.bust"
        }
    }
}

// MARK: - Session Tier

/// A selectable session duration window. Each case is gated behind an `ExperienceTier`.
enum SessionTier: String, CaseIterable, Identifiable {
    case basic        = "10-12 min"
    case intermediate = "15-20 min"
    case advanced     = "20-30 min"

    var id: String { rawValue }

    /// Duration budget in seconds (lowerBound...upperBound). ±120 s tolerance on generation.
    var durationRange: ClosedRange<Int> {
        switch self {
        case .basic:        return 600...720    // 10–12 min
        case .intermediate: return 900...1200   // 15–20 min
        case .advanced:     return 1200...1800  // 20–30 min
        }
    }

    /// Minimum experience tier required to access this session tier.
    var requiredExperienceTier: ExperienceTier {
        switch self {
        case .basic:        return .beginner
        case .intermediate: return .intermediate
        case .advanced:     return .advanced
        }
    }

    /// Returns `true` when this session tier is accessible to the given profile.
    func isUnlocked(for profile: UserProfile?) -> Bool {
        guard let profile = profile else { return self == .basic }
        switch self {
        case .basic:        return true
        case .intermediate: return profile.experienceTier != .beginner
        case .advanced:     return profile.experienceTier == .advanced
        }
    }

    /// Short label displayed on locked tier options.
    var unlockLabel: String {
        switch self {
        case .basic:        return "Available"
        case .intermediate: return "Unlocks at Intermediate (level \(ExperienceTier.intermediateLevel))"
        case .advanced:     return "Unlocks at Advanced (level \(ExperienceTier.advancedLevel))"
        }
    }
}

@Model
final class UserProfile {
    var gender: Gender
    var xp: Int
    var level: Int
    var streakCount: Int
    var lastExerciseDate: Date?
    var profileImageData: Data?

    var activeInjuries: [String] = []
    var savedExerciseNames: [String] = []

    init(gender: Gender = .unspecified, xp: Int = 0, level: Int = 1, streakCount: Int = 0) {
        self.gender = gender
        self.xp = xp
        self.level = level
        self.streakCount = streakCount
    }

    var profileImage: UIImage? {
        guard let data = profileImageData else { return nil }
        return UIImage(data: data)
    }

    func setProfileImage(_ image: UIImage) {
        self.profileImageData = image.jpegData(compressionQuality: 0.9)
    }

    /// The user's named progression tier, derived from their current `level`.
    var experienceTier: ExperienceTier {
        if level >= ExperienceTier.advancedLevel     { return .advanced }
        if level >= ExperienceTier.intermediateLevel { return .intermediate }
        return .beginner
    }

    /**
     Call this when a routine is completed. This method updates XP, streak count, and level based on completion logic.

     Rules:
     - Only award XP and increment streak once per calendar day.
     - If `lastExerciseDate` is nil (first completion), start streakCount at 1.
     - If last completion was yesterday, increment streakCount by 1.
     - If last completion was before yesterday, reset streakCount to 1.
     - If last completion was today, do not award XP or modify streak.
     - Base XP is awarded on each completion.
     - Bonus XP (+50) is awarded when hitting streak milestones: 7, 30, and 100 days.
     - Level increases by 1 for every 100 XP accumulated, and XP rolls over properly.

     - Returns: The new `ExperienceTier` if a tier boundary was crossed, `nil` otherwise.
     */
    @discardableResult
    func completeRoutine(baseXP: Int = 20) -> ExperienceTier? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tierBefore = experienceTier

        // Normalize last exercise date to start of day for comparison
        guard let lastExercise = lastExerciseDate else {
            // First time completing routine
            streakCount = 1
            xp += baseXP
            awardBonusXPIfNeeded()
            levelUpIfNeeded()
            lastExerciseDate = today
            let tierAfter = experienceTier
            return tierAfter != tierBefore ? tierAfter : nil
        }

        let lastDate = calendar.startOfDay(for: lastExercise)

        if lastDate == today {
            // Already completed today, no XP or streak update
            return nil
        }

        let daysDifference = calendar.dateComponents([.day], from: lastDate, to: today).day ?? 0

        if daysDifference == 1 {
            // Continuation of streak
            streakCount += 1
        } else if daysDifference > 1 {
            // Streak broken, reset streakCount
            streakCount = 1
        } else {
            // lastDate is in future or invalid difference, treat as new streak
            streakCount = 1
        }

        xp += baseXP
        awardBonusXPIfNeeded()
        levelUpIfNeeded()
        lastExerciseDate = today
        let tierAfter = experienceTier
        return tierAfter != tierBefore ? tierAfter : nil
    }

    private func awardBonusXPIfNeeded() {
        // Award bonus XP for reaching streak milestones
        let bonusXP = [7, 30, 100].contains(streakCount) ? 50 : 0
        xp += bonusXP
    }

    private func levelUpIfNeeded() {
        while xp >= 100 {
            xp -= 100
            level += 1
        }
    }
}

@Model
final class Exercise {
    var name: String
    var exerciseDescription: String
    var durationSeconds: Int
    var category: ExerciseCategory
    var difficulty: Difficulty
    var genderFocus: Gender?
    var instructions: [String]
    var tips: [String]
    var audioCues: [Int: String] // Timestamp in seconds to text
    var contraindications: [String] = []

    init(name: String,
         exerciseDescription: String,
         durationSeconds: Int,
         category: ExerciseCategory,
         instructions: [String],
         tips: [String] = [],
         audioCues: [Int: String] = [:],
         difficulty: Difficulty = .beginner,
         genderFocus: Gender? = nil,
         contraindications: [String] = []) {
        self.name = name
        self.exerciseDescription = exerciseDescription
        self.durationSeconds = durationSeconds
        self.category = category
        self.difficulty = difficulty
        self.genderFocus = genderFocus
        self.instructions = instructions
        self.tips = tips
        self.audioCues = audioCues
        self.contraindications = contraindications
    }
}

@Model
final class Routine {
    var name: String
    var routineDescription: String
    var exerciseNames: [String] // Store names of exercises

    init(name: String, routineDescription: String, exerciseNames: [String]) {
        self.name = name
        self.routineDescription = routineDescription
        self.exerciseNames = exerciseNames
    }
}

// MARK: - Weekly Plan Models

struct PlanExercise: Codable {
    var name: String
    var value: Int
    var unit: String  // "sets" or "seconds"

    var nominalSeconds: Int {
        unit == "sets" ? value * 45 : value
    }
}

@Model
final class WorkoutPlan {
    var name: String
    var isActive: Bool = false
    var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \PlanDay.plan)
    var days: [PlanDay] = []

    init(name: String) {
        self.name = name
    }
}

@Model
final class PlanDay {
    var name: String
    /// Calendar.weekday values: 1=Sunday, 2=Monday … 7=Saturday.
    var weekdays: [Int] = []
    var exercises: [PlanExercise] = []
    var plan: WorkoutPlan?

    init(name: String, weekdays: [Int] = [], exercises: [PlanExercise] = []) {
        self.name = name
        self.weekdays = weekdays
        self.exercises = exercises
    }
}

// MARK: - Custom Exercise

@Model
final class CustomExercise {
    var name: String
    var durationSeconds: Int
    var unit: String = "seconds"  // "seconds" or "sets"

    init(name: String, durationSeconds: Int, unit: String = "seconds") {
        self.name = name
        self.durationSeconds = durationSeconds
        self.unit = unit
    }
}

// MARK: - Session Builder

extension Routine {

    /// Generates an ordered list of exercise names to fill the given session tier's
    /// duration budget. Filters by profile gender focus, shuffles the pool, then
    /// greedily selects exercises until the budget is reached.
    ///
    /// - Parameters:
    ///   - tier: The target `SessionTier` defining the duration budget.
    ///   - exercises: The full exercise pool (typically all seeded exercises).
    ///   - profile: Optional user profile for gender-focus filtering.
    /// - Returns: An ordered array of exercise names whose total `durationSeconds`
    ///   falls within `tier.durationRange` (±120 s tolerance per FR-004).
    static func buildSession(tier: SessionTier, exercises: [Exercise], profile: UserProfile?) -> [String] {
        let budget = tier.durationRange

        // 1. Filter by gender focus — include gender-neutral + matching exercises
        let activeInjuries = Set(profile?.activeInjuries ?? [])
        let filtered = exercises.filter { exercise in
            let genderOk = exercise.genderFocus == nil || exercise.genderFocus == profile?.gender
            let injuryOk = activeInjuries.isEmpty || Set(exercise.contraindications).isDisjoint(with: activeInjuries)
            return genderOk && injuryOk
        }

        // 2. Shuffle for variety
        let pool = filtered.shuffled()

        // 3. Greedy fill: add exercises until the budget's lower bound is reached
        var selected: [String] = []
        var totalDuration = 0

        for exercise in pool {
            // Stop once we've reached the lower bound
            if totalDuration >= budget.lowerBound { break }
            // Accept if this exercise fits within the upper bound (+ 120 s tolerance)
            if totalDuration + exercise.durationSeconds <= budget.upperBound + 120 {
                selected.append(exercise.name)
                totalDuration += exercise.durationSeconds
            }
        }

        // 4. Fallback: pool exhausted before lower bound — allow repeats
        //    (edge case; 61 exercises is sufficient for any tier)
        if totalDuration < budget.lowerBound {
            var fallback = pool
            var guard_ = 0
            while totalDuration < budget.lowerBound && guard_ < 200 {
                if fallback.isEmpty { fallback = pool }
                if let exercise = fallback.first {
                    fallback.removeFirst()
                    selected.append(exercise.name)
                    totalDuration += exercise.durationSeconds
                }
                guard_ += 1
            }
        }

        return selected
    }
}

// MARK: - Seeding & Migration
extension Exercise {

    /// Called on every app launch from ContentView.onAppear.
    /// - Fresh install (count == 0): seeds the full exercise + routine library.
    /// - Existing install (count > 0): runs data migration to re-categorize any
    ///   legacy ".kegels" exercises and insert exercises added in this update.
    static func seedInitialData(context: ModelContext) {
        let exerciseFetch = FetchDescriptor<Exercise>()
        let count = (try? context.fetchCount(exerciseFetch)) ?? 0

        if count == 0 {
            // Fresh install — seed the complete library
            let allExercises = stretchingExercises()
                + breathingExercises()
                + bodyweightExercises()
                + balanceExercises()
                + frozenShoulderExercises()
                + refluxBreathingExercises()
            applyContraindications(to: allExercises)
            for exercise in allExercises {
                context.insert(exercise)
            }
            let allRoutines = routines()
            for routine in allRoutines {
                context.insert(routine)
            }
        } else {
            // Existing install — migrate data
            migrateData(context: context)
        }
    }

    /// Idempotent migration for users upgrading from a version that had the
    /// Kegels category. Runs in O(n) over the exercise table.
    private static func migrateData(context: ModelContext) {
        guard let exercises = try? context.fetch(FetchDescriptor<Exercise>()) else { return }

        // 1. Re-categorize any legacy kegel exercises to stretching
        for exercise in exercises where exercise.category == .kegels {
            exercise.category = .stretching
        }

        // 2. Insert new exercises that don't already exist (checked by name)
        let existingNames = Set(exercises.map { $0.name })
        let newExercises: [Exercise] = newStretchingExercises()
            + newBreathingExercises()
            + newBodyweightExercises()
            + balanceExercises()
            + frozenShoulderExercises()
            + refluxBreathingExercises()
        for exercise in newExercises where !existingNames.contains(exercise.name) {
            context.insert(exercise)
        }

        // 2b. Refresh focus-area exercise descriptions, which no longer name a condition
        let focusDescriptions = Dictionary(
            (frozenShoulderExercises() + refluxBreathingExercises()).map { ($0.name, $0.exerciseDescription) },
            uniquingKeysWith: { first, _ in first }
        )
        for exercise in exercises {
            if let description = focusDescriptions[exercise.name] { exercise.exerciseDescription = description }
        }

        // 3. Apply contraindications to all exercises (idempotent — safe to re-run)
        let allExercises = exercises + newExercises.filter { !existingNames.contains($0.name) }
        applyContraindications(to: allExercises)

        // 4. Rename programs whose names were softened; pacts link to programs by name
        if let existingRoutines = try? context.fetch(FetchDescriptor<Routine>()) {
            let seeded = routines()
            for routine in existingRoutines {
                guard let newName = Routine.renamedPrograms[routine.name] else { continue }
                routine.name = newName
                if let description = seeded.first(where: { $0.name == newName })?.routineDescription {
                    routine.routineDescription = description
                }
            }
        }
        if let pacts = try? context.fetch(FetchDescriptor<ThisForThat>()) {
            for pact in pacts {
                if let newName = Routine.renamedPrograms[pact.thisAction] { pact.thisAction = newName }
            }
        }

        // 5. Insert new routines that don't already exist (checked by name)
        if let existingRoutines = try? context.fetch(FetchDescriptor<Routine>()) {
            let existingRoutineNames = Set(existingRoutines.map { $0.name })
            for routine in routines() where !existingRoutineNames.contains(routine.name) {
                context.insert(routine)
            }
        }
    }

    /// Sets contraindication tags on exercises by name. Safe to call multiple times.
    static func applyContraindications(to exercises: [Exercise]) {
        let lb = InjuryType.lowerBack.rawValue
        let sh = InjuryType.shoulder.rawValue
        let kn = InjuryType.knee.rawValue
        let we = InjuryType.wristElbow.rawValue
        let af = InjuryType.ankleFoot.rawValue
        let nk = InjuryType.neck.rawValue

        let map: [String: [String]] = [
            // Stretching
            "Neck Tilts":               [nk],
            "Shoulder Rolls":           [sh],
            "Chest Stretch (Doorway)":  [sh],
            "Cat-Cow":                  [lb],
            "Triceps Stretch":          [sh, we],
            "Hamstring Stretch":        [lb, kn],
            "Quadriceps Stretch":       [kn, af],
            "Calf Stretch":             [af],
            "Hip Flexor Stretch":       [kn, lb],
            "Figure-4 Stretch":         [kn, lb],
            "Butterfly Stretch":        [kn],
            "Child's Pose":             [lb, kn, we],
            "IT Band Stretch":          [kn, af],
            "Wrist & Forearm Stretch":  [we],
            "Pigeon Pose":              [kn, lb, af],
            "Seated Spinal Twist":      [lb],
            // Bodyweight
            "Push-ups":                 [sh, we],
            "Knee Push-ups":            [sh, we],
            "Plank Shoulder Taps":      [sh, we],
            "Triceps Dips":             [sh, we],
            "Arm Circles":              [sh],
            "Inchworm Walks":           [sh, we, lb],
            "Front Plank":              [sh, we, lb],
            "Side Plank":               [sh, we],
            "Bicycle Crunches":         [lb, nk],
            "Leg Raises":               [lb],
            "Mountain Climbers":        [sh, we, lb],
            "Squats":                   [kn, af],
            "Lunges":                   [kn, af],
            "Calf Raises":              [af],
            "Wall Sit":                 [kn],
            "Burpees":                  [sh, we, kn, af, lb],
            "Diamond Push-ups":         [sh, we],
            "Jump Squats":              [kn, af],
            "Superman Hold":            [lb],
            "Dead Bug":                 [lb],
            "Bird Dog":                 [lb],
            // Balance
            "Single-Leg Stand":         [kn, af],
            "Heel-to-Toe Walk":         [af, kn],
            "Tree Pose":                [kn, af],
            "Standing Knee Lifts":      [kn, af],
            "Clock Reach":              [kn, af],
        ]

        for exercise in exercises {
            if let tags = map[exercise.name] {
                exercise.contraindications = tags
            }
        }
    }

    // MARK: - Original Exercises

    private static func stretchingExercises() -> [Exercise] {
        originalStretchingExercises() + newStretchingExercises()
    }

    private static func originalStretchingExercises() -> [Exercise] {
        [
            Exercise(name: "Neck Tilts", exerciseDescription: "Forward, backward, and side-to-side tilts.", durationSeconds: 60, category: .stretching, instructions: ["Sit tall.", "Tilt head forward, then back.", "Tilt ear to shoulder on each side."], tips: ["Move slowly.", "Relax your shoulders."], audioCues: [0: "Tilt your head forward gently.", 15: "Tilt it back slowly.", 30: "Right ear to right shoulder.", 45: "Left ear to left shoulder.", 50: "Almost there."]),
            Exercise(name: "Shoulder Rolls", exerciseDescription: "Roll shoulders forward and backward.", durationSeconds: 60, category: .stretching, instructions: ["Stand upright.", "Roll shoulders up and forward.", "Reverse the motion half-way through."], tips: ["Keep it smooth.", "Don't rush."], audioCues: [0: "Roll both shoulders forward.", 15: "Big, slow circles.", 30: "Now roll backward.", 50: "Almost there."]),
            Exercise(name: "Chest Stretch (Doorway)", exerciseDescription: "Open your anterior shoulders.", durationSeconds: 60, category: .stretching, instructions: ["Stand in a doorway.", "Place forearms on the frame.", "Lean forward slightly."], tips: ["You should feel a stretch in your chest.", "Don't overextend."], audioCues: [0: "Place forearms on the frame.", 10: "Lean forward — feel the stretch.", 30: "Breathe — let your chest open.", 50: "Almost there."]),
            Exercise(name: "Cat-Cow", exerciseDescription: "Spinal mobility on all fours.", durationSeconds: 60, category: .stretching, instructions: ["On all fours.", "Inhale, arch back.", "Exhale, round back."], tips: ["Move with your breath.", "Keep neck aligned."], audioCues: [0: "Inhale — arch your back.", 10: "Exhale — round your spine.", 20: "Inhale — arch.", 30: "Exhale — round.", 40: "Inhale — arch again.", 50: "Exhale — round and rest."]),
            Exercise(name: "Triceps Stretch", exerciseDescription: "Overhead arm pull.", durationSeconds: 60, category: .stretching, instructions: ["One arm overhead.", "Bend elbow.", "Pull elbow with other hand.", "Switch sides."], tips: ["Keep your chest upright.", "Don't push too hard."], audioCues: [0: "Right arm overhead, bend the elbow.", 15: "Relax into the stretch.", 30: "Switch to your left arm.", 50: "Almost there."]),
            Exercise(name: "Side Reach Stretch", exerciseDescription: "Lateral torso stretch.", durationSeconds: 60, category: .stretching, instructions: ["Stand with feet apart.", "Reach one arm over head to the side.", "Switch sides."], tips: ["Feel the stretch in your obliques.", "Stay in control."], audioCues: [0: "Reach your left arm up and over.", 15: "Breathe into your side.", 30: "Switch — reach your right arm over.", 50: "Almost there."]),
            Exercise(name: "Hamstring Stretch", exerciseDescription: "Seated or standing leg reach.", durationSeconds: 60, category: .stretching, instructions: ["Extend one leg.", "Hinge at hips.", "Reach for toes.", "Switch legs."], tips: ["Keep back flat.", "Lead with chest."], audioCues: [0: "Extend your right leg. Reach forward.", 15: "Breathe — let your chest lower.", 30: "Switch to your left leg.", 50: "Almost there."]),
            Exercise(name: "Quadriceps Stretch", exerciseDescription: "Standing leg pull.", durationSeconds: 60, category: .stretching, instructions: ["Stand on one leg.", "Pull other foot to glute.", "Switch legs."], tips: ["Keep knees together.", "Find a balance point."], audioCues: [0: "Right leg — pull your foot to glute.", 15: "Knees together, find your balance.", 30: "Switch to your left leg.", 50: "Almost there."]),
            Exercise(name: "Calf Stretch", exerciseDescription: "Against a wall.", durationSeconds: 60, category: .stretching, instructions: ["Hands on wall.", "One leg back, heel down.", "Switch legs."], tips: ["Keep back leg straight.", "Push into the wall."], audioCues: [0: "Right leg back, heel flat on floor.", 15: "Push your heel down — feel the stretch.", 30: "Switch to your left leg.", 50: "Almost there."]),
            Exercise(name: "Hip Flexor Stretch", exerciseDescription: "Lunge position stretch.", durationSeconds: 60, category: .stretching, instructions: ["Kneel on one knee.", "Lean forward into hips.", "Switch sides."], tips: ["Keep torso upright.", "Squeeze glute of back leg."], audioCues: [0: "Right knee down, left foot forward.", 15: "Let your hips sink forward gently.", 30: "Switch to your left knee.", 50: "Almost there."]),
            Exercise(name: "Figure-4 Stretch", exerciseDescription: "Glute focus (Female focus).", durationSeconds: 60, category: .stretching, instructions: ["Lie on back.", "Cross ankle over knee.", "Pull knee to chest."], tips: ["Feel it in your glutes.", "Breathe through it."], audioCues: [0: "Cross your right ankle over left knee.", 15: "Breathe into your hip — let it soften.", 30: "Switch — cross your left ankle over.", 50: "Almost there."], genderFocus: .female),
            Exercise(name: "Butterfly Stretch", exerciseDescription: "Inner thigh focus (Female focus).", durationSeconds: 60, category: .stretching, instructions: ["Sit with soles of feet together.", "Press knees down.", "Lean forward."], tips: ["Gentle pressure.", "Keep feet close."], audioCues: [0: "Soles together. Press your knees down.", 15: "Let gravity open your hips gently.", 30: "Lean forward slightly.", 50: "Almost there."], genderFocus: .female),
            Exercise(name: "Child's Pose", exerciseDescription: "Lower back focus (Male focus).", durationSeconds: 60, category: .stretching, instructions: ["Kneel.", "Sit on heels.", "Reach forward."], tips: ["Widen knees if needed.", "Relax forehead."], audioCues: [0: "Kneel and reach your arms forward.", 20: "Breathe into your back — let it expand.", 40: "Soften your hips toward your heels.", 50: "Almost there."], genderFocus: .male),
            Exercise(name: "IT Band Stretch", exerciseDescription: "Lower body band stretch (Male focus).", durationSeconds: 60, category: .stretching, instructions: ["Cross one leg behind.", "Lean toward the same side.", "Switch."], tips: ["Feel it on the outer hip.", "Balance yourself."], audioCues: [0: "Cross your right leg behind. Lean right.", 15: "Feel the stretch along your outer hip.", 30: "Switch — cross your left leg. Lean left.", 50: "Almost there."], genderFocus: .male)
        ]
    }

    /// New stretching exercises added in this update (002-exercise-review).
    private static func newStretchingExercises() -> [Exercise] {
        [
            Exercise(
                name: "Wrist & Forearm Stretch",
                exerciseDescription: "Desk-worker relief for wrists and forearms.",
                durationSeconds: 60,
                category: .stretching,
                instructions: [
                    "Extend one arm forward, palm up.",
                    "Gently pull fingers down with the other hand.",
                    "Hold for 15 seconds.",
                    "Flip the hand palm-down and pull fingers toward you.",
                    "Switch arms."
                ],
                tips: [
                    "Don't force the stretch — go to gentle tension only.",
                    "Great for anyone who types or uses a phone frequently.",
                    "Breathe normally throughout."
                ],
                audioCues: [
                    0: "Extend your right arm. Pull fingers down.",
                    15: "Flip hand — pull fingers toward you.",
                    30: "Switch to your left arm.",
                    45: "Flip and stretch the left side.",
                    50: "Almost there."
                ]
            ),
            Exercise(
                name: "Pigeon Pose",
                exerciseDescription: "Deep hip opener for flexibility.",
                durationSeconds: 60,
                category: .stretching,
                instructions: [
                    "Start on all fours.",
                    "Bring your right knee forward behind your right wrist.",
                    "Extend your left leg straight back.",
                    "Lower your hips toward the floor.",
                    "Hold and breathe.",
                    "Switch sides."
                ],
                tips: [
                    "Place a cushion under your hip if this feels too intense.",
                    "Keep your hips level and square.",
                    "This stretch deepens over time — don't force it."
                ],
                audioCues: [
                    0: "Right knee forward. Settle into the stretch.",
                    15: "Breathe into your hip — let it soften.",
                    30: "Switch to your left side.",
                    50: "Almost there."
                ],
                difficulty: .intermediate
            ),
            Exercise(
                name: "Seated Spinal Twist",
                exerciseDescription: "Rotational mobility for the spine.",
                durationSeconds: 60,
                category: .stretching,
                instructions: [
                    "Sit with legs extended.",
                    "Bend your right knee and cross it over your left leg.",
                    "Place your left elbow on the outside of your right knee.",
                    "Twist gently to the right.",
                    "Hold.",
                    "Switch sides."
                ],
                tips: [
                    "Sit tall — don't round your back.",
                    "Twist from your torso, not just your shoulders.",
                    "Breathe into the stretch."
                ],
                audioCues: [
                    0: "Cross your right knee over. Twist right.",
                    15: "Breathe — deepen the twist each exhale.",
                    30: "Switch — cross your left knee. Twist left.",
                    50: "Almost there."
                ]
            )
        ]
    }

    // MARK: - Targeted Relief

    /// Gentle mobility stretches for a frozen ("locked") shoulder. Deliberately carry no
    /// shoulder contraindication so they stay available to users with a shoulder injury.
    private static func frozenShoulderExercises() -> [Exercise] {
        [
            Exercise(
                name: "Pendulum Swing",
                exerciseDescription: "Gentle, gravity-assisted loosening.",
                durationSeconds: 90,
                category: .stretching,
                instructions: [
                    "Stand beside a table and rest your good hand on it.",
                    "Lean forward slightly and let the stiff arm hang straight down.",
                    "Relax the shoulder completely.",
                    "Swing the arm in small circles, about 30 cm across.",
                    "Reverse direction halfway through.",
                    "Switch arms if both shoulders are stiff."
                ],
                tips: [
                    "Let your body sway to move the arm — don't use the shoulder muscles.",
                    "Do this first; it warms the joint for the other stretches.",
                    "A warm shower beforehand can help loosen the shoulder."
                ],
                audioCues: [
                    0: "Lean on the table. Let your arm hang loose.",
                    10: "Small circles. Let the arm swing like a pendulum.",
                    30: "Keep the shoulder relaxed.",
                    45: "Reverse the direction.",
                    70: "Make the circles a little bigger if it feels okay.",
                    85: "Almost there."
                ]
            ),
            Exercise(
                name: "Finger Wall Walk",
                exerciseDescription: "Rebuild overhead reach.",
                durationSeconds: 90,
                category: .stretching,
                instructions: [
                    "Face a wall about an arm's length away.",
                    "Place the fingertips of the stiff arm on the wall at waist height.",
                    "Slowly walk your fingers up the wall like a spider.",
                    "Stop at the first point of tension and hold for a few seconds.",
                    "Walk the fingers back down slowly.",
                    "Repeat, aiming a little higher each time."
                ],
                tips: [
                    "Your fingers do the work — keep the shoulder relaxed.",
                    "Mark your highest point to track progress over the weeks.",
                    "Don't shrug — keep the shoulder down away from your ear."
                ],
                audioCues: [
                    0: "Fingertips on the wall at waist height.",
                    5: "Walk your fingers up slowly.",
                    20: "Hold where you feel tension.",
                    30: "Walk back down.",
                    40: "Again — walk your fingers up.",
                    55: "Hold. Breathe.",
                    65: "And back down.",
                    75: "One more — try a little higher.",
                    85: "Almost there."
                ]
            ),
            Exercise(
                name: "Cross-Body Arm Stretch",
                exerciseDescription: "Ease tightness at the back of the shoulder.",
                durationSeconds: 60,
                category: .stretching,
                instructions: [
                    "Sit or stand tall.",
                    "Use your good arm to lift the stiff arm at the elbow.",
                    "Gently bring it across your chest.",
                    "Hold for 15–20 seconds, then relax.",
                    "Repeat."
                ],
                tips: [
                    "Pull from the elbow, not the wrist.",
                    "Keep your shoulders level and facing forward.",
                    "Mild stretch only — stop if you feel sharp pain."
                ],
                audioCues: [
                    0: "Hold the stiff arm at the elbow.",
                    5: "Bring it gently across your chest.",
                    20: "Relax the arm down.",
                    30: "Again — across the chest and hold.",
                    45: "Relax.",
                    50: "Almost there."
                ]
            ),
            Exercise(
                name: "Towel Stretch",
                exerciseDescription: "Improve reach behind your back.",
                durationSeconds: 90,
                category: .stretching,
                instructions: [
                    "Hold a towel behind your back with both hands, one high and one low.",
                    "The stiff arm holds the bottom end.",
                    "Use the top hand to gently pull the towel upward.",
                    "Hold for a few seconds, then lower.",
                    "Repeat slowly."
                ],
                tips: [
                    "Pull gently — the lower arm should feel a stretch, not pain.",
                    "Stand tall and avoid leaning forward.",
                    "A longer towel makes this easier when starting out."
                ],
                audioCues: [
                    0: "Towel behind your back, stiff arm at the bottom.",
                    5: "Gently pull the towel upward.",
                    15: "Hold. Breathe.",
                    20: "Lower slowly.",
                    30: "Pull up again.",
                    45: "Lower.",
                    55: "Once more — gently up.",
                    70: "And down.",
                    85: "Almost there."
                ]
            ),
            Exercise(
                name: "Outward Rotation Stretch",
                exerciseDescription: "Restore outward turning of the arm.",
                durationSeconds: 60,
                category: .stretching,
                instructions: [
                    "Stand in a doorway with the stiff arm's elbow bent to 90°.",
                    "Keep the elbow tucked against your side.",
                    "Place the palm against the door frame.",
                    "Slowly turn your body away from the arm.",
                    "Hold for 15–30 seconds, then relax."
                ],
                tips: [
                    "Keep the elbow pinned to your side throughout.",
                    "A rolled towel between elbow and ribs can help.",
                    "Turn your body, not your arm."
                ],
                audioCues: [
                    0: "Elbow bent and tucked in. Palm on the frame.",
                    5: "Slowly turn your body away.",
                    20: "Hold. Keep that elbow tucked.",
                    30: "Relax and reset.",
                    35: "Turn away again.",
                    50: "Almost there."
                ]
            ),
            Exercise(
                name: "Armpit Stretch",
                exerciseDescription: "Open the armpit and lift the arm.",
                durationSeconds: 60,
                category: .stretching,
                instructions: [
                    "Stand facing a shelf or counter at chest height.",
                    "Use your good arm to lift the stiff arm onto the shelf.",
                    "Slowly bend your knees to open up the armpit.",
                    "Deepen the knee bend a little, then straighten.",
                    "Repeat gently."
                ],
                tips: [
                    "Let your legs do the movement, not your shoulder.",
                    "Go only as low as feels comfortable.",
                    "Keep your back straight."
                ],
                audioCues: [
                    0: "Rest the stiff arm on the shelf.",
                    5: "Bend your knees slowly — feel the armpit open.",
                    15: "Straighten up.",
                    20: "Bend again, a little deeper.",
                    35: "Straighten.",
                    40: "Once more — gently down.",
                    50: "Almost there."
                ]
            )
        ]
    }

    /// Diaphragm-strengthening breathing for reflux. Training the diaphragm supports the
    /// valve between the stomach and oesophagus.
    private static func refluxBreathingExercises() -> [Exercise] {
        [
            Exercise(
                name: "Diaphragm Breathing (Lying)",
                exerciseDescription: "Learn to breathe with your diaphragm.",
                durationSeconds: 300,
                category: .breathing,
                instructions: [
                    "Lie on your back with knees bent, head on a pillow.",
                    "Place one hand on your chest and one just below your ribs.",
                    "Breathe in slowly through your nose so your belly rises.",
                    "The hand on your chest should stay still.",
                    "Tighten your stomach muscles and exhale through pursed lips.",
                    "Repeat with slow, steady breaths."
                ],
                tips: [
                    "Wait at least 2–3 hours after eating before lying down for this.",
                    "Aim for 5–10 minutes, 3–4 times a day as you build the habit.",
                    "If your chest hand moves, slow the breath down."
                ],
                audioCues: [
                    0: "Lie back, knees bent. One hand on chest, one on belly.",
                    10: "Breathe in through your nose — belly rises.",
                    15: "Exhale through pursed lips — belly falls.",
                    30: "Keep the chest hand still.",
                    60: "Inhale into the belly.",
                    65: "Long, slow exhale.",
                    120: "Stay with the rhythm.",
                    150: "Halfway there.",
                    180: "Inhale — fill the belly.",
                    185: "Exhale — tighten the stomach gently.",
                    240: "Slow and steady.",
                    290: "Last few seconds."
                ]
            ),
            Exercise(
                name: "Seated Diaphragm Breathing",
                exerciseDescription: "Upright belly breathing — fine after meals.",
                durationSeconds: 300,
                category: .breathing,
                instructions: [
                    "Sit upright in a chair, feet flat, shoulders relaxed.",
                    "Place one hand on your upper belly, just below your ribs.",
                    "Inhale through your nose for 4 counts — feel the hand move out.",
                    "Exhale through pursed lips for 6 counts — feel it draw in.",
                    "Keep your chest and shoulders still."
                ],
                tips: [
                    "Upright breathing is a good choice after meals when lying down can trigger reflux.",
                    "Try it straight after eating to help calm burping and reflux.",
                    "Loosen any tight belt or waistband first."
                ],
                audioCues: [
                    0: "Sit tall. Hand just below your ribs.",
                    5: "Inhale through your nose — four counts.",
                    9: "Exhale through pursed lips — six counts.",
                    30: "Keep your shoulders still.",
                    60: "Inhale — belly out.",
                    64: "Exhale — belly in.",
                    120: "Steady rhythm.",
                    150: "Halfway there.",
                    210: "Inhale four, exhale six.",
                    290: "Last few seconds."
                ]
            ),
            Exercise(
                name: "360° Rib Breathing",
                exerciseDescription: "Expand the lower ribs to work the whole diaphragm.",
                durationSeconds: 180,
                category: .breathing,
                instructions: [
                    "Sit or stand tall.",
                    "Place your hands on the sides of your lower ribs.",
                    "Inhale through your nose and push your ribs out into your hands — sideways and back.",
                    "Exhale slowly and feel the ribs draw in.",
                    "Repeat."
                ],
                tips: [
                    "Think of the breath expanding like an umbrella opening.",
                    "Keep the shoulders down and relaxed.",
                    "Great as a progression once belly breathing feels easy."
                ],
                audioCues: [
                    0: "Hands on your lower ribs.",
                    5: "Inhale — push the ribs out into your hands.",
                    10: "Exhale — let them draw in.",
                    30: "Expand sideways and into your back.",
                    60: "Inhale wide.",
                    65: "Slow exhale.",
                    90: "Halfway there.",
                    120: "Keep the shoulders down.",
                    170: "Last few seconds."
                ],
                difficulty: .intermediate
            ),
            Exercise(
                name: "Weighted Belly Breathing",
                exerciseDescription: "Strengthen the diaphragm against light resistance.",
                durationSeconds: 300,
                category: .breathing,
                instructions: [
                    "Lie on your back with knees bent.",
                    "Rest a light book on your upper belly, just below your ribs.",
                    "Inhale through your nose and lift the book with your belly.",
                    "Exhale slowly and let the book lower.",
                    "Keep your chest still throughout."
                ],
                tips: [
                    "Start with a light paperback — only add weight once it feels easy.",
                    "Do this on an empty stomach, at least 2–3 hours after eating.",
                    "Stop if you feel discomfort or heartburn."
                ],
                audioCues: [
                    0: "Lie back. Rest the book on your upper belly.",
                    10: "Inhale — lift the book with your belly.",
                    15: "Exhale — let it lower slowly.",
                    30: "Keep your chest still.",
                    60: "Breathe in — push the book up.",
                    65: "Slow exhale.",
                    150: "Halfway there.",
                    210: "Steady breaths.",
                    290: "Last few seconds."
                ],
                difficulty: .intermediate
            )
        ]
    }

    private static func breathingExercises() -> [Exercise] {
        originalBreathingExercises() + newBreathingExercises()
    }

    private static func originalBreathingExercises() -> [Exercise] {
        [
            Exercise(name: "Belly Breathing", exerciseDescription: "Diaphragmatic focus.", durationSeconds: 180, category: .breathing, instructions: ["Hand on belly.", "Inhale, belly out.", "Exhale, belly in."], tips: ["Breathe deep.", "Relax chest."], audioCues: [0: "Hand on belly. Sit comfortably.", 5: "Inhale — belly rises.", 9: "Exhale — belly falls.", 25: "Inhale deep.", 29: "Slow exhale.", 60: "Stay with the breath.", 90: "Inhale — fill your belly.", 120: "Exhale — let it go.", 170: "Last few seconds."]),
            Exercise(name: "4-7-8 Breathing", exerciseDescription: "Tranquilizing breath.", durationSeconds: 120, category: .breathing, instructions: ["Inhale 4s.", "Hold 7s.", "Exhale 8s."], tips: ["Make the whoosh sound.", "Keep tip of tongue on ridge."], audioCues: [0: "Inhale — four counts.", 4: "Hold — seven counts.", 11: "Exhale — eight counts.", 19: "Inhale — four counts.", 23: "Hold — seven.", 30: "Exhale — eight counts.", 38: "Inhale — four counts.", 42: "Hold.", 49: "Long exhale.", 110: "Last few seconds."]),
            Exercise(name: "Box Breathing", exerciseDescription: "Square breathing (4-4-4-4).", durationSeconds: 300, category: .breathing, instructions: ["Inhale 4s.", "Hold 4s.", "Exhale 4s.", "Hold 4s."], tips: ["Equal counts.", "Mental focus."], audioCues: [0: "Sit tall. Prepare to breathe.", 4: "Hold — four counts.", 8: "Exhale — four counts.", 12: "Hold — four counts.", 16: "Inhale — four counts.", 20: "Hold.", 24: "Exhale.", 28: "Hold.", 32: "Inhale.", 48: "Inhale.", 64: "Inhale.", 80: "Inhale.", 96: "Inhale.", 112: "Inhale.", 128: "Inhale — halfway there.", 144: "Inhale.", 160: "Inhale.", 176: "Inhale.", 192: "Inhale.", 208: "Inhale.", 224: "Inhale.", 240: "Inhale.", 256: "Inhale.", 272: "Inhale.", 288: "Last cycle — inhale.", 290: "Last few seconds."]),
            Exercise(name: "Alternate Nostril Breathing", exerciseDescription: "Balance focus.", durationSeconds: 180, category: .breathing, instructions: ["Close one nostril.", "Inhale other.", "Switch nostrils.", "Exhale."], tips: ["Keep it gentle.", "Don't force."], audioCues: [0: "Close right nostril — inhale left.", 10: "Close left nostril — exhale right.", 20: "Inhale right nostril.", 30: "Close right — exhale left.", 40: "Inhale left nostril.", 60: "Switch and exhale.", 90: "Continue the alternating pattern.", 170: "Last few seconds."]),
            Exercise(name: "Pursed Lip Breathing", exerciseDescription: "Ease of breath.", durationSeconds: 120, category: .breathing, instructions: ["Inhale through nose.", "Exhale through pursed lips."], tips: ["Slow the exhale.", "Like blowing out a candle."], audioCues: [0: "Inhale through your nose.", 4: "Exhale through pursed lips.", 14: "Inhale — two counts.", 16: "Exhale slowly — four counts.", 60: "Continue — in through nose.", 110: "Last few seconds."]),
            Exercise(name: "Resonant Breathing", exerciseDescription: "6 breaths per minute.", durationSeconds: 300, category: .breathing, instructions: ["5.5s inhale.", "5.5s exhale."], tips: ["Coherent rhythm.", "Steady flow."], audioCues: [0: "Inhale slowly — five counts.", 5: "Exhale slowly — five counts.", 11: "Inhale.", 16: "Exhale.", 22: "Inhale.", 44: "Inhale — slow and steady.", 66: "Inhale.", 88: "Inhale.", 110: "Inhale.", 132: "Inhale — you're halfway.", 154: "Inhale.", 176: "Inhale.", 198: "Inhale.", 220: "Inhale.", 242: "Inhale.", 264: "Inhale.", 286: "Inhale — last few breaths.", 290: "Last few seconds."]),
            Exercise(name: "Gentle Breath Holds", exerciseDescription: "Body awareness.", durationSeconds: 120, category: .breathing, instructions: ["Inhale.", "Hold comfortably.", "Exhale."], tips: ["Don't push limits.", "Stay relaxed."], audioCues: [0: "Inhale fully.", 5: "Gentle hold — stay relaxed.", 15: "Exhale slowly.", 25: "Inhale — and hold.", 35: "Exhale.", 60: "Inhale — gentle hold.", 70: "Exhale slowly.", 110: "Last few seconds."]),
            Exercise(name: "Progressive Relaxation", exerciseDescription: "Deep rest.", durationSeconds: 300, category: .breathing, instructions: ["Tense and release muscles with breath."], tips: ["Start from toes.", "Work up to head."], audioCues: [0: "Relax your whole body. Close your eyes.", 20: "Tense your feet — hold.", 25: "Release your feet completely.", 50: "Tense your calves — hold.", 55: "Release your calves.", 80: "Tense your thighs — hold.", 85: "Release.", 120: "Tighten your belly — hold.", 130: "Release your core.", 170: "Shrug your shoulders — hold.", 180: "Drop your shoulders. Release.", 250: "Relax your face completely.", 290: "Last few seconds."])
        ]
    }

    /// New breathing exercises added in this update (002-exercise-review).
    private static func newBreathingExercises() -> [Exercise] {
        [
            Exercise(
                name: "Lion's Breath",
                exerciseDescription: "Energizing stress-release technique.",
                durationSeconds: 120,
                category: .breathing,
                instructions: [
                    "Sit comfortably or kneel.",
                    "Inhale deeply through your nose.",
                    "Open your mouth wide, stick out your tongue, and exhale forcefully with a ha sound.",
                    "Relax your face.",
                    "Repeat."
                ],
                tips: [
                    "This may feel silly at first — that's normal and part of the stress release.",
                    "Let the exhale be loud and forceful.",
                    "Great for releasing jaw and face tension."
                ],
                audioCues: [
                    0: "Inhale deeply through your nose.",
                    5: "Open wide and roar it out. Ha!",
                    15: "Inhale again.",
                    20: "And release. Ha!",
                    60: "Keep going. Inhale.",
                    65: "Release!",
                    80: "Inhale — one more round.",
                    85: "Open wide — release!",
                    110: "Almost there."
                ]
            ),
            Exercise(
                name: "Humming Bee Breath",
                exerciseDescription: "Calming vibration breath for anxiety relief.",
                durationSeconds: 180,
                category: .breathing,
                instructions: [
                    "Sit comfortably with eyes closed.",
                    "Place your index fingers gently on the cartilage of your ears.",
                    "Inhale deeply.",
                    "Exhale while making a steady humming sound.",
                    "Feel the vibration in your head and chest.",
                    "Repeat."
                ],
                tips: [
                    "The humming should be smooth and continuous.",
                    "Experiment with pitch — find what feels most soothing.",
                    "This technique is excellent before sleep."
                ],
                audioCues: [
                    0: "Close your eyes. Fingers on your ears.",
                    5: "Inhale deeply.",
                    10: "Hum as you exhale.",
                    30: "Inhale again.",
                    35: "Long, steady hum.",
                    60: "Inhale — keep the vibration going.",
                    65: "Hum slowly — feel the resonance.",
                    90: "Continue at your own pace.",
                    170: "Last few seconds."
                ]
            )
        ]
    }

    private static func bodyweightExercises() -> [Exercise] {
        originalBodyweightExercises() + newBodyweightExercises()
    }

    private static func originalBodyweightExercises() -> [Exercise] {
        [
            Exercise(name: "Push-ups", exerciseDescription: "Standard chest and arms.", durationSeconds: 60, category: .bodyweight, instructions: ["High plank.", "Lower chest.", "Push up."], tips: ["Core tight.", "Elbows at 45 deg."], audioCues: [0: "Start in a high plank position.", 15: "Keep core tight, elbows at 45.", 30: "Good pace — halfway there.", 50: "Last few — finish strong."], difficulty: .beginner),
            Exercise(name: "Knee Push-ups", exerciseDescription: "Modified push-up.", durationSeconds: 60, category: .bodyweight, instructions: ["Knees down.", "Lower chest.", "Push up."], tips: ["Keep back flat.", "Good for beginners."], audioCues: [0: "Knees down, hands under shoulders.", 15: "Lower with control — chest toward floor.", 30: "Good — halfway there.", 50: "Last few — finish strong."], difficulty: .beginner),
            Exercise(name: "Plank Shoulder Taps", exerciseDescription: "Core stability.", durationSeconds: 60, category: .bodyweight, instructions: ["High plank.", "Tap opposite shoulder.", "Switch."], tips: ["Don't rock hips.", "Stable base."], audioCues: [0: "High plank — brace your core.", 15: "Tap and hold — don't rock hips.", 30: "Steady hips — keep going.", 50: "Almost there — don't give up."], difficulty: .intermediate),
            Exercise(name: "Triceps Dips", exerciseDescription: "Using a chair or bench.", durationSeconds: 60, category: .bodyweight, instructions: ["Hands on chair edge.", "Lower hips.", "Push up."], tips: ["Keep back close to chair.", "Elbows back."], audioCues: [0: "Hands on chair edge, back straight.", 15: "Lower slow — elbows point back.", 30: "Halfway — keep the control.", 50: "Almost there — last few reps."], difficulty: .intermediate),
            Exercise(name: "Arm Circles", exerciseDescription: "Shoulder endurance.", durationSeconds: 60, category: .bodyweight, instructions: ["Arms out to sides.", "Small circles.", "Reverse."], tips: ["Keep arms straight.", "Controlled speed."], audioCues: [0: "Arms out — small circles forward.", 15: "Keep shoulders down and relaxed.", 30: "Reverse — circles going backward.", 50: "Almost there."], difficulty: .beginner),
            Exercise(name: "Inchworm Walks", exerciseDescription: "Full body mobility.", durationSeconds: 60, category: .bodyweight, instructions: ["Hinge and touch floor.", "Walk hands to plank.", "Walk hands back."], tips: ["Keep legs straight as possible.", "Stretch at top."], audioCues: [0: "Hinge down, touch the floor.", 15: "Walk hands out to plank.", 30: "Walk hands back — stand tall.", 50: "Almost there."], difficulty: .intermediate),
            Exercise(name: "Front Plank", exerciseDescription: "Core isometric.", durationSeconds: 60, category: .bodyweight, instructions: ["Support on elbows.", "Straight line."], tips: ["Don't sag.", "Squeeze glutes."], audioCues: [0: "Elbows under shoulders — hold plank.", 15: "Hips level — squeeze your glutes.", 30: "Breathe — don't hold your breath.", 50: "Last ten seconds — hold strong.", 55: "Five seconds left."], difficulty: .beginner),
            Exercise(name: "Side Plank", exerciseDescription: "Oblique focus.", durationSeconds: 60, category: .bodyweight, instructions: ["Support on one elbow side.", "Bridge up.", "Switch sides."], tips: ["Hips high.", "Chest open."], audioCues: [0: "Right side plank — hips lifted high.", 15: "Chest open — don't collapse inward.", 30: "Switch to your left side.", 50: "Almost there — hold it.", 55: "Five seconds left."], difficulty: .intermediate),
            Exercise(name: "Glute Bridges", exerciseDescription: "Posterior chain.", durationSeconds: 60, category: .bodyweight, instructions: ["Lie on back.", "Lift hips.", "Squeeze."], tips: ["Feet flat.", "Don't overarch."], audioCues: [0: "Lie back, feet flat, knees up.", 15: "Drive through your heels — lift hips.", 30: "Squeeze glutes at the top.", 50: "Almost there."], difficulty: .beginner),
            Exercise(name: "Bicycle Crunches", exerciseDescription: "Core rotation.", durationSeconds: 60, category: .bodyweight, instructions: ["Elbow to opposite knee.", "Switch."], tips: ["Shoulders off floor.", "Controlled motion."], audioCues: [0: "Shoulders off floor — elbow to knee.", 15: "Controlled rotation — no rushing.", 30: "Halfway — keep your core engaged.", 50: "Last few reps — finish strong."], difficulty: .intermediate),
            Exercise(name: "Leg Raises", exerciseDescription: "Lower core focus.", durationSeconds: 60, category: .bodyweight, instructions: ["Lie on back.", "Lift legs 90 deg.", "Lower slowly."], tips: ["Back flat on floor.", "Don't touch floor."], audioCues: [0: "Lie flat, press lower back down.", 15: "Raise both legs — slow and controlled.", 30: "Lower slowly — don't touch the floor.", 50: "Almost there."], difficulty: .intermediate),
            Exercise(name: "Mountain Climbers", exerciseDescription: "Cardio and core.", durationSeconds: 60, category: .bodyweight, instructions: ["High plank.", "Drive knees to chest."], tips: ["Keep hips low.", "Light on feet."], audioCues: [0: "High plank — drive your knees in.", 15: "Keep hips low — light on feet.", 30: "Halfway — maintain steady pace.", 50: "Last few seconds — push through."], difficulty: .intermediate),
            Exercise(name: "Squats", exerciseDescription: "Leg basics.", durationSeconds: 60, category: .bodyweight, instructions: ["Sit back onto heels.", "Stand up."], tips: ["Knees behind toes.", "Chest up."], audioCues: [0: "Feet shoulder-width, toes slightly out.", 15: "Knees track over toes — chest up.", 30: "Good pace — halfway there.", 50: "Last few — push through your heels."], difficulty: .beginner),
            Exercise(name: "Lunges", exerciseDescription: "Lower body balance.", durationSeconds: 60, category: .bodyweight, instructions: ["Step forward.", "Lower back knee.", "Push back."], tips: ["Torso upright.", "Controlled step."], audioCues: [0: "Step forward — right leg first.", 15: "Torso upright — lower with control.", 30: "Switch — now lead with left leg.", 50: "Almost there."], difficulty: .beginner),
            Exercise(name: "Calf Raises", exerciseDescription: "Lower leg strength.", durationSeconds: 60, category: .bodyweight, instructions: ["Rise onto toes.", "Lower."], tips: ["Hold at top.", "Go through full range."], audioCues: [0: "Rise onto your toes — hold at top.", 30: "Good range — keep going.", 50: "Almost there."], difficulty: .beginner),
            Exercise(name: "Wall Sit", exerciseDescription: "Quad isometric.", durationSeconds: 60, category: .bodyweight, instructions: ["Back against wall.", "Legs 90 deg.", "Hold."], tips: ["Push back.", "Relax arms."], audioCues: [0: "Back flat on wall, legs at 90.", 15: "Push back into wall — relax arms.", 30: "Halfway — breathe through it.", 50: "Ten seconds — hold on.", 55: "Five seconds left."], difficulty: .intermediate),
            Exercise(name: "Burpees", exerciseDescription: "Full body explosive.", durationSeconds: 60, category: .bodyweight, instructions: ["Squat, jump back, jump in, jump up."], tips: ["Maintain form.", "Steady pace."], audioCues: [0: "Squat down, jump back to plank.", 15: "Land softly — maintain your form.", 30: "Halfway — control the pace.", 50: "Last few — finish strong."], difficulty: .advanced),
            Exercise(name: "Clamshells", exerciseDescription: "Hip focus (Female focus).", durationSeconds: 60, category: .bodyweight, instructions: ["Side lying.", "Open knees.", "Switch sides."], tips: ["Hips stacked.", "Control the open."], audioCues: [0: "Lie on right side, knees bent.", 15: "Open your top knee — control it.", 30: "Switch to your left side.", 50: "Almost there."], difficulty: .beginner, genderFocus: .female),
            Exercise(name: "Diamond Push-ups", exerciseDescription: "Triceps focus (Male focus).", durationSeconds: 60, category: .bodyweight, instructions: ["Hands in diamond shape.", "Push up."], tips: ["Elbows in.", "Keep core tight."], audioCues: [0: "Hands in diamond, high plank position.", 15: "Elbows in — lower with control.", 30: "Good work — halfway through.", 50: "Last few — finish strong."], difficulty: .advanced, genderFocus: .male),
            Exercise(name: "Jump Squats", exerciseDescription: "Explosive power (Male focus).", durationSeconds: 60, category: .bodyweight, instructions: ["Squat and jump."], tips: ["Land softly.", "Use your arms."], audioCues: [0: "Squat low — explode up.", 15: "Land softly — absorb with legs.", 30: "Good power — halfway there.", 50: "Last few — land with control."], difficulty: .advanced, genderFocus: .male)
        ]
    }

    /// New bodyweight exercises added in this update (002-exercise-review).
    private static func newBodyweightExercises() -> [Exercise] {
        [
            Exercise(
                name: "Superman Hold",
                exerciseDescription: "Back extension for posture.",
                durationSeconds: 60,
                category: .bodyweight,
                instructions: [
                    "Lie face down with arms extended overhead.",
                    "Simultaneously lift your arms, chest, and legs off the floor.",
                    "Hold for 3 to 5 seconds.",
                    "Lower slowly.",
                    "Repeat."
                ],
                tips: [
                    "Lift gently — you don't need to go high.",
                    "Keep your neck neutral — look at the floor.",
                    "Squeeze your glutes as you lift."
                ],
                audioCues: [
                    0: "Lie face down. Arms overhead.",
                    5: "Lift everything off the floor. Hold.",
                    10: "Lower slowly.",
                    15: "And lift again.",
                    30: "Keep your neck neutral — look down.",
                    50: "Almost there.",
                    55: "Five seconds left."
                ]
            ),
            Exercise(
                name: "Dead Bug",
                exerciseDescription: "Deep core stability exercise.",
                durationSeconds: 60,
                category: .bodyweight,
                instructions: [
                    "Lie on your back with arms pointing to the ceiling.",
                    "Lift your legs to a tabletop position, knees at 90 degrees.",
                    "Slowly extend your right arm overhead and left leg out straight.",
                    "Return to center.",
                    "Switch sides."
                ],
                tips: [
                    "Press your lower back into the floor throughout.",
                    "Move slowly — this is about control, not speed.",
                    "If it's too hard, keep your knees bent as you extend."
                ],
                audioCues: [
                    0: "Arms up, knees at 90 degrees.",
                    5: "Right arm back, left leg out.",
                    10: "Return to center.",
                    15: "Left arm back, right leg out.",
                    30: "Press lower back into the floor.",
                    50: "Almost there."
                ]
            ),
            Exercise(
                name: "Bird Dog",
                exerciseDescription: "Balance and core coordination.",
                durationSeconds: 60,
                category: .bodyweight,
                instructions: [
                    "Start on all fours with a flat back.",
                    "Extend your right arm forward and left leg back simultaneously.",
                    "Hold for 3 seconds.",
                    "Return to all fours.",
                    "Switch to left arm and right leg."
                ],
                tips: [
                    "Keep your hips level — don't let them rotate.",
                    "Move slowly and deliberately.",
                    "Imagine balancing a cup of water on your lower back."
                ],
                audioCues: [
                    0: "On all fours. Flat back.",
                    5: "Right arm and left leg out.",
                    10: "Return.",
                    15: "Left arm and right leg out.",
                    30: "Keep your hips level and square.",
                    50: "Almost there."
                ]
            )
        ]
    }

    // MARK: - Balance Exercises (new category — 002-exercise-review)

    /// Balance exercises focused on stability, proprioception, and fall prevention.
    /// All exercises include chair/wall safety instructions for elderly users.
    private static func balanceExercises() -> [Exercise] {
        [
            Exercise(
                name: "Single-Leg Stand",
                exerciseDescription: "Fundamental one-leg balance hold.",
                durationSeconds: 60,
                category: .balance,
                instructions: [
                    "Stand near a chair or wall for support.",
                    "Shift your weight to one leg.",
                    "Lift the opposite foot off the ground.",
                    "Hold as long as comfortable.",
                    "Switch legs."
                ],
                tips: [
                    "Keep a chair within arm's reach for safety.",
                    "Focus your eyes on a fixed point ahead.",
                    "Start with short holds and build up gradually."
                ],
                audioCues: [
                    0: "Hold a chair if needed. Right foot up.",
                    15: "Eyes on a fixed point ahead.",
                    30: "Switch to your left foot.",
                    50: "Almost there."
                ]
            ),
            Exercise(
                name: "Heel-to-Toe Walk",
                exerciseDescription: "Straight-line tandem walking for stability.",
                durationSeconds: 60,
                category: .balance,
                instructions: [
                    "Stand near a wall or counter for support.",
                    "Place the heel of one foot directly in front of the toes of the other.",
                    "Walk in a straight line.",
                    "Take 10 to 15 steps.",
                    "Turn carefully and repeat."
                ],
                tips: [
                    "Walk alongside a wall you can touch for safety.",
                    "Keep your gaze forward, not down at your feet.",
                    "Go slowly — speed is not the goal."
                ],
                audioCues: [
                    0: "Near a wall. Heel in front of toes.",
                    15: "Arms out — eyes forward, not down.",
                    30: "Keep going, nice and steady.",
                    50: "Almost there."
                ]
            ),
            Exercise(
                name: "Tree Pose",
                exerciseDescription: "Yoga-inspired single-leg balance.",
                durationSeconds: 60,
                category: .balance,
                instructions: [
                    "Stand near a chair or wall.",
                    "Shift your weight to one leg.",
                    "Place the other foot on your inner calf or thigh — never on the knee.",
                    "Bring hands to chest or overhead.",
                    "Switch legs."
                ],
                tips: [
                    "Use a chair for support until you feel confident.",
                    "Never place your foot directly on the knee joint.",
                    "Start with your foot on the calf before progressing higher."
                ],
                audioCues: [
                    0: "Keep a chair close. Right leg balancing.",
                    15: "Hold the chair if needed — breathe.",
                    30: "Switch to your left leg.",
                    50: "Almost there."
                ]
            ),
            Exercise(
                name: "Standing Knee Lifts",
                exerciseDescription: "Alternating slow knee raises for balance.",
                durationSeconds: 60,
                category: .balance,
                instructions: [
                    "Stand tall near a chair for support.",
                    "Slowly lift one knee to hip height.",
                    "Hold briefly at the top.",
                    "Lower the leg slowly and with control.",
                    "Alternate legs."
                ],
                tips: [
                    "Hold the back of a chair if you feel unsteady.",
                    "Keep your standing leg slightly bent.",
                    "Maintain an upright posture throughout."
                ],
                audioCues: [
                    0: "Hold a chair. Lift your right knee.",
                    15: "Lower and switch.",
                    30: "Lift your left knee.",
                    45: "Lower and switch.",
                    50: "Almost there."
                ]
            ),
            Exercise(
                name: "Weight Shifts",
                exerciseDescription: "Side-to-side weight transfer for stability.",
                durationSeconds: 60,
                category: .balance,
                instructions: [
                    "Stand with feet hip-width apart.",
                    "Keep a chair nearby.",
                    "Slowly shift your weight to your right foot.",
                    "Hold for a few seconds.",
                    "Shift your weight to your left foot.",
                    "Repeat smoothly side to side."
                ],
                tips: [
                    "Keep a chair nearby for safety.",
                    "This is an excellent starter exercise for balance.",
                    "Move gently and deliberately — no sudden shifts."
                ],
                audioCues: [
                    0: "Feet hip-width apart. Shift weight to your right.",
                    15: "Now shift to your left.",
                    30: "Back to the right.",
                    45: "And to the left.",
                    50: "Almost there."
                ]
            ),
            Exercise(
                name: "Clock Reach",
                exerciseDescription: "Single-leg reach to clock positions.",
                durationSeconds: 60,
                category: .balance,
                instructions: [
                    "Stand on one leg near a chair for support.",
                    "Imagine you are standing at the center of a clock.",
                    "Reach your opposite foot toward 12 o'clock, then 3, then 6, then 9.",
                    "Return to center each time.",
                    "Switch standing legs."
                ],
                tips: [
                    "Use a chair for support when starting out.",
                    "Keep the reaching leg light — just a gentle tap, not a full weight transfer.",
                    "This exercise challenges balance in all directions."
                ],
                audioCues: [
                    0: "Hold a chair. Stand on your right leg.",
                    10: "Reach to 12 o'clock.",
                    20: "Reach to 3 o'clock.",
                    30: "Switch legs. Stand on your left.",
                    40: "Reach to 12.",
                    50: "Reach to 9 o'clock.",
                    55: "Almost there."
                ],
                difficulty: .intermediate
            )
        ]
    }

    // MARK: - Routines

    private static func routines() -> [Routine] {
        [
            // Existing
            Routine(name: "Morning Wake-Up", routineDescription: "8 min sequence to start the day.", exerciseNames: ["Neck Tilts", "Cat-Cow", "Hamstring Stretch", "Box Breathing"]),
            Routine(name: "Core & Mobility", routineDescription: "12 min focus on stability.", exerciseNames: ["Front Plank", "Glute Bridges", "Side Reach Stretch", "Belly Breathing"]),
            Routine(name: "Relax & De-Stress", routineDescription: "5 min evening wind-down.", exerciseNames: ["Child's Pose", "Side Reach Stretch", "4-7-8 Breathing"]),
            Routine(name: "Full Body Strength", routineDescription: "15 min workout.", exerciseNames: ["Squats", "Push-ups", "Mountain Climbers", "Wall Sit", "Alternate Nostril Breathing"]),

            // New
            Routine(name: "Desk Break", routineDescription: "5 min relief for office workers.", exerciseNames: ["Shoulder Rolls", "Neck Tilts", "Wrist & Forearm Stretch", "Chest Stretch (Doorway)", "Pursed Lip Breathing"]),
            Routine(name: "Lower Body Burn", routineDescription: "12 min legs and glutes focus.", exerciseNames: ["Squats", "Lunges", "Glute Bridges", "Calf Raises", "Clamshells"]),
            Routine(name: "Balance & Stability", routineDescription: "10 min fall-prevention training.", exerciseNames: ["Single-Leg Stand", "Heel-to-Toe Walk", "Weight Shifts", "Standing Knee Lifts", "Clock Reach"]),
            Routine(name: "Deep Stretch", routineDescription: "15 min full-body flexibility.", exerciseNames: ["Cat-Cow", "Butterfly Stretch", "Figure-4 Stretch", "Hip Flexor Stretch", "IT Band Stretch", "Seated Spinal Twist", "Child's Pose"]),
            Routine(name: "Power Circuit", routineDescription: "20 min high-intensity circuit.", exerciseNames: ["Jump Squats", "Burpees", "Mountain Climbers", "Push-ups", "Bicycle Crunches", "Plank Shoulder Taps", "Box Breathing"]),
            Routine(name: "Breathwork & Calm", routineDescription: "8 min breathing and relaxation.", exerciseNames: ["Belly Breathing", "4-7-8 Breathing", "Resonant Breathing", "Progressive Relaxation"]),
            Routine(name: "Upper Body Strength", routineDescription: "12 min arms, chest, and back.", exerciseNames: ["Push-ups", "Diamond Push-ups", "Triceps Dips", "Plank Shoulder Taps", "Superman Hold", "Arm Circles"]),
            Routine(name: "Gentle Morning", routineDescription: "10 min low-impact wake-up.", exerciseNames: ["Shoulder Rolls", "Neck Tilts", "Cat-Cow", "Side Reach Stretch", "Hamstring Stretch", "Belly Breathing"]),

            // Focus areas (008)
            Routine(name: "Shoulder Mobility", routineDescription: "Gentle stretches for a stiff shoulder.", exerciseNames: ["Pendulum Swing", "Finger Wall Walk", "Cross-Body Arm Stretch", "Towel Stretch", "Outward Rotation Stretch", "Armpit Stretch"]),
            Routine(name: "Diaphragm Training", routineDescription: "Slow, steady breathing to strengthen your diaphragm.", exerciseNames: ["Seated Diaphragm Breathing", "360° Rib Breathing", "Diaphragm Breathing (Lying)", "Weighted Belly Breathing"]),
            Routine(name: "Lower Back Mobility", routineDescription: "Gentle movement for a stiff lower back.", exerciseNames: ["Cat-Cow", "Seated Spinal Twist", "Bird Dog", "Child's Pose", "Figure-4 Stretch", "Belly Breathing"])
        ]
    }
}

// MARK: - This for That

/// A habit-forming pact: do "This" (an exercise or habit) to earn "That" (a treat).
/// Per-session pacts bank a treat every `targetCount` completions; weekly pacts bank one
/// treat per calendar week once "This" is done on `targetCount` different days.
@Model
final class ThisForThat {
    var thisAction: String
    var thatTreat: String
    var treatIcon: String = "gift.fill"
    var timesEarned: Int = 0
    var timesClaimed: Int = 0
    var lastEarnedAt: Date?
    var createdAt: Date = Date()

    var isWeekly: Bool = false
    var targetCount: Int = 1
    /// Per-session progress towards the next treat.
    var sessionProgress: Int = 0
    var completionDates: [Date] = []
    /// Start of the week a weekly treat was last awarded, so it's only earned once per week.
    var rewardedWeekStart: Date?

    init(thisAction: String, thatTreat: String, treatIcon: String = "gift.fill", isWeekly: Bool = false, targetCount: Int = 1) {
        self.thisAction = thisAction
        self.thatTreat = thatTreat
        self.treatIcon = treatIcon
        self.isWeekly = isWeekly
        self.targetCount = targetCount
    }

    /// Treats earned but not yet enjoyed.
    var bankedTreats: Int { max(timesEarned - timesClaimed, 0) }

    var doneToday: Bool {
        completionDates.contains { Calendar.current.isDateInToday($0) }
    }

    static var currentWeek: DateInterval {
        Calendar.current.dateInterval(of: .weekOfYear, for: Date())
            ?? DateInterval(start: Calendar.current.startOfDay(for: Date()), duration: 7 * 86_400)
    }

    /// The seven days of the current week, in the user's locale order.
    static var currentWeekDays: [Date] {
        (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: currentWeek.start) }
    }

    /// Distinct days in the current week on which "This" was done.
    var daysDoneThisWeek: Set<Date> {
        let week = Self.currentWeek
        return Set(completionDates.filter { week.contains($0) }.map { Calendar.current.startOfDay(for: $0) })
    }

    var rewardedThisWeek: Bool {
        rewardedWeekStart == Self.currentWeek.start
    }

    /// Progress towards the next treat, as (done, target).
    var progress: (done: Int, target: Int) {
        isWeekly ? (min(daysDoneThisWeek.count, targetCount), targetCount) : (sessionProgress, targetCount)
    }

    var goalLabel: String {
        if isWeekly {
            return "\(targetCount) day\(targetCount == 1 ? "" : "s") a week"
        }
        return targetCount == 1 ? "Every time" : "Every \(targetCount) times"
    }

    /// Records a completion. Returns true when this completion earned a treat.
    @discardableResult
    func markDone() -> Bool {
        if isWeekly {
            guard !doneToday else { return false }
            completionDates.append(Date())
            guard !rewardedThisWeek, daysDoneThisWeek.count >= targetCount else { return false }
            rewardedWeekStart = Self.currentWeek.start
        } else {
            completionDates.append(Date())
            sessionProgress += 1
            guard sessionProgress >= targetCount else { return false }
            sessionProgress = 0
        }
        timesEarned += 1
        lastEarnedAt = Date()
        return true
    }

    func claimTreat() {
        guard bankedTreats > 0 else { return }
        timesClaimed += 1
    }

    /// SF Symbols offered when picking a treat icon.
    static let treatIcons = [
        "gift.fill", "birthday.cake.fill", "cup.and.saucer.fill", "mug.fill", "takeoutbag.and.cup.and.straw.fill",
        "fork.knife", "wineglass.fill", "tv.fill", "gamecontroller.fill", "music.note",
        "book.fill", "bag.fill", "bed.double.fill", "sparkles",
    ]
}
