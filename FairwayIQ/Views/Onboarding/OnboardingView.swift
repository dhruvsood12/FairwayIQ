//
//  OnboardingView.swift
//  FairwayIQ
//

import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var courses: [Course]
    @Environment(SessionStore.self) private var session
    @State private var step = 0
    @State private var playerName = ""
    @State private var skillLevel = "Intermediate"
    @State private var handicapEstimate = 18.0
    @State private var preferredUnits = "yards"
    @State private var selectedHomeCourse: Course?
    @State private var isCompleting = false
    @State private var completeErrorMessage: String?
    @State private var showingCompleteError = false

    private let skillLevels = ["Beginner", "Intermediate", "Advanced", "Scratch"]
    private let unitsOptions = ["yards", "meters"]

    var body: some View {
        ZStack {
            Theme.Color.background.ignoresSafeArea()
            VStack(spacing: 0) {
                progressIndicator
                TabView(selection: $step) {
                    welcomeStep.tag(0)
                    nameStep.tag(1)
                    skillStep.tag(2)
                    unitsStep.tag(3)
                    homeCourseStep.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.25), value: step)
                bottomButtons
            }
        }
        .preferredColorScheme(.dark)
        .alert("Couldn’t finish setup", isPresented: $showingCompleteError) {
            Button("OK") {
                completeErrorMessage = nil
                showingCompleteError = false
            }
        } message: {
            Text(completeErrorMessage ?? "")
        }
    }

    private var progressIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0 ..< 5, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? Theme.Color.greenPrimary : Theme.Color.backgroundSecondary)
                    .frame(height: 4)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, Theme.Layout.horizontalPadding)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "figure.golf")
                .font(.system(size: 72))
                .foregroundStyle(Theme.Color.greenPrimary)
            Text("Welcome to FairwayIQ")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(Theme.Color.textPrimary)
                .multilineTextAlignment(.center)
            Text("Track rounds, log shots, and improve your game with analytics and insights.")
                .font(.body)
                .foregroundStyle(Theme.Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("What should we call you?")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Color.textPrimary)
            TextField("Player name", text: $playerName)
                .textFieldStyle(.plain)
                .font(.title3)
                .padding(Theme.Layout.cardPadding)
                .background(Theme.Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
                .foregroundStyle(Theme.Color.textPrimary)
                .autocorrectionDisabled()
            Spacer()
        }
        .padding(Theme.Layout.horizontalPadding)
        .padding(.top, 40)
    }

    private var skillStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Skill level")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Color.textPrimary)
            Text("Helps us tailor stats and suggestions.")
                .font(.subheadline)
                .foregroundStyle(Theme.Color.textSecondary)
            VStack(spacing: 10) {
                ForEach(skillLevels, id: \.self) { level in
                    Button {
                        skillLevel = level
                        if level == "Beginner" {
                            handicapEstimate = 25
                        } else if level == "Intermediate" {
                            handicapEstimate = 18
                        } else if level == "Advanced" {
                            handicapEstimate = 10
                        } else {
                            handicapEstimate = 0
                        }
                    } label: {
                        HStack {
                            Text(level)
                                .foregroundStyle(Theme.Color.textPrimary)
                            Spacer()
                            if skillLevel == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.Color.greenPrimary)
                            }
                        }
                        .padding(Theme.Layout.cardPadding)
                        .background(skillLevel == level ? Theme.Color.greenMuted.opacity(0.4) : Theme.Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
                    }
                    .buttonStyle(.plain)
                }
            }
            Text("Handicap estimate: \(handicapEstimate, specifier: "%.0f")")
                .font(.caption)
                .foregroundStyle(Theme.Color.textSecondary)
            Spacer()
        }
        .padding(Theme.Layout.horizontalPadding)
        .padding(.top, 40)
    }

    private var unitsStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Preferred units")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Color.textPrimary)
            HStack(spacing: 12) {
                ForEach(unitsOptions, id: \.self) { unit in
                    Button {
                        preferredUnits = unit
                    } label: {
                        Text(unit.capitalized)
                            .fontWeight(.medium)
                            .foregroundStyle(preferredUnits == unit ? Theme.Color.background : Theme.Color.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(preferredUnits == unit ? Theme.Color.greenPrimary : Theme.Color.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer()
        }
        .padding(Theme.Layout.horizontalPadding)
        .padding(.top, 40)
    }

    private var homeCourseStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Home course (optional)")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Color.textPrimary)
            Text("We'll show it first when starting a round.")
                .font(.subheadline)
                .foregroundStyle(Theme.Color.textSecondary)
            ScrollView {
                VStack(spacing: 10) {
                    Button {
                        selectedHomeCourse = nil
                    } label: {
                        HStack {
                            Text("None")
                                .foregroundStyle(Theme.Color.textPrimary)
                            Spacer()
                            if selectedHomeCourse == nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.Color.greenPrimary)
                            }
                        }
                        .padding(Theme.Layout.cardPadding)
                        .background(selectedHomeCourse == nil ? Theme.Color.greenMuted.opacity(0.4) : Theme.Color.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
                    }
                    .buttonStyle(.plain)
                    ForEach(courses.filter { $0.holes.count >= 18 }, id: \.id) { course in
                        Button {
                            selectedHomeCourse = course
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(course.name)
                                        .foregroundStyle(Theme.Color.textPrimary)
                                    if let loc = course.locationName {
                                        Text(loc)
                                            .font(.caption)
                                            .foregroundStyle(Theme.Color.textSecondary)
                                    }
                                }
                                Spacer()
                                if selectedHomeCourse?.id == course.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Theme.Color.greenPrimary)
                                }
                            }
                            .padding(Theme.Layout.cardPadding)
                            .background(selectedHomeCourse?.id == course.id ? Theme.Color.greenMuted.opacity(0.4) : Theme.Color.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Spacer()
        }
        .padding(Theme.Layout.horizontalPadding)
        .padding(.top, 40)
    }

    private var bottomButtons: some View {
        VStack(spacing: 12) {
            Button {
                if step < 4 {
                    withAnimation { step += 1 }
                } else {
                    completeOnboarding()
                }
            } label: {
                Text(step == 4 ? "Get Started" : "Continue")
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Color.background)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canProceed ? Theme.Color.greenPrimary : Theme.Color.textSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
            }
            .disabled(!canProceed)
            .opacity(canProceed ? 1 : 0.7)

            if step > 0 {
                Button("Back") {
                    withAnimation { step -= 1 }
                }
                .font(.subheadline)
                .foregroundStyle(Theme.Color.textSecondary)
            }
        }
        .padding(Theme.Layout.horizontalPadding)
        .padding(.bottom, 40)
    }

    private var canProceed: Bool {
        if step == 1 { return !playerName.trimmingCharacters(in: .whitespaces).isEmpty }
        return true
    }

    private func completeOnboarding() {
        isCompleting = true
        let descriptor = FetchDescriptor<UserProfile>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        let profile: UserProfile
        if let currentProfileId = session.currentProfileId,
           let current = existing.first(where: { $0.id == currentProfileId })
        {
            profile = current
            profile.playerName = playerName.trimmingCharacters(in: .whitespaces)
            profile.skillLevel = skillLevel
            profile.handicapEstimate = handicapEstimate
            profile.preferredUnits = preferredUnits
            profile.homeCourse = selectedHomeCourse
            profile.hasCompletedOnboarding = true
            profile.updatedAt = Date()
        } else if let first = existing.first {
            profile = first
            profile.playerName = playerName.trimmingCharacters(in: .whitespaces)
            profile.skillLevel = skillLevel
            profile.handicapEstimate = handicapEstimate
            profile.preferredUnits = preferredUnits
            profile.homeCourse = selectedHomeCourse
            profile.hasCompletedOnboarding = true
            profile.updatedAt = Date()
        } else {
            profile = UserProfile(
                playerName: playerName.trimmingCharacters(in: .whitespaces),
                skillLevel: skillLevel,
                handicapEstimate: handicapEstimate,
                preferredUnits: preferredUnits,
                homeCourse: selectedHomeCourse,
                hasCompletedOnboarding: true
            )
            modelContext.insert(profile)
        }
        do {
            try modelContext.save()
            session.currentProfileId = profile.id
            DebugLogger.log("Completed onboarding for profile \(profile.id)")
        } catch {
            DebugLogger.error("Failed to complete onboarding", error: error)
            completeErrorMessage = "Your profile couldn’t be saved. Please try again."
            showingCompleteError = true
        }
        isCompleting = false
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [UserProfile.self, Course.self], inMemory: true)
        .environment(SessionStore())
}
