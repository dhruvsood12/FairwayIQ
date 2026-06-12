import Foundation

enum InputValidation {

    struct ValidationResult {
        let isValid: Bool
        let errorMessage: String?

        static let valid = ValidationResult(isValid: true, errorMessage: nil)
        static func invalid(_ message: String) -> ValidationResult {
            ValidationResult(isValid: false, errorMessage: message)
        }
    }

    // MARK: - Score Validation

    static func validateStrokes(_ value: Int) -> ValidationResult {
        guard value >= 1 else { return .invalid("Strokes must be at least 1.") }
        guard value <= 20 else { return .invalid("Strokes cannot exceed 20.") }
        return .valid
    }

    static func validatePutts(_ value: Int, maxStrokes: Int) -> ValidationResult {
        guard value >= 0 else { return .invalid("Putts cannot be negative.") }
        guard value <= maxStrokes else { return .invalid("Putts cannot exceed total strokes.") }
        guard value <= 10 else { return .invalid("Putts cannot exceed 10.") }
        return .valid
    }

    static func validatePenalties(_ value: Int) -> ValidationResult {
        guard value >= 0 else { return .invalid("Penalties cannot be negative.") }
        guard value <= 10 else { return .invalid("Penalties cannot exceed 10.") }
        return .valid
    }

    // MARK: - Distance Validation

    static func validateDistance(_ value: Double?) -> ValidationResult {
        guard let value else { return .valid }
        guard value > 0 else { return .invalid("Distance must be greater than 0.") }
        guard value <= 600 else { return .invalid("Distance exceeds maximum (600 yards).") }
        return .valid
    }

    static func validateYardage(_ value: Int?) -> ValidationResult {
        guard let value else { return .valid }
        guard value >= 50 else { return .invalid("Yardage must be at least 50.") }
        guard value <= 700 else { return .invalid("Yardage cannot exceed 700.") }
        return .valid
    }

    // MARK: - Profile Validation

    static func validateHandicap(_ value: Double) -> ValidationResult {
        guard value >= 0 else { return .invalid("Handicap cannot be negative.") }
        guard value <= 54 else { return .invalid("Handicap cannot exceed 54.") }
        return .valid
    }

    static func validatePlayerName(_ value: String) -> ValidationResult {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .invalid("Name cannot be empty.") }
        guard trimmed.count <= 50 else { return .invalid("Name is too long (max 50 characters).") }
        guard trimmed.count >= 2 else { return .invalid("Name must be at least 2 characters.") }
        return .valid
    }

    // MARK: - Goal Validation

    static func validateGoalTarget(_ value: Double, metricType: GoalMetricType) -> ValidationResult {
        guard value >= metricType.minValue else {
            return .invalid("Target must be at least \(Int(metricType.minValue)) \(metricType.unit).")
        }
        guard value <= metricType.maxValue else {
            return .invalid("Target cannot exceed \(Int(metricType.maxValue)) \(metricType.unit).")
        }
        return .valid
    }

    // MARK: - Coordinate Validation

    static func validateCoordinate(latitude: Double?, longitude: Double?) -> ValidationResult {
        if let lat = latitude {
            guard lat >= -90 && lat <= 90 else { return .invalid("Invalid latitude.") }
        }
        if let lon = longitude {
            guard lon >= -180 && lon <= 180 else { return .invalid("Invalid longitude.") }
        }
        return .valid
    }

    // MARK: - Sanitization

    static func sanitizeNumericInput(_ text: String) -> String {
        text.filter { $0.isNumber || $0 == "." || $0 == "-" }
    }

    static func parseDouble(_ text: String) -> Double? {
        let cleaned = sanitizeNumericInput(text)
        guard !cleaned.isEmpty else { return nil }
        return Double(cleaned)
    }

    static func parseInt(_ text: String) -> Int? {
        let cleaned = text.filter(\.isNumber)
        guard !cleaned.isEmpty else { return nil }
        return Int(cleaned)
    }

    static func clamp<T: Comparable>(_ value: T, min: T, max: T) -> T {
        Swift.min(Swift.max(value, min), max)
    }
}
