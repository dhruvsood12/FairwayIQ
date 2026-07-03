import Charts
import FairwayIQCore
import SwiftData
import SwiftUI

struct AnalyticsView: View {
    @Environment(SessionStore.self) private var session
    @Query(sort: \Round.date, order: .forward) private var rounds: [Round]
    @Query private var profiles: [UserProfile]
    @Query(sort: \PlayerGoal.createdAt, order: .reverse) private var goals: [PlayerGoal]
    @State private var viewModel = AnalyticsDashboardViewModel()
    @State private var selectedTab = 0

    private var profile: UserProfile? {
        session.resolvedProfile(in: profiles)
    }

    private var scopedRounds: [Round] {
        session.roundsForCurrentProfile(rounds, profiles: profiles)
    }

    private var scopedGoals: [PlayerGoal] {
        session.goalsForCurrentProfile(goals, profiles: profiles)
    }

    private var goalProgress: [GoalProgress] {
        GoalEngine.evaluateProgress(goals: scopedGoals, recentRounds: Array(scopedRounds.suffix(10).reversed()), allRounds: scopedRounds)
    }

    private let tabs = ["Overview", "Scoring", "Putting", "Driving", "Clubs", "Goals"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                tabPicker
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.xxl) {
                        if scopedRounds.isEmpty {
                            EmptyStateView(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "No Analytics Yet",
                                message: "Complete rounds to see detailed analytics, trends, and insights."
                            )
                        } else {
                            switch selectedTab {
                            case 0: overviewContent
                            case 1: scoringContent
                            case 2: shortGameContent
                            case 3: drivingApproachContent
                            case 4: clubsContent
                            case 5: goalsContent
                            default: overviewContent
                            }
                        }
                    }
                    .padding(Theme.Layout.horizontalPadding)
                    .padding(.bottom, Spacing.xxxl)
                }
            }
            .background(Theme.Color.background)
            .navigationTitle("Analytics")
            .preferredColorScheme(.dark)
        }
        .task(id: refreshKey) { refreshDashboard() }
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(tabs.indices, id: \.self) { idx in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedTab = idx }
                    } label: {
                        Text(tabs[idx])
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(selectedTab == idx ? Theme.Color.background : Theme.Color.textSecondary)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.sm)
                            .background(selectedTab == idx ? Theme.Color.greenPrimary : Theme.Color.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadiusSmall))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Layout.horizontalPadding)
            .padding(.vertical, Spacing.md)
        }
    }

    // MARK: - Overview

    @ViewBuilder
    private var overviewContent: some View {
        overviewCard
        if !viewModel.scoreTrend.isEmpty {
            scoreTrendCard
        }
        statsGridCard
        splitCard
        bestWorstCard
        if let bestType = PerformanceInsights.bestScoringHoleType(rounds: scopedRounds),
           let toughType = PerformanceInsights.toughestHoleType(rounds: scopedRounds)
        {
            holeTypeCard(best: bestType, tough: toughType)
        }
    }

    private var overviewCard: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Overview")
                HStack(spacing: Spacing.lg) {
                    StatTile(title: "Avg Score", value: String(format: "%.1f", viewModel.summary.averageScore))
                    StatTile(title: "Rounds", value: "\(scopedRounds.count)", valueColor: Theme.Color.textPrimary)
                    StatTile(title: "Index", value: String(format: "%.1f", profile?.handicapEstimate ?? 0), valueColor: Theme.Color.greenPrimary)
                }
            }
        }
    }

    private var scoreTrendCard: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Score Trend")
                Chart {
                    ForEach(viewModel.scoreTrend) { item in
                        LineMark(x: .value("Date", item.date), y: .value("Score", item.score))
                            .foregroundStyle(Theme.Color.greenPrimary)
                            .interpolationMethod(.catmullRom)
                        PointMark(x: .value("Date", item.date), y: .value("Score", item.score))
                            .foregroundStyle(Theme.Color.accent)
                            .symbolSize(30)
                    }
                    if let avg = viewModel.summary.averageScore as Double?, avg > 0 {
                        RuleMark(y: .value("Average", avg))
                            .foregroundStyle(Theme.Color.textSecondary.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("avg")
                                    .font(.caption2)
                                    .foregroundStyle(Theme.Color.textSecondary)
                            }
                    }
                }
                .chartYScale(domain: AnalyticsMath.yDomain(scores: viewModel.scoreTrend.map(\.score)))
                .frame(height: 200)
            }
        }
    }

    private var statsGridCard: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Key Stats")
                HStack(spacing: Spacing.md) {
                    StatTile(title: "Fairways", value: String(format: "%.0f%%", viewModel.summary.fairwayPct))
                    StatTile(title: "GIR", value: String(format: "%.0f%%", viewModel.summary.girPct))
                    StatTile(title: "Putts/Rnd", value: String(format: "%.1f", viewModel.summary.puttsPerRound))
                }
                HStack(spacing: Spacing.md) {
                    StatTile(title: "Penalties/Rnd", value: String(format: "%.1f", viewModel.summary.penaltiesPerRound))
                    StatTile(title: "Best", value: viewModel.summary.bestRoundScore.map(String.init) ?? "—", valueColor: Theme.Color.positive)
                    StatTile(title: "Worst", value: viewModel.summary.worstRoundScore.map(String.init) ?? "—", valueColor: Theme.Color.negative)
                }
            }
        }
    }

    private var splitCard: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Front vs Back 9")
                HStack(spacing: Spacing.md) {
                    VStack(spacing: Spacing.xs) {
                        Text(String(format: "%.1f", viewModel.splitSummary.frontNineAverage))
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Theme.Color.accent)
                        Text("Front 9")
                            .font(.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: Spacing.xs) {
                        Text(String(format: "%.1f", viewModel.splitSummary.backNineAverage))
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Theme.Color.accent)
                        Text("Back 9")
                            .font(.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var bestWorstCard: some View {
        let best = scopedRounds.min(by: { $0.totalStrokes < $1.totalStrokes })
        let worst = scopedRounds.max(by: { $0.totalStrokes < $1.totalStrokes })

        return FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Best & Worst")
                HStack(spacing: Spacing.md) {
                    if let best {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("\(best.totalStrokes)")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(Theme.Color.positive)
                            Text(best.courseName)
                                .font(.caption)
                                .foregroundStyle(Theme.Color.textSecondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if let worst, worst.id != best?.id {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("\(worst.totalStrokes)")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(Theme.Color.negative)
                            Text(worst.courseName)
                                .font(.caption)
                                .foregroundStyle(Theme.Color.textSecondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    // MARK: - Scoring Tab

    @ViewBuilder
    private var scoringContent: some View {
        if !viewModel.scoreTrend.isEmpty {
            scoreTrendCard
        }
        coursePerformanceCard
    }

    private var coursePerformanceCard: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Course-by-Course")
                ForEach(viewModel.coursePerformance.prefix(6)) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(item.courseName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.Color.textPrimary)
                                .lineLimit(1)
                            Text("\(item.roundsPlayed) round\(item.roundsPlayed == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(Theme.Color.textSecondary)
                        }
                        Spacer()
                        Text(String(format: "%.1f", item.averageScore))
                            .font(.headline)
                            .foregroundStyle(Theme.Color.accent)
                    }
                    .padding(.vertical, Spacing.xs)
                }
            }
        }
    }

    // MARK: - Short Game Tab

    @ViewBuilder
    private var shortGameContent: some View {
        puttingCard
        girAnalysisCard
    }

    @ViewBuilder
    private var drivingApproachContent: some View {
        drivingCard
        girAnalysisCard
        if !scopedRounds.isEmpty, let latest = scopedRounds.last {
            insightSummaryCard(round: latest)
        }
    }

    private var puttingCard: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Putting", eyebrow: "Short game")
                HStack(spacing: Spacing.md) {
                    StatTile(title: "Putts/Round", value: String(format: "%.1f", viewModel.summary.puttsPerRound))
                    let allScores = scopedRounds.flatMap(\.holeScores)
                    let threePutts = allScores.count(where: { $0.putts >= 3 })
                    let onePutts = allScores.count(where: { $0.putts == 1 })
                    StatTile(title: "1-Putts", value: "\(onePutts)", valueColor: Theme.Color.positive)
                    StatTile(title: "3-Putts", value: "\(threePutts)", valueColor: threePutts > 0 ? Theme.Color.negative : Theme.Color.textSecondary)
                }
            }
        }
    }

    private var girAnalysisCard: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Approach Play", eyebrow: "Driving & irons")
                HStack(spacing: Spacing.md) {
                    StatTile(title: "GIR %", value: String(format: "%.0f%%", viewModel.summary.girPct))
                    let totalGIR = scopedRounds.reduce(0) { $0 + $1.girsHit }
                    let totalHoles = scopedRounds.flatMap(\.holeScores).count
                    StatTile(title: "Total GIR", value: "\(totalGIR)/\(totalHoles)", valueColor: Theme.Color.textPrimary)
                }
            }
        }
    }

    private var drivingCard: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Driving", eyebrow: "Off the tee")
                HStack(spacing: Spacing.md) {
                    StatTile(title: "Fairways", value: String(format: "%.0f%%", viewModel.summary.fairwayPct))
                    let penaltyHoles = scopedRounds.flatMap(\.holeScores).count(where: { $0.penalties > 0 })
                    StatTile(title: "Penalty Holes", value: "\(penaltyHoles)", valueColor: penaltyHoles == 0 ? Theme.Color.positive : Theme.Color.negative)
                    StatTile(title: "Pen/Round", value: String(format: "%.1f", viewModel.summary.penaltiesPerRound))
                }
            }
        }
    }

    // MARK: - Clubs Tab

    @ViewBuilder
    private var clubsContent: some View {
        NavigationLink {
            ClubGappingView()
        } label: {
            FIQCard {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Club Gapping Lab")
                            .font(.headline)
                            .foregroundStyle(Theme.Color.textPrimary)
                        Text("See your distance data, consistency ratings, and miss patterns for each club.")
                            .font(.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)

        NavigationLink {
            SmartCaddieView()
        } label: {
            FIQCard {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Smart Caddie")
                            .font(.headline)
                            .foregroundStyle(Theme.Color.textPrimary)
                        Text("Get hole-by-hole strategy based on your club distances and tendencies.")
                            .font(.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var goalsContent: some View {
        if goalProgress.isEmpty {
            EmptyStateView(
                icon: "target",
                title: "No Active Goals",
                message: "Create goals to compare your scoring, putting, and ball-striking trends against targets."
            )
        } else {
            ForEach(goalProgress) { progress in
                FIQCard {
                    HStack(spacing: Spacing.md) {
                        ProgressRing(progress: progress.progressPercentage, size: 36, lineWidth: 3)
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(progress.goal.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.Color.textPrimary)
                            Text(progress.statusLabel)
                                .font(.caption)
                                .foregroundStyle(Theme.Color.textSecondary)
                        }
                        Spacer()
                        trendBadge(for: progress.trend)
                    }
                }
            }
        }
    }

    private func holeTypeCard(best: HoleTypeInsight, tough: HoleTypeInsight) -> some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Hole Types", eyebrow: "Scoring profile")
                HStack(spacing: Spacing.md) {
                    StatTile(title: "Best", value: best.label, valueColor: Theme.Color.positive, subtitle: String(format: "%.1f", best.averageRelativeToPar))
                    StatTile(title: "Toughest", value: tough.label, valueColor: Theme.Color.negative, subtitle: String(format: "%.1f", tough.averageRelativeToPar))
                }
            }
        }
    }

    private func insightSummaryCard(round: Round) -> some View {
        let worstCategory = PerformanceInsights.costliestMistakeCategory(for: round) ?? "No clear issue"
        return FIQCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeader(title: "Latest Round Insight", eyebrow: "Baseline")
                Text("Most costly category: \(worstCategory)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Color.textPrimary)
                if let baseline = PerformanceInsights.baselineComparison(for: round, against: Array(scopedRounds.dropLast().suffix(5))) {
                    Text(baseline.detail)
                        .font(.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
        }
    }

    private func trendBadge(for trend: GoalTrend) -> some View {
        HStack(spacing: 2) {
            Image(systemName: trend.icon)
                .font(.caption2.weight(.bold))
            Text(trend.rawValue)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(trend == .improving ? Theme.Color.positive : (trend == .declining ? Theme.Color.negative : Theme.Color.textSecondary))
    }
}

// MARK: - Refresh

private extension AnalyticsView {
    var refreshKey: String {
        let roundsKey = rounds.map {
            "\($0.id.uuidString):\($0.totalStrokes):\($0.totalPutts):\($0.scoreRelativeToPar.map(String.init) ?? "na")"
        }.joined(separator: "|")
        let profileKey = session.currentProfileId?.uuidString ?? "no-profile"
        let handicapKey = profile.map { String(format: "%.1f", $0.handicapEstimate) } ?? "no-index"
        return [profileKey, handicapKey, roundsKey].joined(separator: "#")
    }

    func refreshDashboard() {
        viewModel.refresh(rounds: scopedRounds)
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: [Round.self, UserProfile.self], inMemory: true)
        .environment(SessionStore())
}
