//
//  ProfileView.swift
//  FairwayIQ
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var courses: [Course]

    @State private var showEditProfile = false
    @State private var showClubs = false

    private var profile: UserProfile? { profiles.first }
    private func homeCourseName(for id: String?) -> String {
        guard let id = id else { return "Not set" }
        return courses.first { $0.id == id }?.name ?? id
    }

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
            .sheet(isPresented: $showEditProfile) {
                if let profile = profile {
                    ProfileEditView(profile: profile)
                }
            }
            .sheet(isPresented: $showClubs) {
                if let profile = profile {
                    ClubsInBagView(profile: profile)
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private var playerCard: some View {
        Button {
            showEditProfile = true
        } label: {
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

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            VStack(spacing: 0) {
                row("Units", value: profile?.preferredUnits ?? "yards") { showEditProfile = true }
                Divider().background(Theme.Color.textSecondary.opacity(0.3))
                row("Home course", value: homeCourseName(for: profile?.homeCourseId)) { showEditProfile = true }
                Divider().background(Theme.Color.textSecondary.opacity(0.3))
                row("Clubs in bag", value: "\(profile?.clubsList.count ?? 0) clubs") { showClubs = true }
                Divider().background(Theme.Color.textSecondary.opacity(0.3))
                Button {
                    profile?.hasCompletedOnboarding = false
                    try? modelContext.save()
                } label: {
                    HStack {
                        Text("Reset onboarding (demo)")
                            .foregroundStyle(Theme.Color.textSecondary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                    .padding(Theme.Layout.cardPadding)
                }
                .buttonStyle(.plain)
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
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserProfile.self, Course.self], inMemory: true)
}
