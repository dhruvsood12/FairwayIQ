import Foundation

struct BaselineComparison: Hashable {
    let title: String
    let detail: String
    let deltaText: String
    let isPositive: Bool
}

struct RecentImprovementInsight: Hashable {
    let metricName: String
    let changeText: String
    let isPositive: Bool
}

struct RoundStretchInsight: Hashable {
    let title: String
    let holesText: String
    let relativeToPar: Int
}

struct HoleTypeInsight: Hashable {
    let label: String
    let averageRelativeToPar: Double
    let roundsSampled: Int
}

enum PerformanceInsights {
    static func baselineComparison(for round: Round, against baselineRounds: [Round]) -> BaselineComparison? {
        guard !baselineRounds.isEmpty else { return nil }

        let baselineScores = baselineRounds.map(\.totalStrokes)
        let baselineAverage = Double(baselineScores.reduce(0, +)) / Double(baselineScores.count)
        let delta = Double(round.totalStrokes) - baselineAverage
        guard abs(delta) >= 1 else { return nil }

        let isPositive = delta < 0
        return BaselineComparison(
            title: isPositive ? "Better Than Baseline" : "Above Baseline",
            detail: String(
                format: "This round was %.1f strokes %@ your recent average of %.1f.",
                abs(delta),
                isPositive ? "better than" : "above",
                baselineAverage
            ),
            deltaText: String(format: "%@%.1f", isPositive ? "-" : "+", abs(delta)),
            isPositive: isPositive
        )
    }

    static func mostImprovedMetric(recentRounds: [Round], previousRounds: [Round]) -> RecentImprovementInsight? {
        guard !recentRounds.isEmpty, !previousRounds.isEmpty else { return nil }

        let recentSummary = AnalyticsCalculators.summary(rounds: recentRounds)
        let previousSummary = AnalyticsCalculators.summary(rounds: previousRounds)

        let candidates: [(String, Double, Bool)] = [
            ("Scoring", previousSummary.averageScore - recentSummary.averageScore, true),
            ("Fairways", recentSummary.fairwayPct - previousSummary.fairwayPct, true),
            ("GIR", recentSummary.girPct - previousSummary.girPct, true),
            ("Putts", previousSummary.puttsPerRound - recentSummary.puttsPerRound, true),
            ("Penalties", previousSummary.penaltiesPerRound - recentSummary.penaltiesPerRound, true)
        ]

        guard let best = candidates.max(by: { abs($0.1) < abs($1.1) }), abs(best.1) >= 0.5 else {
            return nil
        }

        return RecentImprovementInsight(
            metricName: best.0,
            changeText: String(format: "%@%.1f", best.1 >= 0 ? "+" : "", best.1),
            isPositive: best.1 > 0
        )
    }

    static func bestAndWorstStretch(for round: Round, windowSize: Int = 3) -> (best: RoundStretchInsight?, worst: RoundStretchInsight?) {
        let scores = round.holeScores.sorted { $0.holeNumber < $1.holeNumber }
        guard scores.count >= windowSize else { return (nil, nil) }

        var bestWindow: (start: Int, end: Int, total: Int)?
        var worstWindow: (start: Int, end: Int, total: Int)?

        for index in 0 ... (scores.count - windowSize) {
            let window = Array(scores[index ..< (index + windowSize)])
            let relative = window.reduce(0) { partialResult, score in
                partialResult + (score.strokes - par(for: score.holeNumber, round: round))
            }
            let candidate = (start: window.first?.holeNumber ?? 0, end: window.last?.holeNumber ?? 0, total: relative)

            if bestWindow == nil || relative < bestWindow!.total {
                bestWindow = candidate
            }
            if worstWindow == nil || relative > worstWindow!.total {
                worstWindow = candidate
            }
        }

        let bestInsight = bestWindow.map {
            RoundStretchInsight(title: "Best Stretch", holesText: "Holes \($0.start)-\($0.end)", relativeToPar: $0.total)
        }
        let worstInsight = worstWindow.map {
            RoundStretchInsight(title: "Worst Stretch", holesText: "Holes \($0.start)-\($0.end)", relativeToPar: $0.total)
        }

        return (bestInsight, worstInsight?.relativeToPar ?? 0 > 0 ? worstInsight : nil)
    }

    static func bestScoringHoleType(rounds: [Round]) -> HoleTypeInsight? {
        holeTypeInsights(rounds: rounds).min(by: { $0.averageRelativeToPar < $1.averageRelativeToPar })
    }

    static func toughestHoleType(rounds: [Round]) -> HoleTypeInsight? {
        holeTypeInsights(rounds: rounds).max(by: { $0.averageRelativeToPar < $1.averageRelativeToPar })
    }

    static func costliestMistakeCategory(for round: Round) -> String? {
        let threePutts = round.holeScores.count(where: { $0.putts >= 3 })
        let penalties = round.holeScores.reduce(0) { $0 + $1.penalties }
        let missedGreens = round.holeScores.count(where: { !$0.gir })

        let categories: [(String, Int)] = [
            ("Three-putts", threePutts),
            ("Penalties", penalties),
            ("Missed greens", missedGreens)
        ]

        guard let top = categories.max(by: { $0.1 < $1.1 }), top.1 > 0 else { return nil }
        return top.0
    }

    private static func holeTypeInsights(rounds: [Round]) -> [HoleTypeInsight] {
        var grouped: [String: [Int]] = [:]

        for round in rounds {
            for score in round.holeScores {
                let par = par(for: score.holeNumber, round: round)
                let key = "Par \(par)s"
                grouped[key, default: []].append(score.strokes - par)
            }
        }

        return grouped.compactMap { key, values in
            guard !values.isEmpty else { return nil }
            return HoleTypeInsight(
                label: key,
                averageRelativeToPar: Double(values.reduce(0, +)) / Double(values.count),
                roundsSampled: values.count
            )
        }
        .sorted { $0.averageRelativeToPar < $1.averageRelativeToPar }
    }

    private static func par(for holeNumber: Int, round: Round) -> Int {
        round.course?.holes.first(where: { $0.number == holeNumber })?.par ?? 4
    }
}
