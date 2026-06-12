//
//  RootView.swift
//  FairwayIQ
//

import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SessionStore.self) private var session

    @State private var route: Route = .loading
    @State private var loadErrorMessage: String?
    @State private var showingLoadError = false

    private enum Route: Equatable {
        case loading
        case onboarding
        case main
    }

    var body: some View {
        ZStack {
            Theme.Color.background.ignoresSafeArea()
            Group {
                switch route {
                case .loading:
                    ProgressView("Loading…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .onboarding:
                    OnboardingView()
                case .main:
                    MainTabView()
                }
            }
        }
        .alert("Couldn’t load your data", isPresented: $showingLoadError) {
            Button("Retry") { loadRoute() }
            Button("Continue") {}
        } message: {
            Text(loadErrorMessage ?? "")
        }
        .onAppear { loadRoute() }
        .onChange(of: session.currentProfileId) { _, _ in loadRoute() }
    }

    private func loadRoute() {
        loadErrorMessage = nil
        showingLoadError = false
        route = .loading

        let repo = ProfileRepository(modelContext: modelContext)
        do {
            let profile: UserProfile?
            if let id = session.currentProfileId {
                profile = try repo.fetchProfile(id: id)
            } else {
                profile = try repo.fetchAnyProfile()
                session.currentProfileId = profile?.id
            }

            guard let profile else {
                route = .onboarding
                return
            }

            route = profile.hasCompletedOnboarding ? .main : .onboarding
        } catch {
            loadErrorMessage = String(describing: error)
            showingLoadError = true
            route = .onboarding
        }

        CourseSeedLoader.applyBundledCatalogIfNeeded(modelContext: modelContext)
        CourseSeedLoader.seedIfNeeded(modelContext: modelContext)

        #if DEBUG
            // Keep demo data available for previews/dev runs, but avoid silently turning production into a demo.
            SampleData.seedIfNeeded(modelContext: modelContext)
        #endif
    }
}

#Preview {
    RootView()
        .modelContainer(for: [UserProfile.self, Course.self, Round.self, FriendEntry.self], inMemory: true)
}
