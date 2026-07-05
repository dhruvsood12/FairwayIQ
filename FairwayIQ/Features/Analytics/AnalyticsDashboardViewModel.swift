import FairwayIQCore
import Foundation

@Observable
final class AnalyticsDashboardViewModel {
    private(set) var scoreTrend: [ScoreTrendPoint] = []
    private(set) var splitSummary: SplitSummary = .init(frontNineAverage: 0, backNineAverage: 0)
    private(set) var coursePerformance: [CoursePerformance] = []
    private(set) var summary: AnalyticsSummary = .init(
        averageScore: 0,
        fairwayPct: 0,
        girPct: 0,
        puttsPerRound: 0,
        penaltiesPerRound: 0,
        bestRoundScore: nil,
        worstRoundScore: nil
    )

    func refresh(rounds: [Round]) {
        let snapshots = rounds.map(\.snapshot)
        scoreTrend = AnalyticsMath.scoreTrend(rounds: snapshots)
        summary = AnalyticsMath.summary(rounds: rounds.map(\.rollup))
        splitSummary = AnalyticsMath.frontBackSplit(rounds: snapshots)
        coursePerformance = AnalyticsMath.coursePerformance(rounds: snapshots)
    }
}
