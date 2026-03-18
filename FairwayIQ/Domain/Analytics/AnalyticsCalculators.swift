import Foundation

struct ScoreTrendPoint: Identifiable, Hashable {
    var id: Date { date }
    let date: Date
    let score: Int
}

struct HandicapTrendPoint: Identifiable, Hashable {
    var id: Date { date }
    let date: Date
    let index: Double
}

struct AnalyticsSummary: Hashable {
    let averageScore: Double
    let fairwayPct: Double
    let girPct: Double
    let puttsPerRound: Double
    let penaltiesPerRound: Double
    let bestRoundScore: Int?
    let worstRoundScore: Int?
}

struct SplitSummary: Hashable {
    let frontNineAverage: Double
    let backNineAverage: Double
}

struct CoursePerformance: Identifiable, Hashable {
    var id: String { courseName }
    let courseName: String
    let roundsPlayed: Int
    let averageScore: Double
}

enum AnalyticsCalculators {
    static func scoreTrend(rounds: [Round]) -> [ScoreTrendPoint] {
        rounds
            .sorted(by: { $0.date < $1.date })
            .map { ScoreTrendPoint(date: $0.date, score: $0.totalStrokes) }
    }

    /// MVP-safe estimate: use the profile's saved estimate, but show it over time without fabricated “improvement”.
    static func indexTrend(rounds: [Round], profileIndexEstimate: Double?) -> [HandicapTrendPoint] {
        let estimate = profileIndexEstimate ?? 18
        return rounds
            .sorted(by: { $0.date < $1.date })
            .map { HandicapTrendPoint(date: $0.date, index: estimate) }
    }

    static func summary(rounds: [Round]) -> AnalyticsSummary {
        guard !rounds.isEmpty else {
            return AnalyticsSummary(
                averageScore: 0,
                fairwayPct: 0,
                girPct: 0,
                puttsPerRound: 0,
                penaltiesPerRound: 0,
                bestRoundScore: nil,
                worstRoundScore: nil
            )
        }

        let totalScores = rounds.map(\.totalStrokes)
        let averageScore = Double(totalScores.reduce(0, +)) / Double(totalScores.count)

        let fairwayTotal = rounds.reduce(0) { $0 + $1.fairwaysPossible }
        let fairwayHit = rounds.reduce(0) { $0 + $1.fairwaysHit }
        let fairwayPct = fairwayTotal > 0 ? (Double(fairwayHit) / Double(fairwayTotal) * 100) : 0

        let girTotal = rounds.reduce(0) { $0 + max(0, $1.holeScores.count) }
        let girHit = rounds.reduce(0) { $0 + $1.girsHit }
        let girPct = girTotal > 0 ? (Double(girHit) / Double(girTotal) * 100) : 0

        let puttsPerRound = Double(rounds.reduce(0) { $0 + $1.totalPutts }) / Double(rounds.count)
        let penaltiesPerRound = Double(rounds.reduce(0) { $0 + $1.holeScores.reduce(0) { $0 + $1.penalties } }) / Double(rounds.count)

        return AnalyticsSummary(
            averageScore: averageScore,
            fairwayPct: fairwayPct,
            girPct: girPct,
            puttsPerRound: puttsPerRound,
            penaltiesPerRound: penaltiesPerRound,
            bestRoundScore: totalScores.min(),
            worstRoundScore: totalScores.max()
        )
    }

    static func yDomain(for scores: [Int]) -> ClosedRange<Double> {
        guard let minScore = scores.min(), let maxScore = scores.max() else { return 60...100 }
        let pad = Swift.max(2, Int(Double(maxScore - minScore) * 0.15))
        return Double(minScore - pad)...Double(maxScore + pad)
    }

    static func frontBackSplit(rounds: [Round]) -> SplitSummary {
        var frontTotals: [Int] = []
        var backTotals: [Int] = []

        for round in rounds {
            let sorted = round.holeScores.sorted { $0.holeNumber < $1.holeNumber }
            let front = sorted.filter { $0.holeNumber <= 9 }.reduce(0) { $0 + $1.strokes }
            let back = sorted.filter { $0.holeNumber > 9 }.reduce(0) { $0 + $1.strokes }
            if front > 0 { frontTotals.append(front) }
            if back > 0 { backTotals.append(back) }
        }

        let frontAvg = frontTotals.isEmpty ? 0 : Double(frontTotals.reduce(0, +)) / Double(frontTotals.count)
        let backAvg = backTotals.isEmpty ? 0 : Double(backTotals.reduce(0, +)) / Double(backTotals.count)
        return SplitSummary(frontNineAverage: frontAvg, backNineAverage: backAvg)
    }

    static func coursePerformance(rounds: [Round]) -> [CoursePerformance] {
        let grouped = Dictionary(grouping: rounds, by: \.courseName)
        return grouped.map { key, rounds in
            let avg = Double(rounds.map(\.totalStrokes).reduce(0, +)) / Double(rounds.count)
            return CoursePerformance(courseName: key, roundsPlayed: rounds.count, averageScore: avg)
        }
        .sorted { lhs, rhs in
            if lhs.roundsPlayed == rhs.roundsPlayed {
                return lhs.averageScore < rhs.averageScore
            }
            return lhs.roundsPlayed > rhs.roundsPlayed
        }
    }
}

