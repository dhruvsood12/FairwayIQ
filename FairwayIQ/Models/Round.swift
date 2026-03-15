//
//  Round.swift
//  FairwayIQ
//

import Foundation
import SwiftData

@Model
final class Round {
    var id: UUID
    var courseId: String
    var courseName: String
    var teeBox: String
    var date: Date
    var weather: String?
    var playingPartners: String?
    @Relationship(deleteRule: .cascade, inverse: \HoleScore.round)
    var holeScores: [HoleScore] = []
    @Relationship(deleteRule: .cascade, inverse: \Shot.round)
    var shots: [Shot] = []
    var createdAt: Date

    var totalStrokes: Int {
        holeScores.reduce(0) { $0 + $1.strokes }
    }

    var totalPutts: Int {
        holeScores.reduce(0) { $0 + $1.putts }
    }

    var fairwaysHit: Int {
        holeScores.compactMap(\.fairwayHit).filter { $0 }.count
    }

    var fairwaysPossible: Int {
        holeScores.filter { $0.fairwayHit != nil }.count
    }

    var girsHit: Int {
        holeScores.filter(\.gir).count
    }

    var totalPar: Int {
        let holes = holeScores.count
        return holes == 18 ? 72 : (holes == 9 ? 36 : holes * 4)
    }

    var scoreRelativeToPar: Int {
        totalStrokes - totalPar
    }

    init(
        id: UUID = UUID(),
        courseId: String,
        courseName: String,
        teeBox: String = "Blue",
        date: Date = Date(),
        weather: String? = nil,
        playingPartners: String? = nil,
        holeScores: [HoleScore] = [],
        shots: [Shot] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.courseId = courseId
        self.courseName = courseName
        self.teeBox = teeBox
        self.date = date
        self.weather = weather
        self.playingPartners = playingPartners
        self.holeScores = holeScores
        self.shots = shots
        self.createdAt = createdAt
    }
}
