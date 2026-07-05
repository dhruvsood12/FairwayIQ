import FairwayIQCore
import SwiftData
import SwiftUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SessionStore.self) private var session
    @Query private var profiles: [UserProfile]
    @Query(sort: \Round.date, order: .reverse) private var rounds: [Round]
    @State private var showEditProfile = false
    @State private var showClubsInBag = false
    @State private var showDeleteConfirmation = false
    @State private var showPrivacyInfo = false
    @State private var exportText = ""
    @State private var showShareSheet = false

    private var profile: UserProfile? {
        session.resolvedProfile(in: profiles)
    }

    private var scopedRounds: [Round] {
        session.roundsForCurrentProfile(rounds, profiles: profiles)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xxl) {
                    if let profile {
                        profileHeader(profile)
                        statsCard
                        settingsSection
                        privacySection
                        dangerZone
                    } else {
                        EmptyStateView(
                            icon: "person.crop.circle",
                            title: "No Profile",
                            message: "Complete onboarding to create your player profile."
                        )
                    }
                }
                .padding(Theme.Layout.horizontalPadding)
                .padding(.bottom, Spacing.xxxl)
            }
            .background(Theme.Color.background)
            .navigationTitle("Profile")
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(text: exportText)
        }
    }

    private func profileHeader(_ profile: UserProfile) -> some View {
        FIQCard {
            VStack(spacing: Spacing.lg) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.Color.greenPrimary)
                Text(profile.playerName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.Color.textPrimary)
                HStack(spacing: Spacing.xl) {
                    VStack(spacing: Spacing.xxs) {
                        Text(String(format: "%.1f", profile.handicapEstimate))
                            .font(.headline)
                            .foregroundStyle(Theme.Color.accent)
                        Text("Handicap (self-reported)")
                            .font(.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                    VStack(spacing: Spacing.xxs) {
                        Text(profile.skillLevel)
                            .font(.headline)
                            .foregroundStyle(Theme.Color.textPrimary)
                        Text("Skill Level")
                            .font(.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                    VStack(spacing: Spacing.xxs) {
                        Text("\(scopedRounds.count)")
                            .font(.headline)
                            .foregroundStyle(Theme.Color.textPrimary)
                        Text("Rounds")
                            .font(.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                }
                if let homeCourse = profile.homeCourse {
                    Text("Home: \(homeCourse.name)")
                        .font(.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var statsCard: some View {
        FIQCard {
            VStack(alignment: .leading, spacing: Spacing.md) {
                SectionHeader(title: "Quick Stats")
                if scopedRounds.isEmpty {
                    Text("Play a round to see your stats here.")
                        .font(.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                } else {
                    let summary = AnalyticsMath.summary(rounds: scopedRounds.map(\.rollup))
                    HStack(spacing: Spacing.md) {
                        StatTile(title: "Avg Score", value: String(format: "%.0f", summary.averageScore))
                        StatTile(title: "Best", value: summary.bestRoundScore.map(String.init) ?? "-", valueColor: Theme.Color.positive)
                        StatTile(title: "Putts/Rnd", value: String(format: "%.1f", summary.puttsPerRound))
                    }
                }
            }
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Settings")

            Button { showEditProfile = true } label: {
                settingsRow(icon: "pencil", title: "Edit Profile")
            }
            .sheet(isPresented: $showEditProfile) {
                if let profile {
                    ProfileEditView(profile: profile)
                }
            }

            Button { showClubsInBag = true } label: {
                settingsRow(icon: "bag.fill", title: "Clubs in Bag")
            }
            .sheet(isPresented: $showClubsInBag) {
                if let profile {
                    ClubsInBagView(profile: profile)
                }
            }

            NavigationLink {
                PracticeView()
            } label: {
                settingsRow(icon: "figure.golf", title: "Practice Sessions")
            }

            NavigationLink {
                GoalsView()
            } label: {
                settingsRow(icon: "target", title: "Goals")
            }
        }
    }

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Privacy & Data")

            if let profile {
                FIQCard {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Toggle("Hide exact location in exports", isOn: binding(for: \.hideExactLocationInExports, on: profile))
                            .tint(Theme.Color.greenPrimary)
                        Toggle("Prefer manual location logging", isOn: binding(for: \.preferManualLocationLogging, on: profile))
                            .tint(Theme.Color.greenPrimary)
                        Text("FairwayIQ stays local-first. These controls let you reduce location detail in reports and avoid automatic GPS use during shot logging.")
                            .font(.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                }
            }

            Button { showPrivacyInfo = true } label: {
                settingsRow(icon: "lock.shield", title: "Privacy Info")
            }
            .sheet(isPresented: $showPrivacyInfo) {
                PrivacyInfoView()
            }

            Button {
                exportAllData()
            } label: {
                settingsRow(icon: "square.and.arrow.up", title: "Export My Data")
            }
        }
    }

    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(title: "Danger Zone")

            Button { showDeleteConfirmation = true } label: {
                HStack(spacing: Spacing.md) {
                    Image(systemName: "trash")
                        .font(.body)
                        .foregroundStyle(Theme.Color.negative)
                        .frame(width: 28)
                    Text("Delete All Local Data")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Color.negative)
                    Spacer()
                }
                .padding(Theme.Layout.cardPadding)
                .background(Theme.Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
            }
            .buttonStyle(.plain)
            .alert("Delete All Data?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Everything", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("This will permanently delete all rounds, practice sessions, goals, and profile data. This cannot be undone.")
            }

            #if DEBUG
                Button {
                    SampleData.seedIfNeeded(modelContext: modelContext)
                    SampleData.ensureDemoProfile(modelContext: modelContext)
                } label: {
                    settingsRow(icon: "ladybug", title: "Reset Sample Data (Debug)")
                }
            #endif
        }
    }

    private func settingsRow(icon: String, title: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Theme.Color.greenPrimary)
                .frame(width: 28)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(Theme.Color.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Theme.Color.textSecondary)
        }
        .padding(Theme.Layout.cardPadding)
        .background(Theme.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
    }

    private func exportAllData() {
        guard let profile else { return }
        let summary = AnalyticsMath.summary(rounds: scopedRounds.map(\.rollup))
        let snapshot = ExportManager.buildStatsExport(
            profile: profile,
            summary: summary,
            roundCount: scopedRounds.count,
            computedIndex: HandicapAnalytics.computedIndex(rounds: scopedRounds)
        )
        let snapshotText = ExportManager.statsSnapshotText(snapshot: snapshot)
        let latestRoundText: String
        if let round = scopedRounds.first {
            let coaching = CoachingEngine.analyze(round: round, baseline: CoachingEngine.computeBaseline(from: Array(scopedRounds.dropFirst().prefix(5))))
            let export = ExportManager.buildRoundExport(
                round: round,
                coaching: coaching,
                privacy: ExportPrivacyOptions(hideExactLocation: profile.hideExactLocationInExports, includeCoachingNotes: true)
            )
            latestRoundText = ExportManager.roundSummaryText(summary: export)
        } else {
            latestRoundText = "No rounds available yet."
        }
        exportText = [snapshotText, "", latestRoundText].joined(separator: "\n")
        showShareSheet = true
    }

    private func deleteAllData() {
        do {
            try modelContext.delete(model: PracticeShot.self)
            try modelContext.delete(model: PracticeSession.self)
            try modelContext.delete(model: PlayerGoal.self)
            try modelContext.delete(model: Shot.self)
            try modelContext.delete(model: HoleScore.self)
            try modelContext.delete(model: Round.self)
            try modelContext.delete(model: UserProfile.self)
            try modelContext.delete(model: FriendEntry.self)
            try modelContext.save()
            session.clearCurrentProfile()
        } catch {
            DebugLogger.error("Failed to delete all data", error: error)
        }
    }

    private func binding<Value>(for keyPath: ReferenceWritableKeyPath<UserProfile, Value>, on profile: UserProfile) -> Binding<Value> {
        Binding(
            get: { profile[keyPath: keyPath] },
            set: {
                profile[keyPath: keyPath] = $0
                profile.updatedAt = Date()
                try? modelContext.save()
            }
        )
    }
}

struct PrivacyInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xxl) {
                    FIQCard {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Label("Local-First", systemImage: "iphone")
                                .font(.headline)
                                .foregroundStyle(Theme.Color.textPrimary)
                            Text("All your data is stored locally on your device. FairwayIQ does not send your data to any server.")
                                .font(.subheadline)
                                .foregroundStyle(Theme.Color.textSecondary)
                        }
                    }
                    FIQCard {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Label("Location", systemImage: "location")
                                .font(.headline)
                                .foregroundStyle(Theme.Color.textPrimary)
                            Text(
                                "Location is only used when you choose to log shot positions during a round. "
                                    + "It is never shared or uploaded. You can use the app fully without granting location permission."
                            )
                            .font(.subheadline)
                            .foregroundStyle(Theme.Color.textSecondary)
                        }
                    }
                    FIQCard {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Label("Your Data", systemImage: "person.badge.shield.checkmark")
                                .font(.headline)
                                .foregroundStyle(Theme.Color.textPrimary)
                            Text("You can export all your data at any time from Profile > Export My Data. You can delete all data from Profile > Delete All Local Data.")
                                .font(.subheadline)
                                .foregroundStyle(Theme.Color.textSecondary)
                        }
                    }
                    FIQCard {
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Label("No Tracking", systemImage: "eye.slash")
                                .font(.headline)
                                .foregroundStyle(Theme.Color.textPrimary)
                            Text("FairwayIQ does not include any analytics SDKs, advertising trackers, or third-party data collection.")
                                .font(.subheadline)
                                .foregroundStyle(Theme.Color.textSecondary)
                        }
                    }
                }
                .padding(Theme.Layout.horizontalPadding)
                .padding(.bottom, Spacing.xxxl)
            }
            .background(Theme.Color.background)
            .navigationTitle("Privacy & Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.Color.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserProfile.self, Round.self, Course.self], inMemory: true)
        .environment(SessionStore())
}
