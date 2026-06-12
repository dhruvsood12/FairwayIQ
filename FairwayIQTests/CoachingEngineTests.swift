import Testing
@testable import FairwayIQ

@Suite("CoachingEngine Tests")
struct CoachingEngineTests {

    @Test("Empty round produces minimal summary")
    func emptyRound() {
        let round = Round(courseNameSnapshot: "Test", holeScores: [])
        let result = CoachingEngine.analyze(round: round, baseline: nil)
        #expect(result.strengths.isEmpty)
        #expect(result.weaknesses.isEmpty)
        #expect(!result.overallAssessment.isEmpty)
    }

    @Test("Three-putts detected as weakness")
    func threePuttsWeakness() {
        let scores = (1...18).map { HoleScore(holeNumber: $0, strokes: 5, putts: 3, gir: false, penalties: 0) }
        let round = Round(courseNameSnapshot: "Test", holeScores: scores)
        for s in scores { s.round = round }
        let result = CoachingEngine.analyze(round: round, baseline: nil)
        let puttingWeakness = result.weaknesses.first(where: { $0.title.contains("3-putt") })
        #expect(puttingWeakness != nil)
    }

    @Test("Zero three-putts is a strength")
    func noThreePutts() {
        let scores = (1...18).map { HoleScore(holeNumber: $0, strokes: 4, putts: 2, gir: true, penalties: 0) }
        let round = Round(courseNameSnapshot: "Test", holeScores: scores)
        for s in scores { s.round = round }
        let result = CoachingEngine.analyze(round: round, baseline: nil)
        let cleanPutting = result.strengths.first(where: { $0.title.contains("Clean putting") })
        #expect(cleanPutting != nil)
    }

    @Test("Penalties detected as weakness")
    func penaltiesWeakness() {
        let scores = (1...18).map { HoleScore(holeNumber: $0, strokes: 6, putts: 2, gir: false, penalties: 1) }
        let round = Round(courseNameSnapshot: "Test", holeScores: scores)
        for s in scores { s.round = round }
        let result = CoachingEngine.analyze(round: round, baseline: nil)
        let penaltyWeakness = result.weaknesses.first(where: { $0.title.contains("Penalties") })
        #expect(penaltyWeakness != nil)
        let penaltyCost = result.strokeCostBreakdown.first(where: { $0.category == "Penalties" })
        #expect(penaltyCost != nil)
    }

    @Test("Zero penalties is a strength")
    func noPenaltiesStrength() {
        let scores = (1...18).map { HoleScore(holeNumber: $0, strokes: 4, putts: 2, gir: true, penalties: 0) }
        let round = Round(courseNameSnapshot: "Test", holeScores: scores)
        for s in scores { s.round = round }
        let result = CoachingEngine.analyze(round: round, baseline: nil)
        let cleanCard = result.strengths.first(where: { $0.title.contains("Clean card") })
        #expect(cleanCard != nil)
    }

    @Test("One-putts recognized as strength")
    func onePuttsStrength() {
        let scores = (1...18).map { HoleScore(holeNumber: $0, strokes: 4, putts: $0 <= 6 ? 1 : 2, gir: true, penalties: 0) }
        let round = Round(courseNameSnapshot: "Test", holeScores: scores)
        for s in scores { s.round = round }
        let result = CoachingEngine.analyze(round: round, baseline: nil)
        let shortGame = result.strengths.first(where: { $0.title.contains("Short game") })
        #expect(shortGame != nil)
    }

    @Test("Baseline comparison works")
    func baselineComparison() {
        let baseline = RoundBaseline(
            averageScore: 85,
            averagePutts: 32,
            averageGIR: 40,
            averageFairwayPct: 50,
            averagePenalties: 2,
            roundCount: 5
        )
        let scores = (1...18).map { HoleScore(holeNumber: $0, strokes: 4, putts: 2, gir: true, penalties: 0) }
        let round = Round(courseNameSnapshot: "Test", holeScores: scores)
        for s in scores { s.round = round }
        let result = CoachingEngine.analyze(round: round, baseline: baseline)
        // Score 72 is better than baseline 85
        let betterThanAvg = result.strengths.first(where: { $0.title.contains("Better than") })
        #expect(betterThanAvg != nil)
    }

    @Test("Compute baseline from rounds")
    func computeBaseline() {
        let scores1 = (1...18).map { HoleScore(holeNumber: $0, strokes: 5, putts: 2, gir: $0 % 3 == 0, penalties: 0) }
        let round1 = Round(courseNameSnapshot: "Test", holeScores: scores1)
        for s in scores1 { s.round = round1 }

        let scores2 = (1...18).map { HoleScore(holeNumber: $0, strokes: 4, putts: 2, gir: $0 % 2 == 0, penalties: 1) }
        let round2 = Round(courseNameSnapshot: "Test", holeScores: scores2)
        for s in scores2 { s.round = round2 }

        let baseline = CoachingEngine.computeBaseline(from: [round1, round2])
        #expect(baseline != nil)
        #expect(baseline!.averageScore == 81.0) // (90 + 72) / 2
        #expect(baseline!.roundCount == 2)
    }

    @Test("Assessment text varies by score")
    func assessmentText() {
        // Under par
        let goodScores = (1...18).map { HoleScore(holeNumber: $0, strokes: 3, putts: 1, gir: true, penalties: 0) }
        let goodRound = Round(courseNameSnapshot: "Test", holeScores: goodScores)
        for s in goodScores { s.round = goodRound }
        let goodResult = CoachingEngine.analyze(round: goodRound, baseline: nil)
        #expect(goodResult.overallAssessment.contains("Outstanding") || goodResult.overallAssessment.contains("under par"))

        // Way over par
        let badScores = (1...18).map { HoleScore(holeNumber: $0, strokes: 7, putts: 3, gir: false, penalties: 1) }
        let badRound = Round(courseNameSnapshot: "Test", holeScores: badScores)
        for s in badScores { s.round = badRound }
        let badResult = CoachingEngine.analyze(round: badRound, baseline: nil)
        #expect(badResult.overallAssessment.contains("challenging"))
    }

    @Test("Action items capped at 5")
    func actionItemsCapped() {
        // Create a round with many issues
        let scores = (1...18).map {
            HoleScore(holeNumber: $0, strokes: 8, putts: 4, fairwayHit: false, gir: false, penalties: 2)
        }
        let round = Round(courseNameSnapshot: "Test", holeScores: scores)
        for s in scores { s.round = round }
        let result = CoachingEngine.analyze(round: round, baseline: nil)
        #expect(result.actionItems.count <= 5)
        #expect(result.strengths.count <= 5)
        #expect(result.weaknesses.count <= 5)
    }
}
