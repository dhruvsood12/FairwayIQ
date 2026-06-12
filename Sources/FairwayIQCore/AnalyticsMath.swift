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

    public init(
        averageScore: Double,
        fairwayPct: Double,
        girPct: Double,
        puttsPerRound: Double,
        penaltiesPerRound: Double
    ) {
        self.averageScore = averageScore
        self.fairwayPct = fairwayPct
        self.girPct = girPct
        self.puttsPerRound = puttsPerRound
        self.penaltiesPerRound = penaltiesPerRound
    }
}

public enum AnalyticsMath {
    public static func summary(rounds: [RoundRollup]) -> AnalyticsSummary {
        guard !rounds.isEmpty else {
            return AnalyticsSummary(averageScore: 0, fairwayPct: 0, girPct: 0, puttsPerRound: 0, penaltiesPerRound: 0)
        }

        let avg = Double(rounds.map(\.totalStrokes).reduce(0, +)) / Double(rounds.count)

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
            penaltiesPerRound: penaltiesPerRound
        )
    }

    public static func yDomain(scores: [Int]) -> ClosedRange<Double> {
        guard let minScore = scores.min(), let maxScore = scores.max() else { return 60 ... 100 }
        let pad = Swift.max(2, Int(Double(maxScore - minScore) * 0.15))
        return Double(minScore - pad) ... Double(maxScore + pad)
    }
}
