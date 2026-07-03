import Foundation

public struct RoundRollup: Hashable {
    public var totalStrokes: Int
    public var fairwaysHit: Int
    public var fairwaysPossible: Int
    public var girsHit: Int
    public var holesPlayed: Int
    public var totalPutts: Int
    public var totalPenalties: Int

    public init(
        totalStrokes: Int,
        fairwaysHit: Int,
        fairwaysPossible: Int,
        girsHit: Int,
        holesPlayed: Int,
        totalPutts: Int,
        totalPenalties: Int
    ) {
        self.totalStrokes = totalStrokes
        self.fairwaysHit = fairwaysHit
        self.fairwaysPossible = fairwaysPossible
        self.girsHit = girsHit
        self.holesPlayed = holesPlayed
        self.totalPutts = totalPutts
        self.totalPenalties = totalPenalties
    }
}

public struct AnalyticsSummary: Hashable {
    public let averageScore: Double
    public let fairwayPct: Double
    public let girPct: Double
    public let puttsPerRound: Double
    public let penaltiesPerRound: Double
    public let bestRoundScore: Int?
    public let worstRoundScore: Int?

    public init(
        averageScore: Double,
        fairwayPct: Double,
        girPct: Double,
        puttsPerRound: Double,
        penaltiesPerRound: Double,
        bestRoundScore: Int?,
        worstRoundScore: Int?
    ) {
        self.averageScore = averageScore
        self.fairwayPct = fairwayPct
        self.girPct = girPct
        self.puttsPerRound = puttsPerRound
        self.penaltiesPerRound = penaltiesPerRound
        self.bestRoundScore = bestRoundScore
        self.worstRoundScore = worstRoundScore
    }
}

public struct HoleLine: Hashable {
    public let number: Int
    public let strokes: Int

    public init(number: Int, strokes: Int) {
        self.number = number
        self.strokes = strokes
    }
}

public struct RoundSnapshot: Hashable {
    public let date: Date
    public let courseName: String
    public let rollup: RoundRollup
    public let holeLines: [HoleLine]

    public init(date: Date, courseName: String, rollup: RoundRollup, holeLines: [HoleLine]) {
        self.date = date
        self.courseName = courseName
        self.rollup = rollup
        self.holeLines = holeLines
    }
}

public struct ScoreTrendPoint: Identifiable, Hashable {
    public var id: Date {
        date
    }

    public let date: Date
    public let score: Int

    public init(date: Date, score: Int) {
        self.date = date
        self.score = score
    }
}

public struct SplitSummary: Hashable {
    public let frontNineAverage: Double
    public let backNineAverage: Double

    public init(frontNineAverage: Double, backNineAverage: Double) {
        self.frontNineAverage = frontNineAverage
        self.backNineAverage = backNineAverage
    }
}

public struct CoursePerformance: Identifiable, Hashable {
    public var id: String {
        courseName
    }

    public let courseName: String
    public let roundsPlayed: Int
    public let averageScore: Double

    public init(courseName: String, roundsPlayed: Int, averageScore: Double) {
        self.courseName = courseName
        self.roundsPlayed = roundsPlayed
        self.averageScore = averageScore
    }
}

public enum AnalyticsMath {
    public static func summary(rounds: [RoundRollup]) -> AnalyticsSummary {
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
        let avg = Double(totalScores.reduce(0, +)) / Double(rounds.count)

        let fairwaysPossible = rounds.map(\.fairwaysPossible).reduce(0, +)
        let fairwaysHit = rounds.map(\.fairwaysHit).reduce(0, +)
        let fairwayPct = fairwaysPossible > 0 ? (Double(fairwaysHit) / Double(fairwaysPossible) * 100) : 0

        let holesPlayed = rounds.map(\.holesPlayed).reduce(0, +)
        let girsHit = rounds.map(\.girsHit).reduce(0, +)
        let girPct = holesPlayed > 0 ? (Double(girsHit) / Double(holesPlayed) * 100) : 0

        let puttsPerRound = Double(rounds.map(\.totalPutts).reduce(0, +)) / Double(rounds.count)
        let penaltiesPerRound = Double(rounds.map(\.totalPenalties).reduce(0, +)) / Double(rounds.count)

        return AnalyticsSummary(
            averageScore: avg,
            fairwayPct: fairwayPct,
            girPct: girPct,
            puttsPerRound: puttsPerRound,
            penaltiesPerRound: penaltiesPerRound,
            bestRoundScore: totalScores.min(),
            worstRoundScore: totalScores.max()
        )
    }

    public static func scoreTrend(rounds: [RoundSnapshot]) -> [ScoreTrendPoint] {
        rounds
            .sorted(by: { $0.date < $1.date })
            .map { ScoreTrendPoint(date: $0.date, score: $0.rollup.totalStrokes) }
    }

    public static func frontBackSplit(rounds: [RoundSnapshot]) -> SplitSummary {
        var frontTotals: [Int] = []
        var backTotals: [Int] = []

        for round in rounds {
            let front = round.holeLines.filter { $0.number <= 9 }.reduce(0) { $0 + $1.strokes }
            let back = round.holeLines.filter { $0.number > 9 }.reduce(0) { $0 + $1.strokes }
            if front > 0 { frontTotals.append(front) }
            if back > 0 { backTotals.append(back) }
        }

        let frontAvg = frontTotals.isEmpty ? 0 : Double(frontTotals.reduce(0, +)) / Double(frontTotals.count)
        let backAvg = backTotals.isEmpty ? 0 : Double(backTotals.reduce(0, +)) / Double(backTotals.count)
        return SplitSummary(frontNineAverage: frontAvg, backNineAverage: backAvg)
    }

    public static func coursePerformance(rounds: [RoundSnapshot]) -> [CoursePerformance] {
        let grouped = Dictionary(grouping: rounds, by: \.courseName)
        return grouped.map { key, rounds in
            let avg = Double(rounds.map(\.rollup.totalStrokes).reduce(0, +)) / Double(rounds.count)
            return CoursePerformance(courseName: key, roundsPlayed: rounds.count, averageScore: avg)
        }
        .sorted { lhs, rhs in
            if lhs.roundsPlayed == rhs.roundsPlayed {
                if lhs.averageScore == rhs.averageScore {
                    return lhs.courseName < rhs.courseName
                }
                return lhs.averageScore < rhs.averageScore
            }
            return lhs.roundsPlayed > rhs.roundsPlayed
        }
    }

    public static func yDomain(scores: [Int]) -> ClosedRange<Double> {
        guard let minScore = scores.min(), let maxScore = scores.max() else { return 60 ... 100 }
        let pad = Swift.max(2, Int(Double(maxScore - minScore) * 0.15))
        return Double(minScore - pad) ... Double(maxScore + pad)
    }
}
