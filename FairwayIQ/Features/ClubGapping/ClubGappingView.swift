import Charts
import SwiftData
import SwiftUI

struct ClubGappingView: View {
    @Environment(SessionStore.self) private var session
    @Query(sort: \Round.date, order: .reverse) private var rounds: [Round]
    @Query(sort: \PracticeSession.date, order: .reverse) private var practiceSessions: [PracticeSession]
    @Query private var profiles: [UserProfile]

    @State private var includePractice = true
    @State private var includeRounds = true
    @State private var recentDaysFilter: Int?
    @State private var selectedLieFilter: String?
    @State private var selectedShotTypeFilter: String?
    @State private var selectedClub: ClubSummary?

    private var profile: UserProfile? {
        session.resolvedProfile(in: profiles)
    }

    private var scopedRounds: [Round] {
        session.roundsForCurrentProfile(rounds, profiles: profiles)
    }

    private var scopedPracticeSessions: [PracticeSession] {
        session.practiceSessionsForCurrentProfile(practiceSessions, profiles: profiles)
    }

    private var lies: [String] {
        Array(Set(allShotRecords.map(\.lie))).sorted()
    }

    private var shotTypes: [String] {
        Array(Set(allShotRecords.map(\.shotType))).sorted()
    }

    private var allShotRecords: [ShotRecord] {
        var records: [ShotRecord] = []
        for round in scopedRounds {
            for shot in round.shots {
                records.append(ShotRecord(
                    club: shot.club,
                    lie: shot.lie,
                    shotType: shot.shotType,
                    distanceYards: shot.distanceYards,
                    result: shot.notes,
                    date: shot.timestamp,
                    isPractice: false
                ))
            }
        }
        for session in scopedPracticeSessions {
            for shot in session.shots {
                records.append(ShotRecord(
                    club: shot.club,
                    lie: shot.lie,
                    shotType: shot.shotType,
                    distanceYards: shot.distanceYards,
                    result: shot.result,
                    date: shot.timestamp,
                    isPractice: true
                ))
            }
        }
        return records
    }

    private var clubSummaries: [ClubSummary] {
        ClubGappingEngine.computeClubSummaries(
            shots: allShotRecords,
            filters: .init(
                lieFilter: selectedLieFilter,
                shotTypeFilter: selectedShotTypeFilter,
                recentDays: recentDaysFilter,
                includePractice: includePractice,
                includeRounds: includeRounds
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xxl) {
                filterSection
                if clubSummaries.isEmpty {
                    EmptyStateView(
                        icon: "ruler",
                        title: "No Club Data Yet",
                        message: "Log shots during rounds or practice sessions to see your club distances, consistency, and miss patterns."
                    )
                } else {
                    gappingChartSection
                    clubListSection
                }
            }
            .padding(Theme.Layout.horizontalPadding)
            .padding(.bottom, Spacing.xxxl)
        }
        .background(Theme.Color.background)
        .navigationTitle("Club Gapping Lab")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedClub) { club in
            ClubDetailSheet(summary: club)
        }
    }

    private var filterSection: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Filters", eyebrow: "Data set")
                HStack(spacing: Spacing.md) {
                    Toggle("Rounds", isOn: $includeRounds)
                        .toggleStyle(.button)
                        .tint(Theme.Color.greenPrimary)
                        .font(.caption.weight(.medium))
                    Toggle("Practice", isOn: $includePractice)
                        .toggleStyle(.button)
                        .tint(Theme.Color.greenPrimary)
                        .font(.caption.weight(.medium))
                }
                Picker("Timeframe", selection: $recentDaysFilter) {
                    Text("All Time").tag(Int?.none)
                    Text("Last 30 Days").tag(Int?.some(30))
                    Text("Last 90 Days").tag(Int?.some(90))
                }
                .pickerStyle(.segmented)
                Picker("Lie", selection: $selectedLieFilter) {
                    Text("All Lies").tag(String?.none)
                    ForEach(lies, id: \.self) { Text($0).tag(String?.some($0)) }
                }
                .pickerStyle(.menu)
                Picker("Shot Type", selection: $selectedShotTypeFilter) {
                    Text("All Shots").tag(String?.none)
                    ForEach(shotTypes, id: \.self) { Text($0).tag(String?.some($0)) }
                }
                .pickerStyle(.menu)
            }
        }
    }

    private var gappingChartSection: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Distance Gapping", eyebrow: "Club lab")
                Chart {
                    ForEach(clubSummaries) { club in
                        BarMark(
                            x: .value("Distance", club.averageDistance),
                            y: .value("Club", club.clubName)
                        )
                        .foregroundStyle(colorForConfidence(club.confidence))
                        .annotation(position: .trailing) {
                            Text("\(Int(club.averageDistance))y")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Theme.Color.textSecondary)
                        }
                    }
                }
                .chartXAxisLabel("Average Distance (yards)")
                .frame(height: CGFloat(clubSummaries.count * 36 + 40))
            }
        }
    }

    private var clubListSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Club Details")
            ForEach(clubSummaries) { club in
                Button { selectedClub = club } label: {
                    clubRow(club)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func clubRow(_ club: ClubSummary) -> some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack(spacing: Spacing.sm) {
                    Text(club.clubName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.Color.textPrimary)
                    ConfidenceIndicator(confidence: club.confidence)
                }
                Text(club.consistencyRating)
                    .font(.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
                Text(club.trustLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(colorForConfidence(club.confidence))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: Spacing.xxs) {
                Text("\(Int(club.averageDistance))y")
                    .font(.headline)
                    .foregroundStyle(Theme.Color.accent)
                Text("carry \(club.carryDistanceEstimate.map { "\(Int($0))y" } ?? "—")")
                    .font(.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
                Text("\(club.sampleSize) shots")
                    .font(.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Theme.Color.textSecondary)
        }
        .padding(Theme.Layout.cardPadding)
        .background(Theme.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
    }

    private func colorForConfidence(_ confidence: ClubConfidence) -> Color {
        switch confidence {
        case .noData: return Theme.Color.textSecondary
        case .low: return Theme.Color.negative.opacity(0.7)
        case .moderate: return Color.orange
        case .high: return Theme.Color.greenPrimary
        }
    }
}

struct ClubDetailSheet: View {
    let summary: ClubSummary
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xxl) {
                    headerSection
                    distanceSection
                    dispersionSection
                }
                .padding(Theme.Layout.horizontalPadding)
                .padding(.bottom, Spacing.xxxl)
            }
            .background(Theme.Color.background)
            .navigationTitle(summary.clubName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.Color.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var headerSection: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Text(summary.clubName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Theme.Color.textPrimary)
                    Spacer()
                    FIQChip(text: summary.confidence.rawValue, color: confidenceColor)
                }
                Text(summary.consistencyRating)
                    .font(.subheadline)
                    .foregroundStyle(Theme.Color.textSecondary)
                Text(summary.trustLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(confidenceColor)
                Text("\(summary.sampleSize) shots recorded")
                    .font(.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
                if let tendency = summary.primaryMissTendency {
                    FIQChip(text: tendency, color: Theme.Color.negative, isOutline: true)
                }
            }
        }
    }

    private var distanceSection: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Distance")
                HStack(spacing: Spacing.md) {
                    StatTile(title: "Average", value: "\(Int(summary.averageDistance))y")
                    StatTile(title: "Median", value: "\(Int(summary.medianDistance))y")
                }
                HStack(spacing: Spacing.md) {
                    StatTile(title: "Carry", value: summary.carryDistanceEstimate.map { "\(Int($0))y" } ?? "—")
                    StatTile(title: "Total", value: summary.totalDistanceEstimate.map { "\(Int($0))y" } ?? "—")
                }
                HStack(spacing: Spacing.md) {
                    StatTile(title: "Min", value: "\(Int(summary.minDistance))y", valueColor: Theme.Color.textSecondary)
                    StatTile(title: "Max", value: "\(Int(summary.maxDistance))y", valueColor: Theme.Color.textSecondary)
                }
                HStack(spacing: Spacing.md) {
                    StatTile(title: "Range", value: "\(Int(summary.distanceRange))y")
                    StatTile(title: "Std Dev", value: String(format: "%.1f", summary.standardDeviation))
                }
            }
        }
    }

    private var dispersionSection: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Miss Pattern")
                if summary.totalMissCategorized == 0 {
                    Text("No miss data recorded. Add shot results during practice to see patterns.")
                        .font(.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                } else {
                    HStack(spacing: Spacing.md) {
                        StatTile(title: "Left", value: "\(summary.missLeftCount)", valueColor: Theme.Color.textSecondary)
                        StatTile(title: "Right", value: "\(summary.missRightCount)", valueColor: Theme.Color.textSecondary)
                        StatTile(title: "Short", value: "\(summary.missShortCount)", valueColor: Theme.Color.textSecondary)
                        StatTile(title: "Long", value: "\(summary.missLongCount)", valueColor: Theme.Color.textSecondary)
                    }
                    if let tendency = summary.primaryMissTendency {
                        Text(tendency)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.Color.negative)
                    }
                }
            }
        }
    }

    private var confidenceColor: Color {
        switch summary.confidence {
        case .noData: return Theme.Color.textSecondary
        case .low: return Theme.Color.negative
        case .moderate: return Color.orange
        case .high: return Theme.Color.positive
        }
    }
}
