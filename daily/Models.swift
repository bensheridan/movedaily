import Foundation
import SwiftData
import UIKit

enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
    case stretching = "Stretching"
    case breathing = "Breathing"
    case bodyweight = "Bodyweight"
    case kegels = "Kegels"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .stretching: return "figure.flexibility"
        case .breathing: return "wind"
        case .bodyweight: return "figure.strengthtraining.traditional"
        case .kegels: return "figure.highintensity.intervaltraining"
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

@Model
final class UserProfile {
    var gender: Gender
    var xp: Int
    var level: Int
    var streakCount: Int
    var lastExerciseDate: Date?
    var profileImageData: Data?
    
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
     */
    func completeRoutine(baseXP: Int = 20) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Normalize last exercise date to start of day for comparison
        guard let lastExercise = lastExerciseDate else {
            // First time completing routine
            streakCount = 1
            xp += baseXP
            awardBonusXPIfNeeded()
            levelUpIfNeeded()
            lastExerciseDate = today
            return
        }
        
        let lastDate = calendar.startOfDay(for: lastExercise)
        
        if lastDate == today {
            // Already completed today, no XP or streak update
            return
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
    
    init(name: String, 
         exerciseDescription: String, 
         durationSeconds: Int, 
         category: ExerciseCategory, 
         instructions: [String],
         tips: [String] = [],
         audioCues: [Int: String] = [:],
         difficulty: Difficulty = .beginner,
         genderFocus: Gender? = nil) {
        self.name = name
        self.exerciseDescription = exerciseDescription
        self.durationSeconds = durationSeconds
        self.category = category
        self.difficulty = difficulty
        self.genderFocus = genderFocus
        self.instructions = instructions
        self.tips = tips
        self.audioCues = audioCues
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

// MARK: - Seeding
extension Exercise {
    static func seedInitialData(context: ModelContext) {
        let exerciseFetch = FetchDescriptor<Exercise>()
        if let count = try? context.fetchCount(exerciseFetch), count > 0 {
            return
        }
        
        let allExercises = stretchingExercises() + breathingExercises() + bodyweightExercises() + kegelExercises()
        for exercise in allExercises {
            context.insert(exercise)
        }
        
        let allRoutines = routines()
        for routine in allRoutines {
            context.insert(routine)
        }
    }
    
    private static func stretchingExercises() -> [Exercise] {
        [
            Exercise(name: "Neck Tilts", exerciseDescription: "Forward, backward, and side-to-side tilts.", durationSeconds: 60, category: .stretching, instructions: ["Sit tall.", "Tilt head forward, then back.", "Tilt ear to shoulder on each side."], tips: ["Move slowly.", "Relax your shoulders."], audioCues: [0: "Tilt your head forward.", 15: "Now tilt it back.", 30: "Right side.", 45: "Left side."]),
            Exercise(name: "Shoulder Rolls", exerciseDescription: "Roll shoulders forward and backward.", durationSeconds: 60, category: .stretching, instructions: ["Stand upright.", "Roll shoulders up and forward.", "Reverse the motion half-way through."], tips: ["Keep it smooth.", "Don't rush."], audioCues: [0: "Roll forward.", 30: "Now roll backward."]),
            Exercise(name: "Chest Stretch (Doorway)", exerciseDescription: "Open your anterior shoulders.", durationSeconds: 60, category: .stretching, instructions: ["Stand in a doorway.", "Place forearms on the frame.", "Lean forward slightly."], tips: ["You should feel a stretch in your chest.", "Don't overextend."], audioCues: [0: "Place your arms on the frame.", 10: "Lean forward and hold."]),
            Exercise(name: "Cat-Cow", exerciseDescription: "Spinal mobility on all fours.", durationSeconds: 60, category: .stretching, instructions: ["On all fours.", "Inhale, arch back.", "Exhale, round back."], tips: ["Move with your breath.", "Keep neck aligned."], audioCues: [0: "Inhale and arch.", 10: "Exhale and round."]),
            Exercise(name: "Triceps Stretch", exerciseDescription: "Overhead arm pull.", durationSeconds: 60, category: .stretching, instructions: ["One arm overhead.", "Bend elbow.", "Pull elbow with other hand.", "Switch sides."], tips: ["Keep your chest upright.", "Don't push too hard."], audioCues: [0: "Right arm up.", 30: "Switch to left arm."]),
            Exercise(name: "Side Reach Stretch", exerciseDescription: "Lateral torso stretch.", durationSeconds: 60, category: .stretching, instructions: ["Stand with feet apart.", "Reach one arm over head to the side.", "Switch sides."], tips: ["Feel the stretch in your obliques.", "Stay in control."], audioCues: [0: "Reach to the left.", 30: "Reach to the right."]),
            Exercise(name: "Hamstring Stretch", exerciseDescription: "Seated or standing leg reach.", durationSeconds: 60, category: .stretching, instructions: ["Extend one leg.", "Hinge at hips.", "Reach for toes.", "Switch legs."], tips: ["Keep back flat.", "Lead with chest."], audioCues: [0: "Right leg forward.", 30: "Switch to left leg."]),
            Exercise(name: "Quadriceps Stretch", exerciseDescription: "Standing leg pull.", durationSeconds: 60, category: .stretching, instructions: ["Stand on one leg.", "Pull other foot to glute.", "Switch legs."], tips: ["Keep knees together.", "Find a balance point."], audioCues: [0: "Right leg up.", 30: "Left leg up."]),
            Exercise(name: "Calf Stretch", exerciseDescription: "Against a wall.", durationSeconds: 60, category: .stretching, instructions: ["Hands on wall.", "One leg back, heel down.", "Switch legs."], tips: ["Keep back leg straight.", "Push into the wall."], audioCues: [0: "Right leg back.", 30: "Left leg back."]),
            Exercise(name: "Hip Flexor Stretch", exerciseDescription: "Lunge position stretch.", durationSeconds: 60, category: .stretching, instructions: ["Kneel on one knee.", "Lean forward into hips.", "Switch sides."], tips: ["Keep torso upright.", "Squeeze glute of back leg."], audioCues: [0: "Right knee down.", 30: "Left knee down."]),
            Exercise(name: "Figure-4 Stretch", exerciseDescription: "Glute focus (Female focus).", durationSeconds: 60, category: .stretching, instructions: ["Lie on back.", "Cross ankle over knee.", "Pull knee to chest."], tips: ["Feel it in your glutes.", "Breathe through it."], audioCues: [0: "Cross your right leg.", 30: "Now switch legs."], genderFocus: .female),
            Exercise(name: "Butterfly Stretch", exerciseDescription: "Inner thigh focus (Female focus).", durationSeconds: 60, category: .stretching, instructions: ["Sit with soles of feet together.", "Press knees down.", "Lean forward."], tips: ["Gentle pressure.", "Keep feet close."], audioCues: [0: "Press your knees down.", 30: "Lean forward slightly."], genderFocus: .female),
            Exercise(name: "Child's Pose", exerciseDescription: "Lower back focus (Male focus).", durationSeconds: 60, category: .stretching, instructions: ["Kneel.", "Sit on heels.", "Reach forward."], tips: ["Widen knees if needed.", "Relax forehead."], audioCues: [0: "Reach forward and rest."], genderFocus: .male),
            Exercise(name: "IT Band Stretch", exerciseDescription: "Lower body band stretch (Male focus).", durationSeconds: 60, category: .stretching, instructions: ["Cross one leg behind.", "Lean toward the same side.", "Switch."], tips: ["Feel it on the outer hip.", "Balance yourself."], audioCues: [0: "Lean to the right.", 30: "Lean to the left."], genderFocus: .male)
        ]
    }
    
    private static func breathingExercises() -> [Exercise] {
        [
            Exercise(name: "Belly Breathing", exerciseDescription: "Diaphragmatic focus.", durationSeconds: 180, category: .breathing, instructions: ["Hand on belly.", "Inhale, belly out.", "Exhale, belly in."], tips: ["Breathe deep.", "Relax chest."], audioCues: [0: "Hand on belly.", 5: "Inhale deep.", 10: "Long exhale."]),
            Exercise(name: "4-7-8 Breathing", exerciseDescription: "Tranquilizing breath.", durationSeconds: 120, category: .breathing, instructions: ["Inhale 4s.", "Hold 7s.", "Exhale 8s."], tips: ["Make the whoosh sound.", "Keep tip of tongue on ridge."], audioCues: [0: "Inhale 4.", 4: "Hold 7.", 11: "Whoosh out 8."]),
            Exercise(name: "Box Breathing", exerciseDescription: "Square breathing (4-4-4-4).", durationSeconds: 300, category: .breathing, instructions: ["Inhale 4s.", "Hold 4s.", "Exhale 4s.", "Hold 4s."], tips: ["Equal counts.", "Mental focus."], audioCues: [0: "Inhale 4.", 4: "Hold 4.", 8: "Exhale 4.", 12: "Hold 4."]),
            Exercise(name: "Alternate Nostril Breathing", exerciseDescription: "Balance focus.", durationSeconds: 180, category: .breathing, instructions: ["Close one nostril.", "Inhale other.", "Switch nostrils.", "Exhale."], tips: ["Keep it gentle.", "Don't force."], audioCues: [0: "Close right, inhale left.", 10: "Close left, exhale right."]),
            Exercise(name: "Pursed Lip Breathing", exerciseDescription: "Ease of breath.", durationSeconds: 120, category: .breathing, instructions: ["Inhale through nose.", "Exhale through pursed lips."], tips: ["Slow the exhale.", "Like blowing out a candle."], audioCues: [0: "Inhale nose.", 5: "Pursed lip exhale."]),
            Exercise(name: "Resonant Breathing", exerciseDescription: "6 breaths per minute.", durationSeconds: 300, category: .breathing, instructions: ["5.5s inhale.", "5.5s exhale."], tips: ["Coherent rhythm.", "Steady flow."], audioCues: [0: "Inhale slowly.", 6: "Exhale slowly."]),
            Exercise(name: "Gentle Breath Holds", exerciseDescription: "Body awareness.", durationSeconds: 120, category: .breathing, instructions: ["Inhale.", "Hold comfortably.", "Exhale."], tips: ["Don't push limits.", "Stay relaxed."], audioCues: [0: "Inhale.", 5: "Gentle hold.", 15: "Exhale."]),
            Exercise(name: "Progressive Relaxation", exerciseDescription: "Deep rest.", durationSeconds: 300, category: .breathing, instructions: ["Tense and release muscles with breath."], tips: ["Start from toes.", "Work up to head."], audioCues: [0: "Relax your toes.", 30: "Relax your legs."])
        ]
    }
    
    private static func bodyweightExercises() -> [Exercise] {
        [
            Exercise(name: "Push-ups", exerciseDescription: "Standard chest and arms.", durationSeconds: 60, category: .bodyweight, instructions: ["High plank.", "Lower chest.", "Push up."], tips: ["Core tight.", "Elbows at 45 deg."], difficulty: .beginner),
            Exercise(name: "Knee Push-ups", exerciseDescription: "Modified push-up.", durationSeconds: 60, category: .bodyweight, instructions: ["Knees down.", "Lower chest.", "Push up."], tips: ["Keep back flat.", "Good for beginners."], difficulty: .beginner),
            Exercise(name: "Plank Shoulder Taps", exerciseDescription: "Core stability.", durationSeconds: 60, category: .bodyweight, instructions: ["High plank.", "Tap opposite shoulder.", "Switch."], tips: ["Don't rock hips.", "Stable base."], difficulty: .intermediate),
            Exercise(name: "Triceps Dips", exerciseDescription: "Using a chair or bench.", durationSeconds: 60, category: .bodyweight, instructions: ["Hands on chair edge.", "Lower hips.", "Push up."], tips: ["Keep back close to chair.", "Elbows back."], difficulty: .intermediate),
            Exercise(name: "Arm Circles", exerciseDescription: "Shoulder endurance.", durationSeconds: 60, category: .bodyweight, instructions: ["Arms out to sides.", "Small circles.", "Reverse."], tips: ["Keep arms straight.", "Controlled speed."], difficulty: .beginner),
            Exercise(name: "Inchworm Walks", exerciseDescription: "Full body mobility.", durationSeconds: 60, category: .bodyweight, instructions: ["Hinge and touch floor.", "Walk hands to plank.", "Walk hands back."], tips: ["Keep legs straight as possible.", "Stretch at top."], difficulty: .intermediate),
            Exercise(name: "Front Plank", exerciseDescription: "Core isometric.", durationSeconds: 60, category: .bodyweight, instructions: ["Support on elbows.", "Straight line."], tips: ["Don't sag.", "Squeeze glutes."], difficulty: .beginner),
            Exercise(name: "Side Plank", exerciseDescription: "Oblique focus.", durationSeconds: 60, category: .bodyweight, instructions: ["Support on one elbow side.", "Bridge up.", "Switch sides."], tips: ["Hips high.", "Chest open."], difficulty: .intermediate),
            Exercise(name: "Glute Bridges", exerciseDescription: "Posterior chain.", durationSeconds: 60, category: .bodyweight, instructions: ["Lie on back.", "Lift hips.", "Squeeze."], tips: ["Feet flat.", "Don't overarch."], difficulty: .beginner),
            Exercise(name: "Bicycle Crunches", exerciseDescription: "Core rotation.", durationSeconds: 60, category: .bodyweight, instructions: ["Elbow to opposite knee.", "Switch."], tips: ["Shoulders off floor.", "Controlled motion."], difficulty: .intermediate),
            Exercise(name: "Leg Raises", exerciseDescription: "Lower core focus.", durationSeconds: 60, category: .bodyweight, instructions: ["Lie on back.", "Lift legs 90 deg.", "Lower slowly."], tips: ["Back flat on floor.", "Don't touch floor."], difficulty: .intermediate),
            Exercise(name: "Mountain Climbers", exerciseDescription: "Cardio and core.", durationSeconds: 60, category: .bodyweight, instructions: ["High plank.", "Drive knees to chest."], tips: ["Keep hips low.", "Light on feet."], difficulty: .intermediate),
            Exercise(name: "Squats", exerciseDescription: "Leg basics.", durationSeconds: 60, category: .bodyweight, instructions: ["Sit back onto heels.", "Stand up."], tips: ["Knees behind toes.", "Chest up."], difficulty: .beginner),
            Exercise(name: "Lunges", exerciseDescription: "Lower body balance.", durationSeconds: 60, category: .bodyweight, instructions: ["Step forward.", "Lower back knee.", "Push back."], tips: ["Torso upright.", "Controlled step."], difficulty: .beginner),
            Exercise(name: "Calf Raises", exerciseDescription: "Lower leg strength.", durationSeconds: 60, category: .bodyweight, instructions: ["Rise onto toes.", "Lower."], tips: ["Hold at top.", "Go through full range."], difficulty: .beginner),
            Exercise(name: "Wall Sit", exerciseDescription: "Quad isometric.", durationSeconds: 60, category: .bodyweight, instructions: ["Back against wall.", "Legs 90 deg.", "Hold."], tips: ["Push back.", "Relax arms."], difficulty: .intermediate),
            Exercise(name: "Burpees", exerciseDescription: "Full body explosive.", durationSeconds: 60, category: .bodyweight, instructions: ["Squat, jump back, jump in, jump up."], tips: ["Maintain form.", "Steady pace."], difficulty: .advanced),
            Exercise(name: "Clamshells", exerciseDescription: "Hip focus (Female focus).", durationSeconds: 60, category: .bodyweight, instructions: ["Side lying.", "Open knees.", "Switch sides."], tips: ["Hips stacked.", "Control the open."], difficulty: .beginner, genderFocus: .female),
            Exercise(name: "Diamond Push-ups", exerciseDescription: "Triceps focus (Male focus).", durationSeconds: 60, category: .bodyweight, instructions: ["Hands in diamond shape.", "Push up."], tips: ["Elbows in.", "Keep core tight."], difficulty: .advanced, genderFocus: .male),
            Exercise(name: "Jump Squats", exerciseDescription: "Explosive power (Male focus).", durationSeconds: 60, category: .bodyweight, instructions: ["Squat and jump."], tips: ["Land softly.", "Use your arms."], difficulty: .advanced, genderFocus: .male)
        ]
    }
    
    private static func kegelExercises() -> [Exercise] {
        [
            // Universal / Initial Identification
            Exercise(name: "Muscle Discovery", exerciseDescription: "Find your pelvic floor muscles.", durationSeconds: 60, category: .kegels, instructions: ["Imagine stopping urine midstream.", "Tighten as if stopping gas.", "Feel the lift and squeeze."], tips: ["Sit or lie down at first.", "Isolate the muscle.", "Don't hold your breath."], audioCues: [0: "Squeeze to find the muscle.", 5: "Now relax completely."]),
            
            // Male Focus (Refined by Research)
            Exercise(name: "Standard Kegels", exerciseDescription: "Long holds for endurance.", durationSeconds: 120, category: .kegels, instructions: ["Imagine pulling your scrotum up.", "Squeeze for 3-5 seconds.", "Relax for 3-5 seconds."], tips: ["Count out loud to breathe.", "Don't squeeze your butt.", "Relax your thighs."], audioCues: [0: "Lift and hold for 5.", 5: "Relax for 5.", 10: "Hold again."], genderFocus: .male),
            
            Exercise(name: "Power Pulses", exerciseDescription: "Fast power reps.", durationSeconds: 60, category: .kegels, instructions: ["Quickly squeeze and relax.", "Aim for 1 pulse per second."], tips: ["Flicker sensation.", "Keep it isolated.", "Breath normally."], audioCues: [0: "Quick pulses start now.", 1: "Squeeze, relax.", 2: "Squeeze, relax."], genderFocus: .male),

            // Female Focus
            Exercise(name: "Standard Kegels", exerciseDescription: "Pelvic floor endurance.", durationSeconds: 120, category: .kegels, instructions: ["Contract the pelvic floor.", "Squeeze for 3-5 seconds.", "Relax for 3-5 seconds."], tips: ["Imagine an elevator lift.", "Don't hold your breath.", "Keep core relaxed."], audioCues: [0: "Squeeze and lift.", 5: "Now relax completely."], genderFocus: .female),
            
            Exercise(name: "Elevator Kegels", exerciseDescription: "Gradual control.", durationSeconds: 120, category: .kegels, instructions: ["Squeeze in 3 stages.", "Relax in 3 stages."], tips: ["Control is key.", "Smooth movement.", "Don't push down."], audioCues: [0: "Stage 1 squeeze.", 5: "Stage 2.", 10: "Stage 3 hold.", 15: "Stage 2 relax."], genderFocus: .female)
        ]
    }
    
    private static func routines() -> [Routine] {
        [
            Routine(name: "Morning Wake-Up", routineDescription: "8 min sequence to start the day.", exerciseNames: ["Neck Tilts", "Cat-Cow", "Hamstring Stretch", "Box Breathing"]),
            Routine(name: "Core & Mobility", routineDescription: "12 min focus on stability.", exerciseNames: ["Front Plank", "Glute Bridges", "Side Reach Stretch", "Belly Breathing"]),
            Routine(name: "Relax & De-Stress", routineDescription: "5 min evening wind-down.", exerciseNames: ["Child's Pose", "Side Reach Stretch", "4-7-8 Breathing", "Standard Kegels"]),
            Routine(name: "Full Body Strength", routineDescription: "15 min workout.", exerciseNames: ["Squats", "Push-ups", "Mountain Climbers", "Wall Sit", "Alternate Nostril Breathing"])
        ]
    }
}

