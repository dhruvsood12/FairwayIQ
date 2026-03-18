//
//  RoundSummaryView.swift
//  FairwayIQ
//

import SwiftUI
import SwiftData
import MapKit

struct RoundSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    var round: Round
    var onComplete: (() -> Void)?
    private var sortedScores: [HoleScore] {
        round.holeScores.sorted { $0.holeNumber < $1.holeNumber }
    }
    private var clubUsage: [(String, Int)] {
        let counts = Dictionary(grouping: round.shots, by: { $0.club }).mapValues { $0.count }
        return counts.sorted { $0.value > $1.value }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Layout.sectionSpacing) {
                headerCard
                scorecardSection
                statsCard
                if !round.shots.isEmpty {
                    shotMapSection
                    if !clubUsage.isEmpty {
                        clubUsageSection
                    }
                }
                Spacer(minLength: 80)
            }
            .padding(Theme.Layout.horizontalPadding)
        }
        .background(Theme.Color.background)
        .navigationTitle("Round Summary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    if let onComplete = onComplete {
                        onComplete()
                    } else {
                        dismiss()
                    }
                }
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Color.greenPrimary)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(round.courseName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Theme.Color.textPrimary)
            Text(round.date.formatted(date: .long, time: .omitted))
                .font(.subheadline)
                .foregroundStyle(Theme.Color.textSecondary)
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("\(round.totalStrokes)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(Theme.Color.accent)
                Text(round.scoreRelativeToPar >= 0 ? "+\(round.scoreRelativeToPar)" : "\(round.scoreRelativeToPar)")
                    .font(.title2)
                    .foregroundStyle(round.scoreRelativeToPar <= 0 ? Theme.Color.positive : Theme.Color.negative)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Layout.cardPadding)
        .background(Theme.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
    }

    private var scorecardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scorecard")
                .font(.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 8) {
                Text("Hole").font(.caption).fontWeight(.semibold).foregroundStyle(Theme.Color.textSecondary)
                Text("Par").font(.caption).fontWeight(.semibold).foregroundStyle(Theme.Color.textSecondary)
                Text("Score").font(.caption).fontWeight(.semibold).foregroundStyle(Theme.Color.textSecondary)
                Text("Putts").font(.caption).fontWeight(.semibold).foregroundStyle(Theme.Color.textSecondary)
                Text("+/-").font(.caption).fontWeight(.semibold).foregroundStyle(Theme.Color.textSecondary)
                ForEach(Array(sortedScores.enumerated()), id: \.element.holeNumber) { _, s in
                    let par = parForHole(s.holeNumber)
                    let diff = s.strokes - par
                    Text("\(s.holeNumber)").font(.caption).foregroundStyle(Theme.Color.textPrimary)
                    Text("\(par)").font(.caption).foregroundStyle(Theme.Color.textSecondary)
                    Text("\(s.strokes)").font(.caption).foregroundStyle(Theme.Color.textPrimary)
                    Text("\(s.putts)").font(.caption).foregroundStyle(Theme.Color.textSecondary)
                    Text(diff > 0 ? "+\(diff)" : "\(diff)")
                        .font(.caption)
                        .foregroundStyle(diff <= 0 ? Theme.Color.positive : Theme.Color.negative)
                }
            }
        }
        .padding(Theme.Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stats")
                .font(.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            HStack(spacing: 16) {
                statBlock(title: "Fairways", value: "\(round.fairwaysHit)/\(round.fairwaysPossible)")
                statBlock(title: "GIR", value: "\(round.girsHit)/\(max(1, round.holeScores.count))")
                statBlock(title: "Putts", value: "\(round.totalPutts)")
                statBlock(title: "Penalties", value: "\(round.holeScores.reduce(0) { $0 + $1.penalties })")
            }
        }
        .padding(Theme.Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
    }

    private func statBlock(title: String, value: String) -> some View {
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

    private var shotMapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shot Map")
                .font(.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            ShotMapView(shots: round.shots)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
        }
    }

    private var clubUsageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Club usage")
                .font(.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            VStack(spacing: 8) {
                ForEach(clubUsage, id: \.0) { club, count in
                    HStack {
                        Text(club)
                            .foregroundStyle(Theme.Color.textPrimary)
                        Spacer()
                        Text("\(count)")
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                    .padding(.vertical, 6)
                }
            }
            .padding(Theme.Layout.cardPadding)
            .background(Theme.Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
        }
    }

    private func parForHole(_ holeNumber: Int) -> Int {
        guard let course = round.course else { return 4 }
        return course.holes.first(where: { $0.number == holeNumber })?.par ?? 4
    }
}

#Preview {
    NavigationStack {
        RoundSummaryView(round: Round(courseNameSnapshot: "Preview", holeScores: (1...18).map { HoleScore(holeNumber: $0, strokes: 4, putts: 2) }))
    }
    .modelContainer(for: [Round.self], inMemory: true)
}
