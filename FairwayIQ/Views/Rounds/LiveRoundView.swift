//
//  LiveRoundView.swift
//  FairwayIQ
//

import SwiftUI
import SwiftData

struct LiveRoundView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let roundId: UUID
    var onRoundComplete: (() -> Void)?
    @Query private var rounds: [Round]
    @State private var currentHoleIndex = 0
    @State private var showShotEntry = false
    @State private var showSummary = false
    @State private var loadFailed = false

    private var round: Round? { rounds.first { $0.id == roundId } }
    private var holeCount: Int { round?.holeScores.count ?? round?.course?.holes.count ?? 18 }
    private var currentHoleNumber: Int { currentHoleIndex + 1 }
    private var par: Int {
        guard let course = round?.course else { return 4 }
        return course.holes.first(where: { $0.number == currentHoleNumber })?.par ?? 4
    }
    private var isPar3: Bool { par == 3 }
    private var currentScore: HoleScore? {
        round?.holeScores.first { $0.holeNumber == currentHoleNumber }
    }
    private var isLastHole: Bool { currentHoleIndex == holeCount - 1 }

    var body: some View {
        Group {
            if let round = round {
                if showSummary {
                    RoundSummaryView(round: round, onComplete: onRoundComplete)
                } else {
                    liveContent(round: round)
                }
            } else {
                if loadFailed {
                    VStack(spacing: 12) {
                        Text("Couldn’t load this round.")
                            .font(.headline)
                            .foregroundStyle(Theme.Color.textPrimary)
                        Button("Close") { dismiss() }
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.Color.background)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 12)
                            .background(Theme.Color.greenPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.Color.background)
                } else {
                    ProgressView("Loading round…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Theme.Color.background)
                        .onAppear {
                            // If the round isn't in the store, don't soft-lock the user here.
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                if round == nil { loadFailed = true }
                            }
                        }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                HStack(spacing: 12) {
                    Button("Exit") { dismiss() }
                        .foregroundStyle(Theme.Color.textSecondary)
                    Text("Hole \(currentHoleNumber)/\(holeCount)")
                        .font(.headline)
                        .foregroundStyle(Theme.Color.textPrimary)
                }
            }
        }
        .sheet(isPresented: $showShotEntry) {
            if let round = round {
                ShotEntryView(round: round, holeNumber: currentHoleNumber) {
                    showShotEntry = false
                }
            }
        }
    }

    private func liveContent(round: Round) -> some View {
        holeEntryView(round: round)
    }

    private func holeEntryView(round: Round) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Layout.sectionSpacing) {
                courseHeader(round: round)
                parCard
                if let score = currentScore {
                    scoreEntryCard(score)
                    statsTogglesCard(score)
                }
                addShotButton
                Spacer(minLength: 100)
            }
            .padding(Theme.Layout.horizontalPadding)
        }
        .background(Theme.Color.background)
        .safeAreaInset(edge: .bottom) {
            saveHoleButton(round: round)
        }
    }

    private func courseHeader(round: Round) -> some View {
        Text(round.courseName)
            .font(.subheadline)
            .foregroundStyle(Theme.Color.textSecondary)
            .padding(.top, 8)
    }

    private var parCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Par \(par)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.Color.greenPrimary)
                Text("Hole \(currentHoleNumber)")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            Spacer()
        }
        .padding(Theme.Layout.cardPadding)
        .background(Theme.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
    }

    private func scoreEntryCard(_ score: HoleScore) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Score")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Color.textSecondary)
            HStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Strokes")
                        .font(.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                    Stepper("\(score.strokes)", value: Binding(
                        get: { score.strokes },
                        set: { score.strokes = max(0, $0) }
                    ), in: 0...20)
                    .labelsHidden()
                    Text("\(score.strokes)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.Color.textPrimary)
                        .frame(width: 44)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 8) {
                    Text("Putts")
                        .font(.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                    Stepper("\(score.putts)", value: Binding(
                        get: { score.putts },
                        set: { score.putts = max(0, min(score.strokes, $0)) }
                    ), in: 0...10)
                    .labelsHidden()
                    Text("\(score.putts)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.Color.textPrimary)
                        .frame(width: 44)
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 8) {
                    Text("Penalties")
                        .font(.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                    Stepper("\(score.penalties)", value: Binding(
                        get: { score.penalties },
                        set: { score.penalties = max(0, $0) }
                    ), in: 0...5)
                    .labelsHidden()
                    Text("\(score.penalties)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.Color.textPrimary)
                        .frame(width: 44)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(Theme.Layout.cardPadding)
        .background(Theme.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
    }

    private func statsTogglesCard(_ score: HoleScore) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stats")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Color.textSecondary)
            if !isPar3 {
                Toggle(isOn: Binding(
                    get: { score.fairwayHit ?? false },
                    set: { score.fairwayHit = $0 }
                )) {
                    Text("Fairway hit")
                        .foregroundStyle(Theme.Color.textPrimary)
                }
                .tint(Theme.Color.greenPrimary)
            }
            Toggle(isOn: Binding(
                get: { score.gir },
                set: { score.gir = $0 }
            )) {
                Text("Green in regulation")
                    .foregroundStyle(Theme.Color.textPrimary)
            }
            .tint(Theme.Color.greenPrimary)
        }
        .padding(Theme.Layout.cardPadding)
        .background(Theme.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
    }

    private var addShotButton: some View {
        Button {
            showShotEntry = true
        } label: {
            HStack {
                Image(systemName: "location.fill")
                Text("Add shot location")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Theme.Color.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.Color.greenMuted.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
        }
        .buttonStyle(.plain)
    }

    private func saveHoleButton(round: Round) -> some View {
        Button {
            saveHoleAndAdvance(round: round)
        } label: {
            Text(isLastHole ? "Finish Round" : "Save & Next Hole")
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Color.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.Color.greenPrimary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Theme.Layout.horizontalPadding)
        .padding(.vertical, 12)
        .background(Theme.Color.background)
    }

    private func saveHoleAndAdvance(round: Round) {
        try? modelContext.save()
        if isLastHole {
            showSummary = true
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentHoleIndex += 1
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Round.self, HoleScore.self, configurations: config)
    let round = Round(courseNameSnapshot: "Preview Course", holeScores: (1...18).map { HoleScore(holeNumber: $0, strokes: 4) })
    container.mainContext.insert(round)
    return NavigationStack {
        LiveRoundView(roundId: round.id)
    }
    .modelContainer(container)
}
