import SwiftData
import SwiftUI

struct SmartCaddieView: View {
    @Environment(SessionStore.self) private var session
    @Query(sort: \Round.date, order: .reverse) private var rounds: [Round]
    @Query(sort: \PracticeSession.date, order: .reverse) private var practiceSessions: [PracticeSession]
    @Query(sort: \Course.name, order: .forward) private var courses: [Course]
    @Query private var profiles: [UserProfile]

    @State private var selectedCourse: Course?
    @State private var selectedHoleIndex = 0
    @State private var strategyMode: StrategyMode = .standard

    private var profile: UserProfile? {
        session.resolvedProfile(in: profiles)
    }

    private var scopedRounds: [Round] {
        session.roundsForCurrentProfile(rounds, profiles: profiles)
    }

    private var scopedPracticeSessions: [PracticeSession] {
        session.practiceSessionsForCurrentProfile(practiceSessions, profiles: profiles)
    }

    private var availableCourses: [Course] {
        courses.filter { !$0.holes.isEmpty }
    }

    private var safestTeeOption: ClubSummary? {
        clubSummaries
            .filter { $0.sampleSize >= 5 && $0.missLeftCount + $0.missRightCount <= max(1, $0.sampleSize / 3) }
            .max(by: { $0.averageDistance < $1.averageDistance })
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
        ClubGappingEngine.computeClubSummaries(shots: allShotRecords)
    }

    private var missTendencies: [MissTendency] {
        let allHoleScores = scopedRounds.flatMap(\.holeScores)
        return StrategyEngine.detectMissTendencies(
            shots: allShotRecords,
            holeScores: allHoleScores,
            rounds: scopedRounds
        )
    }

    private var selectedHole: HoleInfo? {
        guard let course = selectedCourse else { return nil }
        let holes = course.holes.sorted { $0.number < $1.number }
        guard selectedHoleIndex < holes.count else { return nil }
        let hole = holes[selectedHoleIndex]
        return HoleInfo(number: hole.number, par: hole.par, yardage: hole.yardage)
    }

    private var recommendation: StrategyRecommendation? {
        guard let hole = selectedHole else { return nil }
        return StrategyEngine.recommend(
            hole: hole,
            clubSummaries: clubSummaries,
            missTendencies: missTendencies,
            mode: strategyMode
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xxl) {
                courseSelector
                if let safestTeeOption {
                    safestTeeCard(club: safestTeeOption)
                }
                if selectedCourse != nil {
                    modeSelector
                    holeSelector
                    if let rec = recommendation {
                        recommendationCard(rec)
                    }
                }
                if !missTendencies.isEmpty {
                    tendenciesSection
                }
                if clubSummaries.isEmpty {
                    dataWarning
                }
            }
            .padding(Theme.Layout.horizontalPadding)
            .padding(.bottom, Spacing.xxxl)
        }
        .background(Theme.Color.background)
        .navigationTitle("Smart Caddie")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selectedCourse == nil {
                selectedCourse = profile?.homeCourse ?? scopedRounds.first?.course ?? availableCourses.first
            }
            strategyMode = .standard
        }
    }

    private var courseSelector: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeader(title: "Course", eyebrow: "Plan ahead")
                Picker("Course", selection: $selectedCourse) {
                    Text("Select course").tag(Course?.none)
                    ForEach(availableCourses, id: \.id) { course in
                        Text(course.name).tag(Course?.some(course))
                    }
                }
                .pickerStyle(.menu)
                if let course = selectedCourse, let loc = course.locationName {
                    Text(loc)
                        .font(.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
        }
    }

    private func safestTeeCard(club: ClubSummary) -> some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeader(title: "Safest Tee Option", eyebrow: "Player tendency")
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(club.clubName)
                            .font(.headline)
                            .foregroundStyle(Theme.Color.textPrimary)
                        Text("Your longest club with the cleanest left/right miss profile.")
                            .font(.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                    Spacer()
                    Text("\(Int(club.averageDistance))y")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.Color.accent)
                }
            }
        }
    }

    private var modeSelector: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Strategy Mode", eyebrow: "Decision style")
                HStack(spacing: Spacing.sm) {
                    ForEach(StrategyMode.allCases) { mode in
                        Button {
                            withAnimation { strategyMode = mode }
                        } label: {
                            VStack(spacing: Spacing.xs) {
                                Image(systemName: mode.icon)
                                    .font(.title3)
                                Text(mode.rawValue)
                                    .font(.caption.weight(.medium))
                            }
                            .foregroundStyle(strategyMode == mode ? Theme.Color.background : Theme.Color.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(strategyMode == mode ? Theme.Color.greenPrimary : Theme.Color.backgroundSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadiusSmall))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var holeSelector: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Hole", eyebrow: "Preview")
                let holes = selectedCourse?.holes.sorted { $0.number < $1.number } ?? []
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(holes.indices, id: \.self) { idx in
                            Button {
                                withAnimation { selectedHoleIndex = idx }
                            } label: {
                                VStack(spacing: 2) {
                                    Text("\(holes[idx].number)")
                                        .font(.headline)
                                    Text("P\(holes[idx].par)")
                                        .font(.caption2)
                                }
                                .foregroundStyle(selectedHoleIndex == idx ? Theme.Color.background : Theme.Color.textPrimary)
                                .frame(width: 40, height: 50)
                                .background(selectedHoleIndex == idx ? Theme.Color.greenPrimary : Theme.Color.backgroundSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func recommendationCard(_ rec: StrategyRecommendation) -> some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title3)
                        .foregroundStyle(Theme.Color.greenPrimary)
                    Text("Recommendation")
                        .font(.headline)
                        .foregroundStyle(Theme.Color.textPrimary)
                }

                Text(rec.overallAdvice)
                    .font(.subheadline)
                    .foregroundStyle(Theme.Color.textSecondary)

                FIQChip(text: rec.confidenceSummary, color: Theme.Color.accent, isOutline: true)

                if let tee = rec.teeSuggestion {
                    clubRecRow(title: "Off the tee", rec: tee)
                }
                if let approach = rec.approachSuggestion {
                    clubRecRow(title: "Approach", rec: approach)
                }

                if !rec.warnings.isEmpty {
                    ForEach(rec.warnings, id: \.self) { warning in
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Text(warning)
                                .font(.caption)
                                .foregroundStyle(Theme.Color.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private func clubRecRow(title: String, rec: ClubRecommendation) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.Color.textSecondary)
                Spacer()
                ConfidenceIndicator(confidence: rec.confidence)
            }
            HStack {
                Text(rec.club)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.Color.accent)
                if let dist = rec.expectedDistance {
                    Text("~\(Int(dist))y")
                        .font(.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
            Text(rec.rationale)
                .font(.caption)
                .foregroundStyle(Theme.Color.textSecondary)
        }
        .padding(Spacing.md)
        .background(Theme.Color.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadiusSmall))
    }

    private var tendenciesSection: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Your Miss Tendencies", eyebrow: "Rules-based")
                ForEach(missTendencies) { tendency in
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Text(tendency.category)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.Color.textSecondary)
                            Spacer()
                            FIQChip(text: tendency.severity.rawValue, color: severityColor(tendency.severity))
                        }
                        Text(tendency.description)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Theme.Color.textPrimary)
                        Text(tendency.evidence)
                            .font(.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                    .padding(.vertical, Spacing.xs)
                }
            }
        }
    }

    private var dataWarning: some View {
        FIQCard {
            HStack(spacing: Spacing.md) {
                Image(systemName: "info.circle")
                    .foregroundStyle(Theme.Color.textSecondary)
                Text("Log more shots during rounds or practice to unlock better strategy confidence.")
                    .font(.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
        }
    }

    private func severityColor(_ severity: TendencySeverity) -> Color {
        switch severity {
        case .mild: return .yellow
        case .moderate: return .orange
        case .significant: return Theme.Color.negative
        }
    }
}
