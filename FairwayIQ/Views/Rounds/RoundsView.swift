//
//  RoundsView.swift
//  FairwayIQ
//

import SwiftUI
import SwiftData

struct RoundsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Round.date, order: .reverse) private var rounds: [Round]
    @State private var showRoundSetup = false

    var body: some View {
        NavigationStack {
            Group {
                if rounds.isEmpty {
                    emptyState
                } else {
                    roundsList
                }
            }
            .background(Theme.Color.background)
            .navigationTitle("Rounds")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showRoundSetup = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Theme.Color.accent)
                    }
                }
            }
            .sheet(isPresented: $showRoundSetup) {
                RoundSetupView(onDismiss: { showRoundSetup = false })
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "flag.fill")
                .font(.system(size: 48))
                .foregroundStyle(Theme.Color.textSecondary)
            Text("No rounds yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Color.textPrimary)
            Text("Start a round to see your history here.")
                .font(.subheadline)
                .foregroundStyle(Theme.Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var roundsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(rounds, id: \.id) { round in
                    NavigationLink {
                        RoundSummaryView(round: round)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(round.courseName)
                                    .font(.headline)
                                    .foregroundStyle(Theme.Color.textPrimary)
                                Text(round.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(Theme.Color.textSecondary)
                            }
                            Spacer()
                            Text("\(round.totalStrokes)")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(Theme.Color.accent)
                        }
                        .padding(Theme.Layout.cardPadding)
                        .background(Theme.Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.Layout.horizontalPadding)
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    RoundsView()
        .modelContainer(for: [Round.self], inMemory: true)
}
