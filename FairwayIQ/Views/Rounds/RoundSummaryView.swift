import MapKit
import SwiftData
import SwiftUI

struct RoundSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var session
    @Query(sort: \Round.date, order: .reverse) private var allRounds: [Round]
    @Query private var profiles: [UserProfile]
    var round: Round
    var onComplete: (() -> Void)?

    @State private var showShareSheet = false
    @State private var exportText = ""

    private var sortedScores: [HoleScore] {
        round.holeScores.sorted { $0.holeNumber < $1.holeNumber }
    }

    private var clubUsage: [(String, Int)] {
        let counts = Dictionary(grouping: round.shots, by: { $0.club }).mapValues { $0.count }
        return counts.sorted { $0.value > $1.value }
    }

    private var scopedRounds: [Round] {
        session.roundsForCurrentProfile(allRounds, profiles: profiles)
    }

    private var coaching: CoachingSummary {
        let otherRounds = scopedRounds.filter { $0.id != round.id }
        let baseline = CoachingEngine.computeBaseline(from: Array(otherRounds.prefix(10)))
        return CoachingEngine.analyze(round: round, baseline: baseline)
    }

    private var stretchInsights: (best: RoundStretchInsight?, worst: RoundStretchInsight?) {
        PerformanceInsights.bestAndWorstStretch(for: round)
    }

    private var baselineComparison: BaselineComparison? {
        PerformanceInsights.baselineComparison(for: round, against: Array(scopedRounds.filter { $0.id != round.id }.prefix(5)))
    }

    private var frontNineScores: [HoleScore] {
        sortedScores.filter { $0.holeNumber <= 9 }
    }

    private var backNineScores: [HoleScore] {
        sortedScores.filter { $0.holeNumber > 9 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xxl) {
                headerCard
                splitCard
                scorecardSection
                statsCard
                if stretchInsights.best != nil || stretchInsights.worst != nil || baselineComparison != nil {
                    stretchSection
                }
                coachingSection
                if !round.shots.isEmpty {
                    shotMapSection
                    if !clubUsage.isEmpty {
                        clubUsageSection
                    }
                }
                exportButton
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
                    if let onComplete { onComplete() } else { dismiss() }
                }
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Color.greenPrimary)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(text: exportText)
        }
    }

    // MARK: - Header

    private var headerCard: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text(round.courseName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.Color.textPrimary)
                Text(round.date.formatted(date: .long, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(Theme.Color.textSecondary)
                HStack(alignment: .lastTextBaseline, spacing: Spacing.sm) {
                    Text("\(round.totalStrokes)")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(Theme.Color.accent)
                    let diff = round.scoreRelativeToPar
                    Text(diff >= 0 ? "+\(diff)" : "\(diff)")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(diff <= 0 ? Theme.Color.positive : Theme.Color.negative)
                    Spacer()
                    Text(coaching.overallAssessment)
                        .font(.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 160)
                }
            }
        }
    }

    // MARK: - Front/Back Split

    private var splitCard: some View {
        FIQCard {
            HStack(spacing: Spacing.md) {
                VStack(spacing: Spacing.xs) {
                    Text("Front 9")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.Color.textSecondary)
                    Text("\(frontNineScores.reduce(0) { $0 + $1.strokes })")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.Color.accent)
                }
                .frame(maxWidth: .infinity)
                Divider().frame(height: 30).overlay(Theme.Color.backgroundSecondary)
                VStack(spacing: Spacing.xs) {
                    Text("Back 9")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.Color.textSecondary)
                    Text("\(backNineScores.reduce(0) { $0 + $1.strokes })")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.Color.accent)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var stretchSection: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Round Pattern", eyebrow: "Context")
                if let baselineComparison {
                    HStack {
                        FIQChip(text: baselineComparison.deltaText, color: baselineComparison.isPositive ? Theme.Color.positive : Theme.Color.negative)
                        Text(baselineComparison.detail)
                            .font(.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                }
                if let best = stretchInsights.best {
                    HStack {
                        Text(best.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.Color.textPrimary)
                        Spacer()
                        Text(best.holesText)
                            .font(.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                        Text(best.relativeToPar > 0 ? "+\(best.relativeToPar)" : "\(best.relativeToPar)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.Color.positive)
                    }
                }
                if let worst = stretchInsights.worst {
                    HStack {
                        Text(worst.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.Color.textPrimary)
                        Spacer()
                        Text(worst.holesText)
                            .font(.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                        Text("+\(worst.relativeToPar)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.Color.negative)
                    }
                }
            }
        }
    }

    // MARK: - Scorecard

    private var scorecardSection: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Scorecard")
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 6) {
                    Text("Hole").font(.caption2.weight(.semibold)).foregroundStyle(Theme.Color.textSecondary)
                    Text("Par").font(.caption2.weight(.semibold)).foregroundStyle(Theme.Color.textSecondary)
                    Text("Score").font(.caption2.weight(.semibold)).foregroundStyle(Theme.Color.textSecondary)
                    Text("Putts").font(.caption2.weight(.semibold)).foregroundStyle(Theme.Color.textSecondary)
                    Text("+/-").font(.caption2.weight(.semibold)).foregroundStyle(Theme.Color.textSecondary)
                    ForEach(sortedScores, id: \.holeNumber) { holeScore in
                        let par = parForHole(holeScore.holeNumber)
                        let diff = holeScore.strokes - par
                        Text("\(holeScore.holeNumber)").font(.caption).foregroundStyle(Theme.Color.textPrimary)
                        Text("\(par)").font(.caption).foregroundStyle(Theme.Color.textSecondary)
                        Text("\(holeScore.strokes)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(scoreColor(diff))
                        Text("\(holeScore.putts)").font(.caption).foregroundStyle(Theme.Color.textSecondary)
                        Text(diff > 0 ? "+\(diff)" : "\(diff)")
                            .font(.caption)
                            .foregroundStyle(diff <= 0 ? Theme.Color.positive : Theme.Color.negative)
                    }
                }
            }
        }
    }

    private func scoreColor(_ diff: Int) -> Color {
        switch diff {
        case ...(-2): return Color.yellow
        case -1: return Theme.Color.positive
        case 0: return Theme.Color.textPrimary
        case 1: return Theme.Color.negative.opacity(0.8)
        default: return Theme.Color.negative
        }
    }

    // MARK: - Stats

    private var statsCard: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Stats")
                HStack(spacing: Spacing.md) {
                    StatTile(title: "Fairways", value: "\(round.fairwaysHit)/\(round.fairwaysPossible)")
                    StatTile(title: "GIR", value: "\(round.girsHit)/\(round.holeScores.count)")
                    StatTile(title: "Putts", value: "\(round.totalPutts)")
                    StatTile(title: "Penalties", value: "\(round.holeScores.reduce(0) { $0 + $1.penalties })")
                }
            }
        }
    }

    // MARK: - Coaching

    private var coachingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if !coaching.strengths.isEmpty {
                FIQCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        SectionHeader(title: "What Went Well")
                        ForEach(coaching.strengths) { insight in
                            insightRow(insight, isPositive: true)
                        }
                    }
                }
            }

            if !coaching.weaknesses.isEmpty {
                FIQCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        SectionHeader(title: "What Cost You Strokes")
                        ForEach(coaching.weaknesses) { insight in
                            insightRow(insight, isPositive: false)
                        }
                    }
                }
            }

            if !coaching.strokeCostBreakdown.isEmpty {
                FIQCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        SectionHeader(title: "Stroke Cost Breakdown")
                        ForEach(coaching.strokeCostBreakdown) { cost in
                            HStack {
                                Text(cost.category)
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.Color.textPrimary)
                                Spacer()
                                Text(String(format: "+%.1f", cost.estimatedStrokesLost))
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(Theme.Color.negative)
                            }
                        }
                    }
                }
            }

            if !coaching.actionItems.isEmpty {
                FIQCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        SectionHeader(title: "Action Items")
                        ForEach(coaching.actionItems, id: \.self) { item in
                            HStack(alignment: .top, spacing: Spacing.sm) {
                                Image(systemName: "checkmark.circle")
                                    .font(.caption)
                                    .foregroundStyle(Theme.Color.accent)
                                Text(item)
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.Color.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private func insightRow(_ insight: CoachingInsight, isPositive: Bool) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: isPositive ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .foregroundStyle(isPositive ? Theme.Color.positive : Theme.Color.negative)
                .font(.subheadline)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack {
                    Text(insight.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.Color.textPrimary)
                    if let metric = insight.metric {
                        Spacer()
                        FIQChip(text: metric, color: isPositive ? Theme.Color.positive : Theme.Color.negative)
                    }
                }
                Text(insight.detail)
                    .font(.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
        }
    }

    // MARK: - Shot Map

    private var shotMapSection: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Shot Map")
                ShotMapView(shots: round.shots)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadiusSmall))
            }
        }
    }

    // MARK: - Club Usage

    private var clubUsageSection: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Club Usage")
                ForEach(clubUsage, id: \.0) { club, count in
                    HStack {
                        Text(club)
                            .font(.subheadline)
                            .foregroundStyle(Theme.Color.textPrimary)
                        Spacer()
                        Text("\(count)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.Color.accent)
                    }
                }
            }
        }
    }

    // MARK: - Export

    private var exportButton: some View {
        Button {
            let export = ExportManager.buildRoundExport(
                round: round,
                coaching: coaching
            )
            exportText = ExportManager.roundSummaryText(summary: export)
            showShareSheet = true
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Share Round Summary")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.Color.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .background(Theme.Color.greenMuted.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
        }
        .buttonStyle(.plain)
    }

    private func parForHole(_ holeNumber: Int) -> Int {
        round.course?.holes.first(where: { $0.number == holeNumber })?.par ?? 4
    }
}

struct ShareSheet: View {
    let text: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(text)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Theme.Color.textPrimary)
                    .padding(Theme.Layout.horizontalPadding)
                    .textSelection(.enabled)
            }
            .background(Theme.Color.background)
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.Color.accent)
                }
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: text) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Theme.Color.accent)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    NavigationStack {
        RoundSummaryView(round: Round(courseNameSnapshot: "Preview", holeScores: (1 ... 18).map { HoleScore(holeNumber: $0, strokes: 4, putts: 2) }))
    }
    .modelContainer(for: [Round.self], inMemory: true)
    .environment(SessionStore())
}
