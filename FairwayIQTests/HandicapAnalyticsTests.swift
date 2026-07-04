@testable import FairwayIQ
import Foundation
import Testing

@Suite("HandicapAnalytics Tests")
struct HandicapAnalyticsTests {
    private func parCourse() -> Course {
        Course(id: "test:whs", name: "Rated Course", holes: (1 ... 18).map { Hole(number: $0, par: 4) })
    }

    private func round(
        strokesPerHole: Int,
        holes: Int = 18,
        epoch: TimeInterval,
        course: Course?,
        rating: Double? = 72.0,
        slope: Int? = 113
    ) -> Round {
        let scores = (1 ... holes).map { HoleScore(holeNumber: $0, strokes: strokesPerHole, putts: 2) }
        return Round(
            course: course,
            courseNameSnapshot: "Rated Course",
            courseRating: rating,
            slopeRating: slope,
            date: Date(timeIntervalSince1970: epoch),
            holeScores: scores
        )
    }

    @Test("Differential requires rating, slope, 18 holes, and known pars")
    func differentialQualification() {
        let course = parCourse()
        #expect(HandicapAnalytics.differential(for: round(strokesPerHole: 5, epoch: 1, course: course, rating: nil)) == nil)
        #expect(HandicapAnalytics.differential(for: round(strokesPerHole: 5, epoch: 1, course: course, slope: nil)) == nil)
        #expect(HandicapAnalytics.differential(for: round(strokesPerHole: 5, holes: 9, epoch: 1, course: course)) == nil)
        #expect(HandicapAnalytics.differential(for: round(strokesPerHole: 5, epoch: 1, course: nil)) == nil)
    }

    @Test("Qualifying round produces the hand-computed differential")
    func differentialValue() {
        // 18 holes of 5 on a par-4 course: gross 90, the par plus five cap
        // does not bind, so (113 / 113) x (90 - 72.0) = 18.0.
        let value = HandicapAnalytics.differential(for: round(strokesPerHole: 5, epoch: 1, course: parCourse()))
        #expect(value == 18.0)
    }

    @Test("Blowup holes are capped before the differential")
    func differentialCapsBlowups() {
        // 17 holes of 4 plus one 12 on a par 4: the cap trims 12 to 9, so
        // the adjusted gross is 77 and the differential is 5.0.
        let course = parCourse()
        var scores = (1 ... 17).map { HoleScore(holeNumber: $0, strokes: 4, putts: 2) }
        scores.append(HoleScore(holeNumber: 18, strokes: 12, putts: 2))
        let blowup = Round(
            course: course,
            courseNameSnapshot: "Rated Course",
            courseRating: 72.0,
            slopeRating: 113,
            date: Date(timeIntervalSince1970: 2),
            holeScores: scores
        )
        #expect(HandicapAnalytics.differential(for: blowup) == 5.0)
    }

    @Test("Index is unavailable below three qualifying rounds")
    func indexLowData() {
        let course = parCourse()
        let rounds = [
            round(strokesPerHole: 5, epoch: 1, course: course),
            round(strokesPerHole: 5, epoch: 2, course: course),
            round(strokesPerHole: 5, epoch: 3, course: course, rating: nil)
        ]
        #expect(HandicapAnalytics.computedIndex(rounds: rounds) == nil)
        #expect(HandicapAnalytics.qualifyingRoundCount(rounds: rounds) == 2)
    }

    @Test("Three qualifying rounds produce lowest differential minus two")
    func indexAtThreeRounds() {
        let course = parCourse()
        let rounds = [
            round(strokesPerHole: 5, epoch: 1, course: course),
            round(strokesPerHole: 6, epoch: 2, course: course),
            round(strokesPerHole: 4, epoch: 3, course: course)
        ]
        // Differentials 18.0, 36.0, 0.0; three scores use the lowest minus 2.0.
        #expect(HandicapAnalytics.computedIndex(rounds: rounds) == -2.0)
    }

    @Test("Index trend emits a point per qualifying round once the minimum is met")
    func indexTrendPoints() {
        let course = parCourse()
        let rounds = [
            round(strokesPerHole: 5, epoch: 100, course: course),
            round(strokesPerHole: 6, epoch: 200, course: course),
            round(strokesPerHole: 4, epoch: 300, course: course),
            round(strokesPerHole: 5, epoch: 400, course: course)
        ]
        let trend = HandicapAnalytics.indexTrend(rounds: rounds)
        #expect(trend.count == 2)
        #expect(trend.map(\.date) == [Date(timeIntervalSince1970: 300), Date(timeIntervalSince1970: 400)])
        #expect(trend.first?.index == -2.0)
        #expect(trend.last?.index == HandicapAnalytics.computedIndex(rounds: rounds))
    }
}
