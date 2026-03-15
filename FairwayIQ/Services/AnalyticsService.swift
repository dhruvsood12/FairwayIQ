//
//  AnalyticsService.swift
//  FairwayIQ
//

import Foundation
import SwiftData

@Observable
final class AnalyticsService {
    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        modelContext = context
    }

    func handicapTrend(rounds: [Round]) -> [(Date, Double)] {
        rounds.prefix(20).enumerated().map { index, round in
            let estimate = 18.0 - Double(index) * 0.3
            return (round.date, max(5.0, estimate))
        }
    }

    func averageScore(rounds: [Round]) -> Double {
        guard !rounds.isEmpty else { return 0 }
        return Double(rounds.map(\.totalStrokes).reduce(0, +)) / Double(rounds.count)
    }

    func fairwayPercentage(rounds: [Round]) -> Double {
        let total = rounds.reduce(0) { $0 + $1.fairwaysPossible }
        guard total > 0 else { return 0 }
        let hit = rounds.reduce(0) { $0 + $1.fairwaysHit }
        return Double(hit) / Double(total) * 100
    }

    func girPercentage(rounds: [Round]) -> Double {
        let total = rounds.count * 18
        guard total > 0 else { return 0 }
        let hit = rounds.reduce(0) { $0 + $1.girsHit }
        return Double(hit) / Double(total) * 100
    }
}
