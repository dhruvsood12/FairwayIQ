import Foundation
import SwiftData

@Model
final class PlayerGoal {
    var id: UUID
    var title: String
    var metricType: String
    var targetValue: Double
    var comparisonDirection: String
    var isActive: Bool
    var createdAt: Date
    var player: UserProfile?

    init(
        id: UUID = UUID(),
        title: String,
        metricType: String,
        targetValue: Double,
        comparisonDirection: String = "below",
        isActive: Bool = true,
        createdAt: Date = Date(),
        player: UserProfile? = nil
    ) {
        self.id = id
        self.title = title
        self.metricType = metricType
        self.targetValue = targetValue
        self.comparisonDirection = comparisonDirection
        self.isActive = isActive
        self.createdAt = createdAt
        self.player = player
    }
}

enum GoalMetricType: String, CaseIterable, Identifiable {
    case averageScore = "Average Score"
    case puttsPerRound = "Putts per Round"
    case girPercentage = "GIR %"
    case fairwayPercentage = "Fairway %"
    case penaltiesPerRound = "Penalties per Round"
    case bestScore = "Best Score"

    var id: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .averageScore: return "number.circle"
        case .puttsPerRound: return "circle.circle"
        case .girPercentage: return "scope"
        case .fairwayPercentage: return "arrow.up.forward"
        case .penaltiesPerRound: return "exclamationmark.triangle"
        case .bestScore: return "trophy"
        }
    }

    var unit: String {
        switch self {
        case .averageScore, .bestScore: return "strokes"
        case .puttsPerRound: return "putts"
        case .girPercentage, .fairwayPercentage: return "%"
        case .penaltiesPerRound: return "penalties"
        }
    }

    var defaultTarget: Double {
        switch self {
        case .averageScore: return 90
        case .puttsPerRound: return 34
        case .girPercentage: return 40
        case .fairwayPercentage: return 50
        case .penaltiesPerRound: return 2
        case .bestScore: return 85
        }
    }

    var defaultDirection: String {
        switch self {
        case .girPercentage, .fairwayPercentage: return "above"
        default: return "below"
        }
    }

    var minValue: Double {
        switch self {
        case .averageScore, .bestScore: return 50
        case .puttsPerRound: return 20
        case .girPercentage, .fairwayPercentage: return 5
        case .penaltiesPerRound: return 0
        }
    }

    var maxValue: Double {
        switch self {
        case .averageScore, .bestScore: return 150
        case .puttsPerRound: return 50
        case .girPercentage, .fairwayPercentage: return 100
        case .penaltiesPerRound: return 10
        }
    }
}
