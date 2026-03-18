//
//  ProfileView.swift
//  FairwayIQ
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SessionStore.self) private var session
    @Query private var profiles: [UserProfile]
    @Query(sort: \Round.date, order: .reverse) private var rounds: [Round]

    @State private var showEditProfile = false
    @State private var showClubs = false

    private var profile: UserProfile? { profiles.first }
    private var homeCourseName: String { profile?.homeCourse?.name ?? "Not set" }
    private var roundsPlayed: Int {
        guard let profile else { return rounds.count }
        return rounds.filter { $0.player?.id == profile.id }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Color.background.ignoresSafeArea()
                if let profile {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Theme.Layout.sectionSpacing) {
                            playerCard(profile: profile)
                            profileStatsCard
                            settingsSection(profile: profile)
                        }
                        .padding(Theme.Layout.horizontalPadding)
                        .padding(.bottom, 32)
                    }
                } else {
                    emptyState
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showEditProfile) {
                if let profile = profile { ProfileEditView(profile: profile) }
            }
            .sheet(isPresented: $showClubs) {
                if let profile = profile { ClubsInBagView(profile: profile) }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func playerCard(profile: UserProfile) -> some View {
        Button { showEditProfile = true } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    initialsBadge(name: profile.playerName)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile.playerName)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.Color.textPrimary)
                        Text(profile.skillLevel)
                            .font(.subheadline)
                            .foregroundStyle(Theme.Color.textSecondary)
                        Text("Index: \(String(format: "%.1f", profile.handicapEstimate))")
                            .font(.caption)
                            .foregroundStyle(Theme.Color.accent)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
            .padding(Theme.Layout.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
        }
        .buttonStyle(.plain)
    }

    private var profileStatsCard: some View {
        HStack(spacing: 12) {
            statPill(title: "Rounds", value: "\(roundsPlayed)")
            statPill(title: "Home", value: homeCourseName)
        }
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.Color.textSecondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.Color.textPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Layout.cardPadding)
        .background(Theme.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
    }

    private func settingsSection(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            VStack(spacing: 0) {
                row("Units", value: profile.preferredUnits) { showEditProfile = true }
                Divider().background(Theme.Color.textSecondary.opacity(0.3))
                row("Home course", value: homeCourseName) { showEditProfile = true }
                Divider().background(Theme.Color.textSecondary.opacity(0.3))
                row("Clubs in bag", value: "\(profile.clubsList.count) clubs") { showClubs = true }

                #if DEBUG
                Divider().background(Theme.Color.textSecondary.opacity(0.3))
                row("Debug: Reset onboarding", value: "") {
                    profile.hasCompletedOnboarding = false
                    session.clearCurrentProfile()
                    try? modelContext.save()
                }
                #endif
            }
            .background(Theme.Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
        }
    }

    private func row(_ title: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(Theme.Color.textPrimary)
                Spacer()
                Text(value)
                    .foregroundStyle(Theme.Color.textSecondary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            .padding(Theme.Layout.cardPadding)
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 54))
                .foregroundStyle(Theme.Color.greenMuted)
            Text("Create your profile")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.Color.textPrimary)
            Text("Set your name, handicap estimate, home course, units, and clubs to personalize FairwayIQ.")
                .font(.subheadline)
                .foregroundStyle(Theme.Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Button {
                session.clearCurrentProfile()
            } label: {
                Text("Start onboarding")
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Color.background)
                    .frame(maxWidth: 260)
                    .padding(.vertical, 14)
                    .background(Theme.Color.greenPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.Layout.horizontalPadding)
    }

    private func initialsBadge(name: String) -> some View {
        let parts = name.split(separator: " ").prefix(2)
        let initials = parts.compactMap { $0.first }.map { String($0) }.joined()
        return Text(initials.isEmpty ? "F" : initials.uppercased())
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundStyle(Theme.Color.textPrimary)
            .frame(width: 56, height: 56)
            .background(Theme.Color.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Theme.Color.greenMuted.opacity(0.35), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserProfile.self, Course.self], inMemory: true)
}
