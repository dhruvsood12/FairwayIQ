import FairwayIQCore
import Foundation

struct HandicapIndexPoint: Identifiable, Hashable {
    var id: Date {
        date
    }

    let date: Date
    let index: Double
}

enum HandicapAnalytics {
    static let minimumQualifyingRounds = 3

    /// A round produces a score differential only when nothing about it has
    /// to be invented: a user-entered course rating and slope, exactly 18
    /// scored holes, and a known par for every hole. The adjusted gross
    /// score uses the par plus five cap of Rule 3.1a because per-hole stroke
    /// indexes are not in the data model yet; MODEL.md records the decision.
    static func differential(for round: Round) -> Double? {
        guard
            let rating = round.courseRating,
            let slope = round.slopeRating,
            round.holeScores.count == 18
        else {
            return nil
        }

        var holes: [HoleScoreInput] = []
        for score in round.holeScores {
            guard let par = round.par(forHole: score.holeNumber) else { return nil }
            holes.append(HoleScoreInput(strokes: score.strokes, par: par, strokesReceived: 0))
        }

        guard let adjusted = HandicapMath.adjustedGrossScore(holes: holes, hasEstablishedIndex: false) else {
            return nil
        }
        return HandicapMath.scoreDifferential(
            adjustedGrossScore: adjusted,
            courseRating: rating,
            slopeRating: slope
        )
    }

    static func qualifyingRoundCount(rounds: [Round]) -> Int {
        rounds.count(where: { differential(for: $0) != nil })
    }

    static func computedIndex(rounds: [Round]) -> Double? {
        let latestFirst = rounds
            .sorted(by: { $0.date > $1.date })
            .compactMap(differential(for:))
        return HandicapMath.handicapIndex(latestFirstDifferentials: latestFirst)
    }

    static func indexTrend(rounds: [Round]) -> [HandicapIndexPoint] {
        let chronological = rounds.sorted(by: { $0.date < $1.date })
        var differentialsOldestFirst: [Double] = []
        var points: [HandicapIndexPoint] = []

        for round in chronological {
            guard let differential = differential(for: round) else { continue }
            differentialsOldestFirst.append(differential)
            let latestFirst = Array(differentialsOldestFirst.reversed())
            if let index = HandicapMath.handicapIndex(latestFirstDifferentials: latestFirst) {
                points.append(HandicapIndexPoint(date: round.date, index: index))
            }
        }
        return points
    }
}
