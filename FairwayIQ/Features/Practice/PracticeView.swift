import SwiftData
import SwiftUI

struct PracticeView: View {
    @Environment(SessionStore.self) private var session
    @Query(sort: \PracticeSession.date, order: .reverse) private var sessions: [PracticeSession]
    @Query private var profiles: [UserProfile]
    @State private var showNewSession = false

    private var profile: UserProfile? {
        session.resolvedProfile(in: profiles)
    }

    private var scopedSessions: [PracticeSession] {
        session.practiceSessionsForCurrentProfile(sessions, profiles: profiles)
    }

    private var recentShotRecords: [ShotRecord] {
        scopedSessions.flatMap { session in
            session.shots.map {
                ShotRecord(
                    club: $0.club,
                    lie: $0.lie,
                    shotType: $0.shotType,
                    distanceYards: $0.distanceYards,
                    result: $0.result,
                    date: $0.timestamp,
                    isPractice: true
                )
            }
        }
    }

    private var topClubSummary: ClubSummary? {
        ClubGappingEngine.computeClubSummaries(
            shots: recentShotRecords,
            filters: .init(recentDays: 30, includePractice: true, includeRounds: false)
        ).first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xxl) {
                    quickStatsSection
                    if let topClubSummary {
                        momentumCard(summary: topClubSummary)
                    }
                    if scopedSessions.isEmpty {
                        EmptyStateView(
                            icon: "figure.golf",
                            title: "No Practice Sessions",
                            message: "Log practice shots to build your club distance data and improve your Smart Caddie recommendations.",
                            actionTitle: "Start Practice",
                            onAction: { showNewSession = true }
                        )
                    } else {
                        sessionsListSection
                    }
                }
                .padding(Theme.Layout.horizontalPadding)
                .padding(.bottom, Spacing.xxxl)
            }
            .background(Theme.Color.background)
            .navigationTitle("Practice")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showNewSession = true } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.Color.accent)
                    }
                }
            }
            .sheet(isPresented: $showNewSession) {
                PracticeSessionEntryView(onDismiss: { showNewSession = false })
            }
        }
    }

    private var quickStatsSection: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Practice Stats", eyebrow: "Training")
                HStack(spacing: Spacing.md) {
                    StatTile(title: "Sessions", value: "\(scopedSessions.count)")
                    StatTile(title: "Total Shots", value: "\(scopedSessions.reduce(0) { $0 + $1.shotCount })")
                    let allDistances = scopedSessions.flatMap(\.shots).compactMap(\.distanceYards)
                    StatTile(
                        title: "Avg Distance",
                        value: allDistances.isEmpty ? "—" : "\(Int(allDistances.reduce(0, +) / Double(allDistances.count)))y"
                    )
                }
            }
        }
    }

    private func momentumCard(summary: ClubSummary) -> some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Distance Lab Momentum", eyebrow: "Last 30 days")
                Text("Your most reliable practice club lately is \(summary.clubName).")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.Color.textPrimary)
                HStack(spacing: Spacing.md) {
                    StatTile(title: "Avg", value: "\(Int(summary.averageDistance))y")
                    StatTile(title: "Carry", value: summary.carryDistanceEstimate.map { "\(Int($0))y" } ?? "—")
                    StatTile(title: "Trust", value: summary.trustLabel, valueColor: Theme.Color.positive)
                }
            }
        }
    }

    private var sessionsListSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Recent Sessions")
            ForEach(scopedSessions.prefix(20)) { session in
                NavigationLink {
                    PracticeSessionDetailView(session: session)
                } label: {
                    practiceSessionRow(session)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func practiceSessionRow(_ session: PracticeSession) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: PracticeSessionType(rawValue: session.sessionType)?.icon ?? "figure.golf")
                .font(.title3)
                .foregroundStyle(Theme.Color.greenPrimary)
                .frame(width: 40, height: 40)
                .background(Theme.Color.greenMuted.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(session.sessionType)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Color.textPrimary)
                Text(session.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text("\(session.shotCount) shots")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.Color.accent)
                if let avg = session.averageDistance {
                    Text("\(Int(avg))y avg")
                        .font(.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
        }
        .padding(Theme.Layout.cardPadding)
        .background(Theme.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
    }
}
