//
//  HomeView.swift
//  FairwayIQ
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Round.date, order: .reverse) private var rounds: [Round]
    @Query private var profiles: [UserProfile]

    private var recentRound: Round? { rounds.first }
    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Layout.sectionSpacing) {
                    headerSection
                    quickStartCard
                    if let round = recentRound {
                        recentRoundCard(round)
                    }
                    handicapPreviewCard
                    leaderboardPreviewCard
                }
                .padding(Theme.Layout.horizontalPadding)
                .padding(.bottom, 32)
            }
            .background(Theme.Color.background)
            .navigationTitle("FairwayIQ")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let name = profile?.playerName, !name.isEmpty {
                Text("Welcome back, \(name)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Color.textPrimary)
            }
            Text("Ready to track your next round?")
                .font(.subheadline)
                .foregroundStyle(Theme.Color.textSecondary)
        }
        .padding(.top, 8)
    }

    private var quickStartCard: some View {
        NavigationLink {
            Text("Round setup — coming next")
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Theme.Color.greenPrimary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start New Round")
                        .font(.headline)
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text("Select course and tee off")
                        .font(.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            .padding(Theme.Layout.cardPadding)
            .background(Theme.Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
        }
        .buttonStyle(.plain)
    }

    private func recentRoundCard(_ round: Round) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Round")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Color.textSecondary)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(round.courseName)
                        .font(.headline)
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text(round.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(round.totalStrokes)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.Color.accent)
                    Text(round.scoreRelativeToPar >= 0 ? "+\(round.scoreRelativeToPar)" : "\(round.scoreRelativeToPar)")
                        .font(.caption)
                        .foregroundStyle(round.scoreRelativeToPar <= 0 ? Theme.Color.positive : Theme.Color.negative)
                }
            }
        }
        .padding(Theme.Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
    }

    private var handicapPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Handicap Trend")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Color.textSecondary)
            HStack(alignment: .bottom) {
                Text("\(profile?.handicapEstimate ?? 18, specifier: "%.1f")")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.Color.textPrimary)
                Text("index")
                    .font(.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .padding(.bottom, 6)
            }
            Text("Trend chart will appear here")
                .font(.caption)
                .foregroundStyle(Theme.Color.textSecondary)
        }
        .padding(Theme.Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
    }

    private var leaderboardPreviewCard: some View {
        NavigationLink {
            LeaderboardView()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Leaderboard")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.Color.textSecondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                Text("See how you stack up against friends")
                    .font(.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            .padding(Theme.Layout.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [UserProfile.self, Round.self, Course.self], inMemory: true)
}
