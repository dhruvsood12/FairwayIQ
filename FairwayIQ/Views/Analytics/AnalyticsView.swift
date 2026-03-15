//
//  AnalyticsView.swift
//  FairwayIQ
//

import SwiftUI
import SwiftData

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Round.date, order: .reverse) private var rounds: [Round]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Layout.sectionSpacing) {
                    handicapSection
                    scoringSection
                    statsSection
                }
                .padding(Theme.Layout.horizontalPadding)
                .padding(.bottom, 32)
            }
            .background(Theme.Color.background)
            .navigationTitle("Analytics")
        }
    }

    private var handicapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Handicap Trend")
                .font(.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            Text("Charts will display here with Swift Charts")
                .font(.subheadline)
                .foregroundStyle(Theme.Color.textSecondary)
        }
        .padding(Theme.Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
    }

    private var scoringSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Average Score")
                .font(.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            let avg = rounds.isEmpty ? 0 : Double(rounds.map(\.totalStrokes).reduce(0, +)) / Double(rounds.count)
            Text(String(format: "%.1f", avg))
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Theme.Color.accent)
        }
        .padding(Theme.Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Stats")
                .font(.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            Text("Fairways • GIR • Putts — coming with charts")
                .font(.subheadline)
                .foregroundStyle(Theme.Color.textSecondary)
        }
        .padding(Theme.Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: [Round.self], inMemory: true)
}
