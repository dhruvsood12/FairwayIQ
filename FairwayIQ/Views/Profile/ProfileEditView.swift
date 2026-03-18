//
//  ProfileEditView.swift
//  FairwayIQ
//

import SwiftUI
import SwiftData

struct ProfileEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var profile: UserProfile
    @Query private var courses: [Course]

    @State private var playerName: String = ""
    @State private var skillLevel: String = "Intermediate"
    @State private var handicapEstimate: Double = 18
    @State private var preferredUnits: String = "yards"
    @State private var selectedHomeCourse: Course?
    @State private var saveErrorMessage: String?
    @State private var showingSaveError = false

    private let skillLevels = ["Beginner", "Intermediate", "Advanced", "Scratch"]
    private var eligibleCourses: [Course] { courses.filter { $0.holes.count >= 18 } }

    var body: some View {
        NavigationStack {
            Form {
                Section("Player") {
                    TextField("Name", text: $playerName)
                        .textFieldStyle(.roundedBorder)
                }
                Section("Skill") {
                    Picker("Level", selection: $skillLevel) {
                        ForEach(skillLevels, id: \.self) { Text($0).tag($0) }
                    }
                    HStack {
                        Text("Handicap index")
                        Slider(value: $handicapEstimate, in: 0...54, step: 0.5)
                        Text(String(format: "%.1f", handicapEstimate))
                            .frame(width: 36)
                    }
                }
                Section("Preferences") {
                    Picker("Units", selection: $preferredUnits) {
                        Text("Yards").tag("yards")
                        Text("Meters").tag("meters")
                    }
                    Picker("Home course", selection: $selectedHomeCourse) {
                        Text("None").tag(nil as Course?)
                        ForEach(eligibleCourses, id: \.id) { course in
                            Text(course.name).tag(course as Course?)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Color.background)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Color.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if save() {
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Color.greenPrimary)
                }
            }
            .onAppear {
                playerName = profile.playerName
                skillLevel = profile.skillLevel
                handicapEstimate = profile.handicapEstimate
                preferredUnits = profile.preferredUnits
                selectedHomeCourse = profile.homeCourse
            }
        }
        .preferredColorScheme(.dark)
        .alert("Couldn’t save profile", isPresented: $showingSaveError) {
            Button("OK") {
                saveErrorMessage = nil
                showingSaveError = false
            }
        } message: {
            Text(saveErrorMessage ?? "")
        }
    }

    private func save() -> Bool {
        let trimmedName = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            saveErrorMessage = "Name can’t be empty."
            showingSaveError = true
            return false
        }
        profile.playerName = trimmedName
        profile.skillLevel = skillLevel
        profile.handicapEstimate = handicapEstimate
        profile.preferredUnits = preferredUnits
        profile.homeCourse = selectedHomeCourse
        profile.updatedAt = Date()
        do {
            try modelContext.save()
            return true
        } catch {
            saveErrorMessage = String(describing: error)
            showingSaveError = true
            return false
        }
    }
}
