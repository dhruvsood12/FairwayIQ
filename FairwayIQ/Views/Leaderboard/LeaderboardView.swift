//
//  LeaderboardView.swift
//  FairwayIQ
//

import SwiftUI
import SwiftData

struct LeaderboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FriendEntry.sortOrder) private var friends: [FriendEntry]

    var body: some View {
        NavigationStack {
            Group {
                if friends.isEmpty {
                    emptyState
                } else {
                    leaderboardList
                }
            }
            .background(Theme.Color.background)
            .navigationTitle("Leaderboard")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.Color.textSecondary)
            Text("No friends yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Color.textPrimary)
            Text("Mock leaderboard will show here with sample data.")
                .font(.subheadline)
                .foregroundStyle(Theme.Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var leaderboardList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(friends.enumerated()), id: \.element.id) { index, friend in
                    HStack(spacing: 16) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundStyle(Theme.Color.textSecondary)
                            .frame(width: 28, alignment: .center)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(friend.displayName)
                                .font(.headline)
                                .foregroundStyle(Theme.Color.textPrimary)
                            if let avg = friend.averageScore {
                                Text("Avg: \(String(format: "%.1f", avg))")
                                    .font(.caption)
                                    .foregroundStyle(Theme.Color.textSecondary)
                            }
                        }
                        Spacer()
                        if let best = friend.weeklyBestScore {
                            Text("\(best)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(Theme.Color.accent)
                        }
                    }
                    .padding(Theme.Layout.cardPadding)
                    .background(Theme.Color.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
                }
            }
            .padding(Theme.Layout.horizontalPadding)
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    LeaderboardView()
        .modelContainer(for: [FriendEntry.self], inMemory: true)
}
