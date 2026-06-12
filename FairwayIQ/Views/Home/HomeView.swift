import SwiftUI
import SwiftData
import Charts

struct HomeView: View {
    @Environment(SessionStore.self) private var session
    @Query(sort: \Round.date, order: .reverse) private var rounds: [Round]
    @Query private var profiles: [UserProfile]
    @Query(sort: \PlayerGoal.createdAt) private var goals: [PlayerGoal]
    @State private var showRoundSetup = false

    private var profile: UserProfile? { session.resolvedProfile(in: profiles) }
    private var scopedRounds: [Round] { session.roundsForCurrentProfile(rounds, profiles: profiles) }
    private var scopedGoals: [PlayerGoal] { session.goalsForCurrentProfile(goals, profiles: profiles) }
    private var recentRound: Round? { scopedRounds.first }
    private var baselineRounds: [Round] { Array(scopedRounds.dropFirst().prefix(5)) }
    private var bestHoleType: HoleTypeInsight? { PerformanceInsights.bestScoringHoleType(rounds: scopedRounds) }
    private var mostImprovedMetric: RecentImprovementInsight? {
        PerformanceInsights.mostImprovedMetric(
            recentRounds: Array(scopedRounds.prefix(5)),
            previousRounds: Array(scopedRounds.dropFirst(5).prefix(5))
        )
    }

    private var goalProgress: [GoalProgress] {
        GoalEngine.evaluateProgress(
            goals: scopedGoals.filter(\.isActive),
            recentRounds: Array(scopedRounds.prefix(10)),
            allRounds: scopedRounds
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xxl) {
                    headerSection
                    quickActionsRow
                    if let round = recentRound {
                        recentRoundCard(round)
                    }
                    if !goalProgress.isEmpty {
                        goalsPreviewCard
                    }
                    if scopedRounds.count >= 2 {
                        scoreTrendPreview
                    }
                    if let mostImprovedMetric {
                        improvementInsightCard(mostImprovedMetric)
                    }
                    insightsCard
                    navigationCards
                }
                .padding(Theme.Layout.horizontalPadding)
                .padding(.bottom, Spacing.xxxl)
            }
            .background(Theme.Color.background)
            .navigationTitle("FairwayIQ")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if let name = profile?.playerName, !name.isEmpty {
                Text("Welcome back, \(name)")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Theme.Color.textPrimary)
            }
            HStack(spacing: Spacing.lg) {
                if let handicap = profile?.handicapEstimate {
                    HStack(spacing: Spacing.xs) {
                        Text(String(format: "%.1f", handicap))
                            .font(.headline)
                            .foregroundStyle(Theme.Color.accent)
                        Text("handicap")
                            .font(.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                }
                HStack(spacing: Spacing.xs) {
                    Text("\(scopedRounds.count)")
                        .font(.headline)
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text("rounds")
                        .font(.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
        }
        .padding(.top, Spacing.sm)
    }

    // MARK: - Quick Actions

    private var quickActionsRow: some View {
        HStack(spacing: Spacing.md) {
            quickActionButton(icon: "plus.circle.fill", title: "New Round", color: Theme.Color.greenPrimary) {
                showRoundSetup = true
            }
            .sheet(isPresented: $showRoundSetup) {
                RoundSetupView(onDismiss: { showRoundSetup = false })
            }

            NavigationLink {
                PracticeView()
            } label: {
                quickActionLabel(icon: "figure.golf", title: "Practice", color: Theme.Color.accent)
            }
            .buttonStyle(.plain)

            NavigationLink {
                SmartCaddieView()
            } label: {
                quickActionLabel(icon: "brain.head.profile", title: "Caddie", color: Color.orange)
            }
            .buttonStyle(.plain)
        }
    }

    private func quickActionButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            quickActionLabel(icon: icon, title: title, color: color)
        }
        .buttonStyle(.plain)
    }

    private func quickActionLabel(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(Theme.Color.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
        .background(Theme.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
    }

    // MARK: - Recent Round

    private func recentRoundCard(_ round: Round) -> some View {
        NavigationLink {
            RoundSummaryView(round: round)
        } label: {
            FIQCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack {
                        Text("Recent Round")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.Color.textSecondary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(round.courseName)
                                .font(.headline)
                                .foregroundStyle(Theme.Color.textPrimary)
                            Text(round.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(Theme.Color.textSecondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: Spacing.xxs) {
                            Text("\(round.totalStrokes)")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(Theme.Color.accent)
                            let diff = round.scoreRelativeToPar
                            Text(diff >= 0 ? "+\(diff)" : "\(diff)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(diff <= 0 ? Theme.Color.positive : Theme.Color.negative)
                        }
                    }
                    HStack(spacing: Spacing.lg) {
                        miniStatLabel("FIR", "\(round.fairwaysHit)/\(round.fairwaysPossible)")
                        miniStatLabel("GIR", "\(round.girsHit)/\(round.holeScores.count)")
                        miniStatLabel("Putts", "\(round.totalPutts)")
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func miniStatLabel(_ title: String, _ value: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.Color.textPrimary)
            Text(title)
                .font(.caption2)
                .foregroundStyle(Theme.Color.textSecondary)
        }
    }

    // MARK: - Goals Preview

    private var goalsPreviewCard: some View {
        NavigationLink {
            GoalsView()
        } label: {
            FIQCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    cardHeader("Goals Progress")
                    ForEach(goalProgress.prefix(3)) { progress in
                        HStack(spacing: Spacing.md) {
                            ProgressRing(
                                progress: progress.progressPercentage,
                                size: 28,
                                lineWidth: 3,
                                color: progress.isAchieved ? Theme.Color.positive : Theme.Color.accent
                            )
                            Text(progress.goal.title)
                                .font(.subheadline)
                                .foregroundStyle(Theme.Color.textPrimary)
                            Spacer()
                            Text(progress.statusLabel)
                                .font(.caption)
                                .foregroundStyle(progress.isAchieved ? Theme.Color.positive : Theme.Color.textSecondary)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Score Trend

    private var scoreTrendPreview: some View {
        NavigationLink {
            AnalyticsView()
        } label: {
            FIQCard {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack {
                        cardHeader("Score Trend")
                        Spacer()
                        if let improvement = scoreImprovement {
                            TrendBadge(trend: improvement.text, isPositive: improvement.isPositive)
                        }
                    }
                    let trend = AnalyticsCalculators.scoreTrend(rounds: Array(scopedRounds.prefix(10)))
                    Chart {
                        ForEach(trend) { item in
                            LineMark(x: .value("Date", item.date), y: .value("Score", item.score))
                                .foregroundStyle(Theme.Color.greenPrimary)
                                .interpolationMethod(.catmullRom)
                            PointMark(x: .value("Date", item.date), y: .value("Score", item.score))
                                .foregroundStyle(Theme.Color.accent)
                                .symbolSize(20)
                        }
                    }
                    .chartYScale(domain: AnalyticsCalculators.yDomain(for: trend.map(\.score)))
                    .frame(height: 100)
                    .chartXAxis(.hidden)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func improvementInsightCard(_ insight: RecentImprovementInsight) -> some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Most Improved Metric", eyebrow: "Momentum")
                Text(insight.metricName)
                    .font(.headline)
                    .foregroundStyle(Theme.Color.textPrimary)
                Text("\(insight.changeText) compared with the prior five rounds")
                    .font(.subheadline)
                    .foregroundStyle(insight.isPositive ? Theme.Color.positive : Theme.Color.negative)
            }
        }
    }

    private var scoreImprovement: (text: String, isPositive: Bool)? {
        guard scopedRounds.count >= 4 else { return nil }
        let recent = Array(scopedRounds.prefix(3))
        let older = Array(scopedRounds.dropFirst(3).prefix(3))
        guard !older.isEmpty else { return nil }
        let recentAvg = Double(recent.map(\.totalStrokes).reduce(0, +)) / Double(recent.count)
        let olderAvg = Double(older.map(\.totalStrokes).reduce(0, +)) / Double(older.count)
        let diff = recentAvg - olderAvg
        if abs(diff) < 0.5 { return nil }
        return (
            text: String(format: "%.1f", abs(diff)),
            isPositive: diff < 0
        )
    }

    // MARK: - Insights

    private var insightsCard: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Quick Insights", eyebrow: "Smart summary")
                if scopedRounds.isEmpty {
                    Text("Play your first round to unlock insights.")
                        .font(.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                } else {
                    if let bestHoleType {
                        Text("Best scoring hole type: \(bestHoleType.label)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.Color.textPrimary)
                        Text(String(format: "%.1f vs par on average", bestHoleType.averageRelativeToPar))
                            .font(.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                    if let recentRound,
                       let costly = PerformanceInsights.costliestMistakeCategory(for: recentRound) {
                        Text("Most costly mistake lately: \(costly)")
                            .font(.caption)
                            .foregroundStyle(Theme.Color.negative)
                    }
                    if let recentRound,
                       let baseline = PerformanceInsights.baselineComparison(for: recentRound, against: baselineRounds) {
                        HStack(spacing: Spacing.md) {
                            FIQChip(text: baseline.deltaText, color: baseline.isPositive ? Theme.Color.positive : Theme.Color.negative)
                            Text(baseline.detail)
                                .font(.caption)
                                .foregroundStyle(Theme.Color.textSecondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Navigation

    private var navigationCards: some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.md) {
                navCard(icon: "ruler", title: "Club Lab", destination: ClubGappingView())
                navCard(icon: "target", title: "Goals", destination: GoalsView())
            }
            HStack(spacing: Spacing.md) {
                navCard(icon: "person.2.fill", title: "Leaderboard", destination: LeaderboardView())
                navCard(icon: "brain.head.profile", title: "Smart Caddie", destination: SmartCaddieView())
            }
        }
    }

    private func navCard<Dest: View>(icon: String, title: String, destination: Dest) -> some View {
        NavigationLink {
            destination
        } label: {
            HStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Theme.Color.greenPrimary)
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.Color.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            .padding(Theme.Layout.cardPadding)
            .background(Theme.Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
        }
        .buttonStyle(.plain)
    }

    private func cardHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.Color.textSecondary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Theme.Color.textSecondary)
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [UserProfile.self, Round.self, Course.self, PlayerGoal.self], inMemory: true)
        .environment(SessionStore())
}
