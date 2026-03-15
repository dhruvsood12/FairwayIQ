//
//  AnalyticsView.swift
//  FairwayIQ
//

import SwiftUI
import SwiftData
import Charts

private struct ScoreTrendPoint: Identifiable {
    let id: Date
    let date: Date
    let score: Int
}

private struct HandicapTrendPoint: Identifiable {
    let id: Date
    let date: Date
    let index: Double
}

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Round.date, order: .forward) private var rounds: [Round]
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }
    private var sortedRounds: [Round] { rounds.sorted { $0.date < $1.date } }
    private var handicapTrendData: [HandicapTrendPoint] {
        sortedRounds.enumerated().map { index, _ in
            let estimate = (profile?.handicapEstimate ?? 18) - Double(index) * 0.4
            let date = sortedRounds[index].date
            return HandicapTrendPoint(id: date, date: date, index: max(0, estimate))
        }
    }
    private var scoreTrendData: [ScoreTrendPoint] {
        sortedRounds.map { ScoreTrendPoint(id: $0.date, date: $0.date, score: $0.totalStrokes) }
    }
    private var averageScore: Double {
        guard !rounds.isEmpty else { return 0 }
        return Double(rounds.map(\.totalStrokes).reduce(0, +)) / Double(rounds.count)
    }
    private var fairwayPct: Double {
        let total = rounds.reduce(0) { $0 + $1.fairwaysPossible }
        guard total > 0 else { return 0 }
        return Double(rounds.reduce(0) { $0 + $1.fairwaysHit }) / Double(total) * 100
    }
    private var girPct: Double {
        guard !rounds.isEmpty else { return 0 }
        let total = rounds.count * 18
        let hit = rounds.reduce(0) { $0 + $1.girsHit }
        return Double(hit) / Double(total) * 100
    }
    private var puttsPerRound: Double {
        guard !rounds.isEmpty else { return 0 }
        return Double(rounds.reduce(0) { $0 + $1.totalPutts }) / Double(rounds.count)
    }
    private var bestRound: Round? { rounds.min(by: { $0.totalStrokes < $1.totalStrokes }) }
    private var worstRound: Round? { rounds.max(by: { $0.totalStrokes < $1.totalStrokes }) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Layout.sectionSpacing) {
                    overviewCard
                    if !rounds.isEmpty {
                        scoreTrendCard
                        handicapTrendCard
                        statsGridCard
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
    }

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.1f", averageScore))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.Color.accent)
                    Text("Avg score")
                        .font(.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                .frame(maxWidth: .infinity)
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(rounds.count)")
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
                    Text("Index")
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
                ForEach(scoreTrendData) { item in
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
            .chartYScale(domain: 65...95)
            .frame(height: 180)
        }
        .padding(Theme.Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
    }

    private var handicapTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Handicap trend")
                .font(.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            Chart {
                ForEach(handicapTrendData) { item in
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
            .chartYScale(domain: 0...30)
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
                miniStat(title: "Fairways", value: String(format: "%.0f%%", fairwayPct))
                miniStat(title: "GIR", value: String(format: "%.0f%%", girPct))
                miniStat(title: "Putts/rnd", value: String(format: "%.1f", puttsPerRound))
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

#Preview {
    AnalyticsView()
        .modelContainer(for: [Round.self, UserProfile.self], inMemory: true)
}
