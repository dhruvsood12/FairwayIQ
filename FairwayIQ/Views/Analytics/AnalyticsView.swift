//
//  AnalyticsView.swift
//  FairwayIQ
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Environment(SessionStore.self) private var session
    @Query(sort: \Round.date, order: .forward) private var rounds: [Round]
    @Query private var profiles: [UserProfile]
    @State private var viewModel = AnalyticsDashboardViewModel()

    private var profile: UserProfile? { session.resolvedProfile(in: profiles) }
    private var scopedRounds: [Round] { session.roundsForCurrentProfile(rounds, profiles: profiles) }
    private var bestRound: Round? { scopedRounds.min(by: { $0.totalStrokes < $1.totalStrokes }) }
    private var worstRound: Round? { scopedRounds.max(by: { $0.totalStrokes < $1.totalStrokes }) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Layout.sectionSpacing) {
                    overviewCard
                    if !scopedRounds.isEmpty {
                        scoreTrendCard
                        handicapTrendCard
                        statsGridCard
                        splitCard
                        coursePerformanceCard
                        bestWorstCard
                    } else {
                        emptyAnalyticsCard
                    }
                }
                .padding(Theme.Layout.horizontalPadding)
                .padding(.bottom, 32)
            }
            .background(Theme.Color.background)
            .navigationTitle("Analytics")
            .preferredColorScheme(.dark)
        }
        .task(id: refreshKey) { refreshDashboard() }
    }

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.1f", viewModel.summary.averageScore))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.Color.accent)
                    Text("Avg score")
                        .font(.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                .frame(maxWidth: .infinity)
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(scopedRounds.count)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text("Rounds")
                        .font(.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                .frame(maxWidth: .infinity)
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.1f", profile?.handicapEstimate ?? 0))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.Color.greenPrimary)
                    Text("Index (estimate)")
                        .font(.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(Theme.Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
    }

    private var scoreTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Score trend")
                .font(.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            Chart {
                ForEach(viewModel.scoreTrend) { item in
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Score", item.score)
                    )
                    .foregroundStyle(Theme.Color.greenPrimary)
                    .interpolationMethod(.catmullRom)
                    PointMark(
                        x: .value("Date", item.date),
                        y: .value("Score", item.score)
                    )
                    .foregroundStyle(Theme.Color.accent)
                }
            }
            .chartYScale(domain: AnalyticsCalculators.yDomain(for: viewModel.scoreTrend.map(\.score)))
            .frame(height: 180)
        }
        .padding(Theme.Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
    }

    private var handicapTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Index estimate")
                .font(.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            Chart {
                ForEach(viewModel.indexTrend) { item in
                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value("Index", item.index)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.Color.greenPrimary.opacity(0.6), Theme.Color.greenPrimary.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Index", item.index)
                    )
                    .foregroundStyle(Theme.Color.greenPrimary)
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYScale(domain: 0...54)
            .frame(height: 160)
        }
        .padding(Theme.Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
    }

    private var statsGridCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key stats")
                .font(.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            HStack(spacing: 12) {
                miniStat(title: "Fairways", value: String(format: "%.0f%%", viewModel.summary.fairwayPct))
                miniStat(title: "GIR", value: String(format: "%.0f%%", viewModel.summary.girPct))
                miniStat(title: "Putts/rnd", value: String(format: "%.1f", viewModel.summary.puttsPerRound))
            }
            HStack(spacing: 12) {
                miniStat(title: "Penalties/rnd", value: String(format: "%.1f", viewModel.summary.penaltiesPerRound))
                miniStat(title: "Best", value: viewModel.summary.bestRoundScore.map(String.init) ?? "—")
                miniStat(title: "Worst", value: viewModel.summary.worstRoundScore.map(String.init) ?? "—")
            }
        }
        .padding(Theme.Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
    }

    private var splitCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Front vs back")
                .font(.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            HStack(spacing: 12) {
                miniStat(title: "Front 9", value: String(format: "%.1f", viewModel.splitSummary.frontNineAverage))
                miniStat(title: "Back 9", value: String(format: "%.1f", viewModel.splitSummary.backNineAverage))
            }
        }
        .padding(Theme.Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
    }

    private var coursePerformanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Course-by-course")
                .font(.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            ForEach(viewModel.coursePerformance.prefix(4)) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.courseName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.Color.textPrimary)
                            .lineLimit(1)
                        Text("\(item.roundsPlayed) rounds")
                            .font(.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                    Spacer()
                    Text(String(format: "%.1f", item.averageScore))
                        .font(.headline)
                        .foregroundStyle(Theme.Color.accent)
                }
                .padding(.vertical, 6)
            }
        }
        .padding(Theme.Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
    }

    private func miniStat(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Theme.Color.accent)
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var bestWorstCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Best & worst")
                .font(.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            HStack(spacing: 12) {
                if let best = bestRound {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(best.totalStrokes)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Theme.Color.positive)
                        Text(best.courseName)
                            .font(.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
                if let worst = worstRound, worst.id != bestRound?.id {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(worst.totalStrokes)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Theme.Color.negative)
                        Text(worst.courseName)
                            .font(.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(Theme.Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
    }

    private var emptyAnalyticsCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundStyle(Theme.Color.textSecondary)
            Text("Complete rounds to see analytics")
                .font(.subheadline)
                .foregroundStyle(Theme.Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Layout.cardPadding)
        .background(Theme.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
    }
}

private extension AnalyticsView {
    var refreshKey: String {
        let roundsKey = rounds.map {
            "\($0.id.uuidString):\($0.totalStrokes):\($0.totalPutts):\($0.scoreRelativeToPar)"
        }.joined(separator: "|")
        let profileKey = session.currentProfileId?.uuidString ?? "no-profile"
        let handicapKey = profile.map { String(format: "%.1f", $0.handicapEstimate) } ?? "no-index"
        return [profileKey, handicapKey, roundsKey].joined(separator: "#")
    }

    func refreshDashboard() {
        viewModel.refresh(rounds: scopedRounds, profileIndexEstimate: profile?.handicapEstimate)
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: [Round.self, UserProfile.self], inMemory: true)
        .environment(SessionStore())
}
