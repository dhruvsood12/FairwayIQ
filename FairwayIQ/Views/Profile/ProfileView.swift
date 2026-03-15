//
//  ProfileView.swift
//  FairwayIQ
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Layout.sectionSpacing) {
                    playerCard
                    settingsSection
                }
                .padding(Theme.Layout.horizontalPadding)
                .padding(.bottom, 32)
            }
            .background(Theme.Color.background)
            .navigationTitle("Profile")
        }
    }

    private var playerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.Color.greenMuted)
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile?.playerName ?? "Player")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text(profile?.skillLevel ?? "—")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Color.textSecondary)
                    if let h = profile?.handicapEstimate {
                        Text("Index: \(String(format: "%.1f", h))")
                            .font(.caption)
                            .foregroundStyle(Theme.Color.accent)
                    }
                }
                Spacer()
            }
        }
        .padding(Theme.Layout.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            VStack(spacing: 0) {
                row("Units", value: profile?.preferredUnits ?? "yards")
                Divider().background(Theme.Color.textSecondary.opacity(0.3))
                row("Home course", value: profile?.homeCourseId ?? "Not set")
                Divider().background(Theme.Color.textSecondary.opacity(0.3))
                row("Clubs in bag", value: "Manage clubs")
            }
            .background(Theme.Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
        }
    }

    private func row(_ title: String, value: String) -> some View {
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
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserProfile.self], inMemory: true)
}
