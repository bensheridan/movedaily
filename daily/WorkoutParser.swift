import Foundation

// MARK: - Public return types

struct ParsedDay {
    var name: String
    var exercises: [ParsedExerciseResult]
}

struct ParsedExerciseResult {
    var name: String
    var value: Int
    var unit: String
}

// MARK: - Errors

enum WorkoutParserError: LocalizedError {
    case emptyResult

    var errorDescription: String? {
        "No exercises could be found. Try including exercise names with set counts or durations."
    }
}

// MARK: - Parser
//
// Regex-based workout parser — fully on-device, instant, no Apple Intelligence
// dependency. Handles the common patterns found in typed/pasted workout programs:
//   • Name × N          → N sets
//   • Name → N × M      → N sets
//   • Name → N × M sec  → N sets (timed sets)
//   1. Name             → pending; next line "N × M" → N sets
//   Name                → pending; next line "N × M" → N sets

struct WorkoutParser {
    // async to match the caller; no async work is done.
    static func parse(text: String) async throws -> [ParsedDay] {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }

        let chunks = splitByDay(lines)
        let days = chunks.compactMap { (name, chunk) -> ParsedDay? in
            let exercises = extractExercises(from: chunk)
            return exercises.isEmpty ? nil : ParsedDay(name: name, exercises: exercises)
        }

        guard !days.isEmpty else { throw WorkoutParserError.emptyResult }
        return days
    }

    // MARK: - Exercise extraction

    private static func extractExercises(from lines: [String]) -> [ParsedExerciseResult] {
        var results: [ParsedExerciseResult] = []
        var pending: String? = nil

        for line in lines {
            guard !line.isEmpty else { continue }

            // 1. Inline: line contains both a name and a quantity
            if let ex = parseInline(line) {
                pending = nil
                results.append(ex)
                continue
            }

            // 2. Standalone quantity: "N × M", "N × M–P", "N × M sec"
            //    Pair with the most recent pending name.
            if let qty = parseStandaloneQuantity(line) {
                if let name = pending {
                    results.append(ParsedExerciseResult(name: name, value: qty.value, unit: qty.unit))
                }
                pending = nil
                continue
            }

            // 3. Section label → clears pending without consuming it
            if isSectionLabel(line) {
                pending = nil
                continue
            }

            // 4. Exercise name candidate → becomes pending
            if let name = asExerciseName(line) {
                pending = name
            }
        }
        return results
    }

    // MARK: - Line parsers

    /// "• Band pull-aparts × 20", "• Squat → 4 × 6–8", "• Side plank → 3 × 30 sec"
    private static func parseInline(_ raw: String) -> ParsedExerciseResult? {
        let line = stripBullet(raw)

        // Arrow form: "Name → qty"
        if let arrowIdx = line.range(of: "→") {
            let namePart = String(line[line.startIndex..<arrowIdx.lowerBound])
            let rest = String(line[arrowIdx.upperBound...]).trimmingCharacters(in: .whitespaces)
            let name = cleanName(namePart)
            if !name.isEmpty, let qty = parseQuantityString(rest) {
                return ParsedExerciseResult(name: name, value: qty.value, unit: qty.unit)
            }
        }

        // Times form: "Name × qty" — name must start with a letter to rule out "3 × 10"
        if let xIdx = line.range(of: "×") {
            let namePart = String(line[line.startIndex..<xIdx.lowerBound]).trimmingCharacters(in: .whitespaces)
            let rest = String(line[xIdx.upperBound...]).trimmingCharacters(in: .whitespaces)
            guard namePart.first?.isLetter == true else { return nil }
            let name = cleanName(namePart)
            if !name.isEmpty, let qty = parseQuantityString(rest) {
                return ParsedExerciseResult(name: name, value: qty.value, unit: qty.unit)
            }
        }

        return nil
    }

    /// A line that is only a quantity, e.g. "3 × 10–12" or "2 × 10 each" — starts with a digit.
    private static func parseStandaloneQuantity(_ line: String) -> (value: Int, unit: String)? {
        let t = stripBullet(line)
        guard t.first?.isNumber == true else { return nil }
        return parseQuantityString(t)
    }

    /// Parse a quantity expression into (value, unit):
    ///   "3 × 10"       → (3, "sets")
    ///   "2–3 × 10"     → (2, "sets")  — lower bound of range
    ///   "4 × 6–8"      → (4, "sets")
    ///   "3 × 30 sec"   → (3, "sets")  — timed sets, N is still set count
    ///   "30 sec"       → (30, "seconds")
    ///   "1 min"        → (60, "seconds")
    ///   "20"           → (20, "sets")
    private static func parseQuantityString(_ text: String) -> (value: Int, unit: String)? {
        let t = text.trimmingCharacters(in: .whitespaces)
        guard let leading = leadingInt(t), leading > 0 else { return nil }

        // N × M [unit] — N is always set count regardless of what M is
        if t.range(of: #"^\d+(?:[–\-]\d+)?\s*[×xX]\s*\d+"#, options: .regularExpression) != nil {
            return (leading, "sets")
        }

        // N sec / N min (pure timed hold, no ×)
        if t.range(of: #"^\d+\s*(sec|min)"#, options: [.regularExpression, .caseInsensitive]) != nil {
            let isMin = t.lowercased().hasPrefix("\(leading) min") || t.lowercased().hasPrefix("\(leading)min")
            return (isMin ? leading * 60 : leading, "seconds")
        }

        // Bare integer — treat as sets
        if t.range(of: #"^\d+\s*$"#, options: .regularExpression) != nil {
            return (leading, "sets")
        }

        return nil
    }

    /// True for short section headings like "Strength", "Core", "Shoulder block".
    private static func isSectionLabel(_ line: String) -> Bool {
        let t = stripBullet(line).lowercased()
        guard t.split(separator: " ").count <= 5 else { return false }
        let labels = ["strength", "core", "shoulder", "mobility", "primer",
                      "lower", "upper", "optional", "add-on", "main", "lifts",
                      "block", "posture", "cardio", "warm-up", "cool-down"]
        return labels.contains(where: { t.contains($0) })
    }

    /// Returns a clean name if the line looks like an exercise name (not a set count or section label).
    private static func asExerciseName(_ raw: String) -> String? {
        let t = stripBullet(raw)
        guard t.first?.isLetter == true else { return nil }     // set counts start with digits
        guard !isSectionLabel(raw) else { return nil }
        let name = cleanName(t)
        return name.isEmpty ? nil : name
    }

    // MARK: - Day splitting

    private static func splitByDay(_ lines: [String]) -> [(String, [String])] {
        var result: [(String, [String])] = []
        var currentName = "All Exercises"
        var currentLines: [String] = []

        for line in lines {
            if line.lowercased().range(of: #"\bday\s+\d"#, options: .regularExpression) != nil {
                if !currentLines.allSatisfy({ $0.isEmpty }) {
                    result.append((currentName, currentLines))
                }
                currentName = line
                currentLines = []
            } else {
                currentLines.append(line)
            }
        }
        if !currentLines.allSatisfy({ $0.isEmpty }) {
            result.append((currentName, currentLines))
        }
        return result
    }

    // MARK: - String helpers

    private static func stripBullet(_ line: String) -> String {
        line.replacingOccurrences(of: #"^[•\-\*]\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"^\d+\.\s*"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }

    private static func cleanName(_ text: String) -> String {
        text
            .replacingOccurrences(of: #"\s*\([^)]*\)"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s*\([^)]*$"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }

    private static func leadingInt(_ text: String) -> Int? {
        guard let range = text.range(of: #"^\d+"#, options: .regularExpression) else { return nil }
        return Int(text[range])
    }
}
