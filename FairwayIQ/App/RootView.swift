//
//  RootView.swift
//  FairwayIQ
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }
    private var showOnboarding: Bool {
        guard let p = profile else { return true }
        return !p.hasCompletedOnboarding
    }

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        .onAppear {
            SampleData.seedIfNeeded(modelContext: modelContext)
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: [UserProfile.self, Course.self, Round.self, FriendEntry.self], inMemory: true)
}
