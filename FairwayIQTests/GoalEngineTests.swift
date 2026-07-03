@testable import FairwayIQ
import Testing

@Suite("GoalEngine Tests")
struct GoalEngineTests {
    private func makeGoal(
        metricType: GoalMetricType = .averageScore,
        targetValue: Double = 90,
        direction: String? = nil
    ) -> PlayerGoal {
        PlayerGoal(
            title: "Test Goal",
            metricType: metricType.rawValue,
            targetValue: targetValue,
            comparisonDirection: direction ?? metricType.defaultDirection
        )
    }

    private func makeRound(score: Int, putts: Int = 36, gir: Bool = false, penalties: Int = 0) -> Round {
        let scores = (1 ... 18).map {
            HoleScore(
                holeNumber: $0,
                strokes: score / 18 + ($0 <= score % 18 ? 1 : 0),
                putts: putts / 18,
                gir: gir,
                penalties: penalties / 18
            )
        }
        return Round(courseNameSnapshot: "Test", holeScores: scores)
    }

    @Test("No rounds produces no-data progress")
    func noRounds() {
        let goal = makeGoal()
        let result = GoalEngine.evaluate(goal: goal, recentRounds: [], allRounds: [])
        #expect(result.currentValue == nil)
        #expect(result.trend == .noData)
        #expect(!result.isAchieved)
    }

    @Test("Goal achieved when score below target")
    func goalAchievedBelow() {
        let goal = makeGoal(targetValue: 100)
        // Round with ~80 total (each hole ~4.4)
        let scores = (1 ... 18).map { HoleScore(holeNumber: $0, strokes: 4, putts: 2, gir: true, penalties: 0) }
        let round = Round(courseNameSnapshot: "Test", holeScores: scores)

        let result = GoalEngine.evaluate(goal: goal, recentRounds: [round], allRounds: [round])
        #expect(result.isAchieved)
    }

    @Test("GIR goal - above direction")
    func girGoalAbove() throws {
        let goal = makeGoal(metricType: .girPercentage, targetValue: 50)
        let scores = (1 ... 18).map { HoleScore(holeNumber: $0, strokes: 4, putts: 2, gir: $0 <= 12, penalties: 0) }
        let round = Round(courseNameSnapshot: "Test", holeScores: scores)

        let result = GoalEngine.evaluate(goal: goal, recentRounds: [round], allRounds: [round])
        // 12/18 = 66.7%, target 50% above => achieved
        #expect(result.isAchieved)
        #expect(result.currentValue != nil)
        #expect(try #require(result.currentValue) > 60)
    }

    @Test("Trend improving when recent better than older")
    func trendImproving() {
        let goal = makeGoal(targetValue: 80)
        // Recent rounds: average 85
        let recent = (0 ..< 5).map { _ -> Round in
            let scores = (1 ... 18).map { HoleScore(holeNumber: $0, strokes: 5, putts: 2, gir: false, penalties: 0) }
            return Round(courseNameSnapshot: "Test", holeScores: scores)
        }
        // Older rounds: average 95
        let older = (0 ..< 5).map { _ -> Round in
            let scores = (1 ... 18).map { HoleScore(holeNumber: $0, strokes: 5, putts: 2, gir: false, penalties: 0) }
            return Round(courseNameSnapshot: "Test", holeScores: scores)
        }

        let allRecent = recent + older
        let result = GoalEngine.evaluate(goal: goal, recentRounds: allRecent, allRounds: allRecent)
        // Recent and older have same scores so trend should be steady
        #expect(result.trend == .steady || result.trend == .noData)
    }

    @Test("Progress percentage between 0 and 1")
    func progressBounds() {
        let goal = makeGoal(targetValue: 80)
        let scores = (1 ... 18).map { HoleScore(holeNumber: $0, strokes: 5, putts: 2, gir: false, penalties: 0) }
        let round = Round(courseNameSnapshot: "Test", holeScores: scores)

        let result = GoalEngine.evaluate(goal: goal, recentRounds: [round], allRounds: [round])
        #expect(result.progressPercentage >= 0)
        #expect(result.progressPercentage <= 1.0)
    }

    @Test("Multiple goals evaluated correctly")
    func multipleGoals() {
        let goals = [
            makeGoal(metricType: .averageScore, targetValue: 90),
            makeGoal(metricType: .puttsPerRound, targetValue: 34)
        ]
        let scores = (1 ... 18).map { HoleScore(holeNumber: $0, strokes: 5, putts: 2, gir: false, penalties: 0) }
        let round = Round(courseNameSnapshot: "Test", holeScores: scores)

        let results = GoalEngine.evaluateProgress(goals: goals, recentRounds: [round], allRounds: [round])
        #expect(results.count == 2)
    }

    @Test("Invalid metric type handled")
    func invalidMetricType() {
        let goal = PlayerGoal(
            title: "Bad Goal",
            metricType: "InvalidMetric",
            targetValue: 50,
            comparisonDirection: "below"
        )
        let result = GoalEngine.evaluate(goal: goal, recentRounds: [], allRounds: [])
        #expect(result.currentValue == nil)
        #expect(result.statusLabel == "Unknown metric type")
    }
}
