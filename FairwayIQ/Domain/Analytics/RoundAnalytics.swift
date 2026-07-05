import FairwayIQCore
import Foundation

extension Round {
    var rollup: RoundRollup {
        RoundRollup(
            totalStrokes: totalStrokes,
            fairwaysHit: fairwaysHit,
            fairwaysPossible: fairwaysPossible,
            girsHit: girsHit,
            holesPlayed: holeScores.count,
            totalPutts: totalPutts,
            totalPenalties: holeScores.reduce(0) { $0 + $1.penalties }
        )
    }

    var snapshot: RoundSnapshot {
        RoundSnapshot(
            date: date,
            courseName: courseName,
            rollup: rollup,
            holeLines: holeScores.map { HoleLine(number: $0.holeNumber, strokes: $0.strokes) }
        )
    }
}
