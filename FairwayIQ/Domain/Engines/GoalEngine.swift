import Foundation

struct GoalProgress: Identifiable {
    let id: UUID
    let goal: PlayerGoal
    let currentValue: Double?
    let progressPercentage: Double
    let trend: GoalTrend
    let statusLabel: String
    let isAchieved: Bool
}

enum GoalTrend: String {
    case improving = "Improving"
    case steady = "Steady"
    case declining = "Declining"
    case noData = "Not enough data"

    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .steady: return "arrow.right"
        case .declining: return "arrow.down.right"
        case .noData: return "questionmark"
        }
    }
}

enum GoalEngine {

    static func evaluateProgress(
        goals: [PlayerGoal],
        recentRounds: [Round],
        allRounds: [Round]
    ) -> [GoalProgress] {
        goals.filter(\.isActive).map { goal in
            evaluate(goal: goal, recentRounds: recentRounds, allRounds: allRounds)
        }
    }

    static func evaluate(
        goal: PlayerGoal,
        recentRounds: [Round],
        allRounds: [Round]
    ) -> GoalProgress {
        guard let metricType = GoalMetricType(rawValue: goal.metricType) else {
            return GoalProgress(
                id: goal.id,
                goal: goal,
                currentValue: nil,
                progressPercentage: 0,
                trend: .noData,
                statusLabel: "Unknown metric type",
                isAchieved: false
            )
        }

        let recent = Array(recentRounds.prefix(5))
        let older = Array(recentRounds.dropFirst(5).prefix(5))

        guard !recent.isEmpty else {
            return GoalProgress(
                id: goal.id,
                goal: goal,
                currentValue: nil,
                progressPercentage: 0,
                trend: .noData,
                statusLabel: "Play rounds to track progress",
                isAchieved: false
            )
        }

        let currentValue = computeMetric(metricType, from: recent)
        let olderValue = older.isEmpty ? nil : computeMetric(metricType, from: older)

        let isBelow = goal.comparisonDirection == "below"
        let progress = computeProgress(current: currentValue, target: goal.targetValue, isBelow: isBelow, metricType: metricType)
        let achieved = isBelow ? currentValue <= goal.targetValue : currentValue >= goal.targetValue
        let trend = computeTrend(current: currentValue, older: olderValue, isBelow: isBelow)

        let statusLabel: String
        if achieved {
            statusLabel = "Goal achieved!"
        } else {
            let diff = abs(currentValue - goal.targetValue)
            if isBelow {
                statusLabel = String(format: "%.1f %@ to go", diff, metricType.unit)
            } else {
                statusLabel = String(format: "%.1f %@ to go", diff, metricType.unit)
            }
        }

        return GoalProgress(
            id: goal.id,
            goal: goal,
            currentValue: currentValue,
            progressPercentage: progress,
            trend: trend,
            statusLabel: statusLabel,
            isAchieved: achieved
        )
    }

    private static func computeMetric(_ metricType: GoalMetricType, from rounds: [Round]) -> Double {
        guard !rounds.isEmpty else { return 0 }
        let count = Double(rounds.count)

        switch metricType {
        case .averageScore:
            return Double(rounds.map(\.totalStrokes).reduce(0, +)) / count

        case .puttsPerRound:
            return Double(rounds.map(\.totalPutts).reduce(0, +)) / count

        case .girPercentage:
            let allScores = rounds.flatMap(\.holeScores)
            guard !allScores.isEmpty else { return 0 }
            return Double(allScores.filter(\.gir).count) / Double(allScores.count) * 100

        case .fairwayPercentage:
            let applicable = rounds.flatMap(\.holeScores).filter { $0.fairwayHit != nil }
            guard !applicable.isEmpty else { return 0 }
            return Double(applicable.filter { $0.fairwayHit == true }.count) / Double(applicable.count) * 100

        case .penaltiesPerRound:
            let totalPen = rounds.flatMap(\.holeScores).reduce(0) { $0 + $1.penalties }
            return Double(totalPen) / count

        case .bestScore:
            return Double(rounds.map(\.totalStrokes).min() ?? 0)
        }
    }

    private static func computeProgress(
        current: Double,
        target: Double,
        isBelow: Bool,
        metricType: GoalMetricType
    ) -> Double {
        let startingPoint: Double
        switch metricType {
        case .averageScore: startingPoint = 120
        case .puttsPerRound: startingPoint = 40
        case .girPercentage: startingPoint = 0
        case .fairwayPercentage: startingPoint = 0
        case .penaltiesPerRound: startingPoint = 8
        case .bestScore: startingPoint = 120
        }

        if isBelow {
            let totalRange = startingPoint - target
            guard totalRange > 0 else { return current <= target ? 1.0 : 0 }
            let progress = (startingPoint - current) / totalRange
            return min(1.0, max(0, progress))
        } else {
            let totalRange = target - startingPoint
            guard totalRange > 0 else { return current >= target ? 1.0 : 0 }
            let progress = (current - startingPoint) / totalRange
            return min(1.0, max(0, progress))
        }
    }

    private static func computeTrend(
        current: Double,
        older: Double?,
        isBelow: Bool
    ) -> GoalTrend {
        guard let older else { return .noData }
        let diff = current - older
        let threshold = 1.0

        if isBelow {
            if diff < -threshold { return .improving }
            if diff > threshold { return .declining }
        } else {
            if diff > threshold { return .improving }
            if diff < -threshold { return .declining }
        }
        return .steady
    }
}
