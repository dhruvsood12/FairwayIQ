//
//  Round.swift
//  FairwayIQ
//

import Foundation
import SwiftData

@Model
final class Round {
    var id: UUID
    var course: Course?
    var courseNameSnapshot: String
    var teeBox: String
    var date: Date
    var weather: String?
    var playingPartners: String?
    var player: UserProfile?
    @Relationship(deleteRule: .cascade, inverse: \HoleScore.round)
    var holeScores: [HoleScore] = []
    @Relationship(deleteRule: .cascade, inverse: \Shot.round)
    var shots: [Shot] = []
    var createdAt: Date

    var courseName: String {
        course?.name ?? courseNameSnapshot
    }

    var totalStrokes: Int {
        holeScores.reduce(0) { $0 + $1.strokes }
    }

    var totalPutts: Int {
        holeScores.reduce(0) { $0 + $1.putts }
    }

    var fairwaysHit: Int {
        holeScores.compactMap(\.fairwayHit).count(where: { $0 })
    }

    var fairwaysPossible: Int {
        holeScores.count(where: { $0.fairwayHit != nil })
    }

    var girsHit: Int {
        holeScores.filter(\.gir).count
    }

    var totalPar: Int {
        if let course {
            return course.totalPar
        }
        // Fallback for legacy/demo rounds until migration is complete.
        let holes = holeScores.count
        return holes == 18 ? 72 : (holes == 9 ? 36 : holes * 4)
    }

    var scoreRelativeToPar: Int {
        totalStrokes - totalPar
    }

    init(
        id: UUID = UUID(),
        course: Course? = nil,
        courseNameSnapshot: String,
        teeBox: String = "Blue",
        date: Date = Date(),
        weather: String? = nil,
        playingPartners: String? = nil,
        player: UserProfile? = nil,
        holeScores: [HoleScore] = [],
        shots: [Shot] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.course = course
        self.courseNameSnapshot = courseNameSnapshot
        self.teeBox = teeBox
        self.date = date
        self.weather = weather
        self.playingPartners = playingPartners
        self.player = player
        self.holeScores = holeScores
        self.shots = shots
        self.createdAt = createdAt
    }
}
