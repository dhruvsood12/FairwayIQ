@testable import FairwayIQ
import Testing

@Suite("InputValidation Tests")
struct InputValidationTests {
    // MARK: - Strokes

    @Test("Valid strokes in range")
    func validStrokes() {
        #expect(InputValidation.validateStrokes(1).isValid)
        #expect(InputValidation.validateStrokes(4).isValid)
        #expect(InputValidation.validateStrokes(12).isValid)
        #expect(InputValidation.validateStrokes(20).isValid)
    }

    @Test("Strokes below minimum rejected")
    func strokesBelowMin() {
        let result = InputValidation.validateStrokes(0)
        #expect(!result.isValid)
        #expect(result.errorMessage != nil)
    }

    @Test("Strokes above maximum rejected")
    func strokesAboveMax() {
        let result = InputValidation.validateStrokes(21)
        #expect(!result.isValid)
    }

    // MARK: - Putts

    @Test("Valid putts in range")
    func validPutts() {
        #expect(InputValidation.validatePutts(0, maxStrokes: 5).isValid)
        #expect(InputValidation.validatePutts(2, maxStrokes: 5).isValid)
        #expect(InputValidation.validatePutts(5, maxStrokes: 5).isValid)
    }

    @Test("Putts cannot exceed strokes")
    func puttsExceedStrokes() {
        let result = InputValidation.validatePutts(6, maxStrokes: 5)
        #expect(!result.isValid)
    }

    @Test("Negative putts rejected")
    func negativePutts() {
        let result = InputValidation.validatePutts(-1, maxStrokes: 5)
        #expect(!result.isValid)
    }

    // MARK: - Penalties

    @Test("Valid penalties")
    func validPenalties() {
        #expect(InputValidation.validatePenalties(0).isValid)
        #expect(InputValidation.validatePenalties(3).isValid)
        #expect(InputValidation.validatePenalties(10).isValid)
    }

    @Test("Negative penalties rejected")
    func negativePenalties() {
        #expect(!InputValidation.validatePenalties(-1).isValid)
    }

    @Test("Penalties over max rejected")
    func penaltiesOverMax() {
        #expect(!InputValidation.validatePenalties(11).isValid)
    }

    // MARK: - Distance

    @Test("Nil distance is valid")
    func nilDistance() {
        #expect(InputValidation.validateDistance(nil).isValid)
    }

    @Test("Valid distance range")
    func validDistance() {
        #expect(InputValidation.validateDistance(1).isValid)
        #expect(InputValidation.validateDistance(250).isValid)
        #expect(InputValidation.validateDistance(600).isValid)
    }

    @Test("Zero distance rejected")
    func zeroDistance() {
        #expect(!InputValidation.validateDistance(0).isValid)
    }

    @Test("Excessive distance rejected")
    func excessiveDistance() {
        #expect(!InputValidation.validateDistance(601).isValid)
    }

    // MARK: - Handicap

    @Test("Valid handicap range")
    func validHandicap() {
        #expect(InputValidation.validateHandicap(0).isValid)
        #expect(InputValidation.validateHandicap(18.5).isValid)
        #expect(InputValidation.validateHandicap(54).isValid)
    }

    @Test("Negative handicap rejected")
    func negativeHandicap() {
        #expect(!InputValidation.validateHandicap(-1).isValid)
    }

    @Test("Handicap over max rejected")
    func handicapOverMax() {
        #expect(!InputValidation.validateHandicap(55).isValid)
    }

    // MARK: - Player Name

    @Test("Valid player name")
    func validName() {
        #expect(InputValidation.validatePlayerName("John").isValid)
        #expect(InputValidation.validatePlayerName("JD").isValid)
    }

    @Test("Empty name rejected")
    func emptyName() {
        #expect(!InputValidation.validatePlayerName("").isValid)
        #expect(!InputValidation.validatePlayerName("   ").isValid)
    }

    @Test("Single character name rejected")
    func singleCharName() {
        #expect(!InputValidation.validatePlayerName("A").isValid)
    }

    @Test("Overly long name rejected")
    func longName() {
        let name = String(repeating: "A", count: 51)
        #expect(!InputValidation.validatePlayerName(name).isValid)
    }

    // MARK: - Goal Target

    @Test("Valid goal targets")
    func validGoalTargets() {
        #expect(InputValidation.validateGoalTarget(90, metricType: .averageScore).isValid)
        #expect(InputValidation.validateGoalTarget(34, metricType: .puttsPerRound).isValid)
        #expect(InputValidation.validateGoalTarget(50, metricType: .girPercentage).isValid)
    }

    @Test("Goal target below minimum rejected")
    func goalTargetBelowMin() {
        #expect(!InputValidation.validateGoalTarget(49, metricType: .averageScore).isValid)
    }

    @Test("Goal target above maximum rejected")
    func goalTargetAboveMax() {
        #expect(!InputValidation.validateGoalTarget(151, metricType: .averageScore).isValid)
    }

    // MARK: - Coordinates

    @Test("Valid coordinates")
    func validCoordinates() {
        #expect(InputValidation.validateCoordinate(latitude: 37.0, longitude: -122.0).isValid)
        #expect(InputValidation.validateCoordinate(latitude: nil, longitude: nil).isValid)
    }

    @Test("Invalid latitude rejected")
    func invalidLatitude() {
        #expect(!InputValidation.validateCoordinate(latitude: 91, longitude: 0).isValid)
        #expect(!InputValidation.validateCoordinate(latitude: -91, longitude: 0).isValid)
    }

    @Test("Invalid longitude rejected")
    func invalidLongitude() {
        #expect(!InputValidation.validateCoordinate(latitude: 0, longitude: 181).isValid)
        #expect(!InputValidation.validateCoordinate(latitude: 0, longitude: -181).isValid)
    }

    // MARK: - Sanitization

    @Test("Numeric input sanitization")
    func sanitization() {
        #expect(InputValidation.sanitizeNumericInput("abc123def") == "123")
        #expect(InputValidation.sanitizeNumericInput("12.5") == "12.5")
        #expect(InputValidation.sanitizeNumericInput("-3") == "-3")
        #expect(InputValidation.sanitizeNumericInput("") == "")
    }

    @Test("Parse double from text")
    func parseDouble() {
        #expect(InputValidation.parseDouble("12.5") == 12.5)
        #expect(InputValidation.parseDouble("abc") == nil)
        #expect(InputValidation.parseDouble("") == nil)
        #expect(InputValidation.parseDouble("150") == 150.0)
    }

    @Test("Parse int from text")
    func parseInt() {
        #expect(InputValidation.parseInt("42") == 42)
        #expect(InputValidation.parseInt("abc") == nil)
        #expect(InputValidation.parseInt("") == nil)
        #expect(InputValidation.parseInt("12abc34") == 1234)
    }

    @Test("Clamp utility")
    func clamp() {
        #expect(InputValidation.clamp(5, min: 0, max: 10) == 5)
        #expect(InputValidation.clamp(-1, min: 0, max: 10) == 0)
        #expect(InputValidation.clamp(15, min: 0, max: 10) == 10)
    }
}
