import SwiftUI

struct PracticeSessionDetailView: View {
    let session: PracticeSession

    private var sortedShots: [PracticeShot] {
        session.shots.sorted { $0.timestamp < $1.timestamp }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xxl) {
                headerCard
                if !sortedShots.isEmpty {
                    statsCard
                    shotsListCard
                }
                if let notes = session.notes, !notes.isEmpty {
                    notesCard(notes)
                }
            }
            .padding(Theme.Layout.horizontalPadding)
            .padding(.bottom, Spacing.xxxl)
        }
        .background(Theme.Color.background)
        .navigationTitle("Practice Session")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Image(systemName: PracticeSessionType(rawValue: session.sessionType)?.icon ?? "figure.golf")
                        .font(.title2)
                        .foregroundStyle(Theme.Color.greenPrimary)
                    Text(session.sessionType)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.Color.textPrimary)
                }
                Text(session.date.formatted(date: .long, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(Theme.Color.textSecondary)
                HStack(spacing: Spacing.lg) {
                    StatTile(title: "Shots", value: "\(session.shotCount)")
                    if let avg = session.averageDistance {
                        StatTile(title: "Avg Distance", value: "\(Int(avg))y")
                    }
                    StatTile(title: "Clubs Used", value: "\(session.clubsUsed.count)")
                }
                .padding(.top, Spacing.sm)
            }
        }
    }

    private var statsCard: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Club Breakdown")
                let clubGroups = Dictionary(grouping: sortedShots, by: \.club)
                ForEach(clubGroups.sorted(by: { $0.key < $1.key }), id: \.key) { club, clubShots in
                    let distances = clubShots.compactMap(\.distanceYards)
                    HStack {
                        Text(club)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.Color.textPrimary)
                        Spacer()
                        Text("\(clubShots.count) shots")
                            .font(.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                        if !distances.isEmpty {
                            Text("\(Int(distances.reduce(0, +) / Double(distances.count)))y avg")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.Color.accent)
                                .frame(width: 60, alignment: .trailing)
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                }
            }
        }
    }

    private var shotsListCard: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "All Shots")
                ForEach(sortedShots) { shot in
                    HStack(spacing: Spacing.md) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(shot.club)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Theme.Color.textPrimary)
                            HStack(spacing: Spacing.xs) {
                                Text(shot.lie)
                                    .font(.caption)
                                    .foregroundStyle(Theme.Color.textSecondary)
                                if let result = shot.result {
                                    Text("• \(result)")
                                        .font(.caption)
                                        .foregroundStyle(Theme.Color.textSecondary)
                                }
                            }
                        }
                        Spacer()
                        if let dist = shot.distanceYards {
                            Text("\(Int(dist))y")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.Color.accent)
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                    if shot.id != sortedShots.last?.id {
                        Divider().overlay(Theme.Color.backgroundSecondary)
                    }
                }
            }
        }
    }

    private func notesCard(_ notes: String) -> some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeader(title: "Notes")
                Text(notes)
                    .font(.subheadline)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
        }
    }
}
