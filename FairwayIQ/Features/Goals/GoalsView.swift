import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SessionStore.self) private var session
    @Query(sort: \Round.date, order: .reverse) private var rounds: [Round]
    @Query(sort: \PlayerGoal.createdAt, order: .reverse) private var goals: [PlayerGoal]
    @Query private var profiles: [UserProfile]
    @State private var showAddGoal = false

    private var profile: UserProfile? { session.resolvedProfile(in: profiles) }
    private var scopedRounds: [Round] { session.roundsForCurrentProfile(rounds, profiles: profiles) }
    private var scopedGoals: [PlayerGoal] { session.goalsForCurrentProfile(goals, profiles: profiles) }
    private var recentRounds: [Round] { Array(scopedRounds.prefix(5)) }
    private var previousRounds: [Round] { Array(scopedRounds.dropFirst(5).prefix(5)) }

    private var goalProgress: [GoalProgress] {
        GoalEngine.evaluateProgress(
            goals: scopedGoals,
            recentRounds: Array(scopedRounds.prefix(10)),
            allRounds: scopedRounds
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xxl) {
                if goalProgress.isEmpty {
                    EmptyStateView(
                        icon: "target",
                        title: "No Goals Set",
                        message: "Set measurable goals to track your improvement and stay motivated.",
                        actionTitle: "Add Goal",
                        onAction: { showAddGoal = true }
                    )
                } else {
                    progressOverview
                    if let improvementInsight = PerformanceInsights.mostImprovedMetric(recentRounds: recentRounds, previousRounds: previousRounds) {
                        improvementCard(improvementInsight)
                    }
                    goalsList
                }
            }
            .padding(Theme.Layout.horizontalPadding)
            .padding(.bottom, Spacing.xxxl)
        }
        .background(Theme.Color.background)
        .navigationTitle("Goals")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddGoal = true } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.Color.accent)
                }
            }
        }
        .sheet(isPresented: $showAddGoal) {
            AddGoalView(onDismiss: { showAddGoal = false })
        }
    }

    private var progressOverview: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Progress Overview", eyebrow: "Goals")
                let achieved = goalProgress.filter(\.isAchieved).count
                let total = goalProgress.count
                HStack(spacing: Spacing.lg) {
                    ProgressRing(
                        progress: total > 0 ? Double(achieved) / Double(total) : 0,
                        size: 56,
                        lineWidth: 5
                    )
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("\(achieved) of \(total) achieved")
                            .font(.headline)
                            .foregroundStyle(Theme.Color.textPrimary)
                        let improving = goalProgress.filter { $0.trend == .improving }.count
                        if improving > 0 {
                            Text("\(improving) goal\(improving > 1 ? "s" : "") trending up")
                                .font(.caption)
                                .foregroundStyle(Theme.Color.positive)
                        }
                    }
                }
            }
        }
    }

    private func improvementCard(_ insight: RecentImprovementInsight) -> some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionHeader(title: "Most Improved Metric", eyebrow: "Last 5 rounds")
                Text(insight.metricName)
                    .font(.headline)
                    .foregroundStyle(Theme.Color.textPrimary)
                Text("\(insight.changeText) versus the prior five rounds")
                    .font(.subheadline)
                    .foregroundStyle(insight.isPositive ? Theme.Color.positive : Theme.Color.negative)
            }
        }
    }

    private var goalsList: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Your Goals")
            ForEach(goalProgress) { progress in
                goalCard(progress)
            }
        }
    }

    private func goalCard(_ progress: GoalProgress) -> some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: GoalMetricType(rawValue: progress.goal.metricType)?.icon ?? "target")
                        .font(.title3)
                        .foregroundStyle(progress.isAchieved ? Theme.Color.positive : Theme.Color.accent)
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(progress.goal.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.Color.textPrimary)
                        Text(progress.statusLabel)
                            .font(.caption)
                            .foregroundStyle(progress.isAchieved ? Theme.Color.positive : Theme.Color.textSecondary)
                    }
                    Spacer()
                    trendIndicator(progress.trend)
                }

                HStack(spacing: Spacing.md) {
                    ProgressRing(
                        progress: progress.progressPercentage,
                        size: 36,
                        lineWidth: 3,
                        color: progress.isAchieved ? Theme.Color.positive : Theme.Color.accent
                    )
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        if let current = progress.currentValue {
                            Text("Current: \(formattedValue(current, metricType: progress.goal.metricType))")
                                .font(.caption)
                                .foregroundStyle(Theme.Color.textPrimary)
                        }
                        Text("Target: \(formattedValue(progress.goal.targetValue, metricType: progress.goal.metricType))")
                            .font(.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                    Spacer()
                    Text(String(format: "%.0f%%", progress.progressPercentage * 100))
                        .font(.headline)
                        .foregroundStyle(progress.isAchieved ? Theme.Color.positive : Theme.Color.accent)
                }

                if progress.trend == .noData {
                    Text("More rounds are needed before trend detection becomes reliable.")
                        .font(.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }

                // Delete button
                Button(role: .destructive) {
                    deleteGoal(progress.goal)
                } label: {
                    Text("Remove Goal")
                        .font(.caption)
                        .foregroundStyle(Theme.Color.negative.opacity(0.8))
                }
            }
        }
    }

    private func trendIndicator(_ trend: GoalTrend) -> some View {
        HStack(spacing: 2) {
            Image(systemName: trend.icon)
                .font(.caption2.weight(.bold))
            Text(trend.rawValue)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(trendColor(trend))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(trendColor(trend).opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func trendColor(_ trend: GoalTrend) -> Color {
        switch trend {
        case .improving: return Theme.Color.positive
        case .steady: return Theme.Color.textSecondary
        case .declining: return Theme.Color.negative
        case .noData: return Theme.Color.textSecondary
        }
    }

    private func formattedValue(_ value: Double, metricType: String) -> String {
        guard let type = GoalMetricType(rawValue: metricType) else {
            return String(format: "%.1f", value)
        }
        switch type {
        case .girPercentage, .fairwayPercentage:
            return String(format: "%.0f%%", value)
        case .averageScore, .bestScore:
            return String(format: "%.0f", value)
        default:
            return String(format: "%.1f", value)
        }
    }

    private func deleteGoal(_ goal: PlayerGoal) {
        modelContext.delete(goal)
        try? modelContext.save()
    }
}

struct AddGoalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SessionStore.self) private var session
    @Query private var profiles: [UserProfile]
    var onDismiss: () -> Void

    @State private var title = ""
    @State private var metricType: GoalMetricType = .averageScore
    @State private var targetValue: Double = 90
    @State private var validationError: String?

    private var profile: UserProfile? { session.resolvedProfile(in: profiles) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Name") {
                    TextField("e.g. Break 90", text: $title)
                }
                Section("Metric") {
                    Picker("Metric", selection: $metricType) {
                        ForEach(GoalMetricType.allCases) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                    .onChange(of: metricType) { _, newType in
                        targetValue = newType.defaultTarget
                        if title.isEmpty {
                            title = defaultTitle(for: newType)
                        }
                    }
                }
                Section("Target (\(metricType.unit))") {
                    HStack {
                        Slider(value: $targetValue, in: metricType.minValue...metricType.maxValue, step: 1)
                        Text(String(format: "%.0f", targetValue))
                            .font(.headline)
                            .foregroundStyle(Theme.Color.accent)
                            .frame(width: 44)
                    }
                }
                if let error = validationError {
                    Section {
                        Text(error)
                            .foregroundStyle(Theme.Color.negative)
                            .font(.caption)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Color.background)
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                        .foregroundStyle(Theme.Color.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveGoal() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.Color.greenPrimary)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func defaultTitle(for type: GoalMetricType) -> String {
        switch type {
        case .averageScore: return "Break \(Int(type.defaultTarget))"
        case .puttsPerRound: return "Under \(Int(type.defaultTarget)) putts"
        case .girPercentage: return "Hit \(Int(type.defaultTarget))% GIR"
        case .fairwayPercentage: return "Hit \(Int(type.defaultTarget))% fairways"
        case .penaltiesPerRound: return "Under \(Int(type.defaultTarget)) penalties"
        case .bestScore: return "Shoot \(Int(type.defaultTarget))"
        }
    }

    private func saveGoal() {
        let validation = InputValidation.validateGoalTarget(targetValue, metricType: metricType)
        guard validation.isValid else {
            validationError = validation.errorMessage
            return
        }

        let goal = PlayerGoal(
            title: title.trimmingCharacters(in: .whitespaces),
            metricType: metricType.rawValue,
            targetValue: targetValue,
            comparisonDirection: metricType.defaultDirection,
            player: profile
        )
        modelContext.insert(goal)
        do {
            try modelContext.save()
            onDismiss()
        } catch {
            validationError = "Failed to save goal."
        }
    }
}
