@testable import FairwayIQ
import Testing

@Suite("PerformanceInsights Tests")
struct PerformanceInsightsTests {
    private func makeRound(scores: [Int], putts: [Int]? = nil, penalties: [Int]? = nil) -> Round {
        let holeScores = scores.enumerated().map { idx, strokes in
            let p = putts?[idx] ?? 2
            let pen = penalties?[idx] ?? 0
            return HoleScore(
                holeNumber: idx + 1,
                strokes: strokes,
                putts: p,
                gir: strokes <= 4,
                penalties: pen
            )
        }
        let round = Round(courseNameSnapshot: "Test", holeScores: holeScores)
        for s in holeScores {
            s.round = round
        }
        return round
    }

    // MARK: - Baseline Comparison

    @Test("Baseline comparison detects improvement")
    func baselineDetectsImprovement() throws {
        let round = makeRound(scores: Array(repeating: 4, count: 18)) // 72
        let baselines = [makeRound(scores: Array(repeating: 5, count: 18))] // 90
        let result = PerformanceInsights.baselineComparison(for: round, against: baselines)
        #expect(result != nil)
        #expect(try #require(result?.isPositive))
    }

    @Test("Baseline comparison detects regression")
    func baselineDetectsRegression() throws {
        let round = makeRound(scores: Array(repeating: 6, count: 18)) // 108
        let baselines = [makeRound(scores: Array(repeating: 5, count: 18))] // 90
        let result = PerformanceInsights.baselineComparison(for: round, against: baselines)
        #expect(result != nil)
        #expect(try !(#require(result?.isPositive)))
    }

    @Test("Baseline returns nil for no baselines")
    func baselineNilForEmpty() {
        let round = makeRound(scores: Array(repeating: 4, count: 18))
        let result = PerformanceInsights.baselineComparison(for: round, against: [])
        #expect(result == nil)
    }

    @Test("Baseline returns nil for small delta")
    func baselineNilForSmallDelta() {
        let round = makeRound(scores: Array(repeating: 5, count: 18)) // 90
        let baselines = [makeRound(scores: Array(repeating: 5, count: 18))] // 90
        let result = PerformanceInsights.baselineComparison(for: round, against: baselines)
        #expect(result == nil) // delta < 1
    }

    // MARK: - Most Improved Metric

    @Test("Most improved metric with significant change")
    func mostImprovedSignificant() throws {
        let recent = [makeRound(scores: Array(repeating: 4, count: 18))]
        let previous = [makeRound(scores: Array(repeating: 5, count: 18))]
        let result = PerformanceInsights.mostImprovedMetric(recentRounds: recent, previousRounds: previous)
        #expect(result != nil)
        #expect(try #require(result?.isPositive))
    }

    @Test("Most improved returns nil for empty rounds")
    func mostImprovedNilEmpty() {
        let result = PerformanceInsights.mostImprovedMetric(recentRounds: [], previousRounds: [])
        #expect(result == nil)
    }

    // MARK: - Best and Worst Stretch

    @Test("Stretch insights found for 18 holes")
    func stretchInsights() {
        var scores = Array(repeating: 4, count: 18)
        scores[3] = 7; scores[4] = 8; scores[5] = 7 // bad stretch holes 4-6
        scores[10] = 3; scores[11] = 3; scores[12] = 3 // good stretch holes 11-13
        let round = makeRound(scores: scores)
        let (best, worst) = PerformanceInsights.bestAndWorstStretch(for: round)
        #expect(best != nil)
        #expect(worst != nil)
    }

    @Test("Stretch returns nil for too few holes")
    func stretchNilForFewHoles() {
        let round = makeRound(scores: [4, 5])
        let (best, worst) = PerformanceInsights.bestAndWorstStretch(for: round)
        #expect(best == nil)
        #expect(worst == nil)
    }

    // MARK: - Hole Type Insights

    @Test("Best hole type computed")
    func bestHoleType() {
        let rounds = [makeRound(scores: Array(repeating: 4, count: 18))]
        let result = PerformanceInsights.bestScoringHoleType(rounds: rounds)
        #expect(result != nil)
    }

    @Test("Hole type returns nil for empty rounds")
    func holeTypeNilEmpty() {
        let result = PerformanceInsights.bestScoringHoleType(rounds: [])
        #expect(result == nil)
    }

    // MARK: - Costliest Mistake

    @Test("Costliest mistake found")
    func costliestMistake() {
        let putts = Array(repeating: 3, count: 18)
        let round = makeRound(scores: Array(repeating: 6, count: 18), putts: putts)
        let result = PerformanceInsights.costliestMistakeCategory(for: round)
        #expect(result != nil)
    }

    @Test("Costliest mistake nil for perfect round")
    func costliestMistakeNilPerfect() {
        let round = makeRound(scores: Array(repeating: 0, count: 0))
        let result = PerformanceInsights.costliestMistakeCategory(for: round)
        #expect(result == nil)
    }
}
