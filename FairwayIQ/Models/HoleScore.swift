//
//  HoleScore.swift
//  FairwayIQ
//

import Foundation
import SwiftData

@Model
final class HoleScore {
    var holeNumber: Int
    var strokes: Int
    var putts: Int
    var fairwayHit: Bool?
    var gir: Bool
    var penalties: Int
    var round: Round?

    init(
        holeNumber: Int,
        strokes: Int = 0,
        putts: Int = 0,
        fairwayHit: Bool? = nil,
        gir: Bool = false,
        penalties: Int = 0
    ) {
        self.holeNumber = holeNumber
        self.strokes = strokes
        self.putts = putts
        self.fairwayHit = fairwayHit
        self.gir = gir
        self.penalties = penalties
    }
}
