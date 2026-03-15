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
    @State private var selectedHomeCourseId: String?

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
                    Picker("Home course", selection: $selectedHomeCourseId) {
                        Text("None").tag(nil as String?)
                        ForEach(eligibleCourses, id: \.id) { course in
                            Text(course.name).tag(course.id as String?)
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
                        save()
                        dismiss()
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
                selectedHomeCourseId = profile.homeCourseId
            }
        }
        .preferredColorScheme(.dark)
    }

    private func save() {
        profile.playerName = playerName.trimmingCharacters(in: .whitespaces)
        profile.skillLevel = skillLevel
        profile.handicapEstimate = handicapEstimate
        profile.preferredUnits = preferredUnits
        profile.homeCourseId = selectedHomeCourseId
        profile.updatedAt = Date()
        try? modelContext.save()
    }
}
