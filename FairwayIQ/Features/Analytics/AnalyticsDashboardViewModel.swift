import Foundation

@Observable
final class AnalyticsDashboardViewModel {
    private(set) var scoreTrend: [ScoreTrendPoint] = []
    private(set) var indexTrend: [HandicapTrendPoint] = []
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

    func refresh(rounds: [Round], profileIndexEstimate: Double?) {
        scoreTrend = AnalyticsCalculators.scoreTrend(rounds: rounds)
        indexTrend = AnalyticsCalculators.indexTrend(rounds: rounds, profileIndexEstimate: profileIndexEstimate)
        summary = AnalyticsCalculators.summary(rounds: rounds)
        splitSummary = AnalyticsCalculators.frontBackSplit(rounds: rounds)
        coursePerformance = AnalyticsCalculators.coursePerformance(rounds: rounds)
    }
}
