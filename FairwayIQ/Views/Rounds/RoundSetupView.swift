//
//  RoundSetupView.swift
//  FairwayIQ
//

import SwiftData
import SwiftUI

struct RoundSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var session
    var onDismiss: (() -> Void)?
    @Query private var courses: [Course]
    @Query private var profiles: [UserProfile]

    @State private var selectedCourse: Course?
    @State private var teeBox = "Blue"
    @State private var roundDate = Date()
    @State private var weather = "Sunny"
    @State private var playingPartners = ""
    @State private var isStarting = false
    @State private var startedRoundItem: RoundNavItem?
    @State private var saveErrorMessage: String?
    @State private var showingSaveError = false

    private var profile: UserProfile? {
        session.resolvedProfile(in: profiles)
    }

    private struct RoundNavItem: Identifiable, Hashable {
        let id: UUID
    }

    private let teeBoxes = ["Black", "Blue", "White", "Gold", "Red"]
    private let weatherOptions = ["Sunny", "Partly Cloudy", "Cloudy", "Windy", "Rain", "Other"]
    private var eligibleCourses: [Course] {
        courses.filter { $0.holes.count >= 18 }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Course") {
                    Picker("Course", selection: $selectedCourse) {
                        Text("Select course").tag(nil as Course?)
                        ForEach(eligibleCourses, id: \.id) { course in
                            Text(course.name).tag(course as Course?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section("Tee & Date") {
                    Picker("Tee box", selection: $teeBox) {
                        ForEach(teeBoxes, id: \.self) { Text($0).tag($0) }
                    }
                    DatePicker("Date", selection: $roundDate, displayedComponents: .date)
                }
                Section("Conditions") {
                    Picker("Weather", selection: $weather) {
                        ForEach(weatherOptions, id: \.self) { Text($0).tag($0) }
                    }
                    TextField("Playing partners (optional)", text: $playingPartners)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .background(Theme.Color.background)
            .scrollContentBackground(.hidden)
            .navigationTitle("New Round")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Color.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start Round") {
                        startRound()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(canStart ? Theme.Color.accent : Theme.Color.textSecondary)
                    .disabled(!canStart || isStarting)
                }
            }
            .navigationDestination(item: $startedRoundItem) { item in
                LiveRoundView(roundId: item.id, onRoundComplete: onDismiss ?? { dismiss() })
            }
        }
        .preferredColorScheme(.dark)
        .alert("Couldn’t start round", isPresented: $showingSaveError) {
            Button("OK") {
                saveErrorMessage = nil
                showingSaveError = false
            }
        } message: {
            Text(saveErrorMessage ?? "")
        }
    }

    private var canStart: Bool {
        selectedCourse != nil
    }

    private func startRound() {
        guard let course = selectedCourse else { return }
        isStarting = true
        let holeCount = max(1, course.holes.count)
        let holeScores: [HoleScore] = (1 ... holeCount).map { num in
            let score = HoleScore(
                holeNumber: num,
                strokes: 0,
                putts: 0,
                fairwayHit: nil,
                gir: false,
                penalties: 0
            )
            modelContext.insert(score)
            return score
        }
        let round = Round(
            course: course,
            courseNameSnapshot: course.name,
            teeBox: teeBox,
            date: roundDate,
            weather: weather,
            playingPartners: playingPartners.isEmpty ? nil : playingPartners,
            player: profile,
            holeScores: holeScores,
            shots: [],
            createdAt: Date()
        )
        for holeScore in holeScores {
            holeScore.round = round
        }
        modelContext.insert(round)
        do {
            try modelContext.save()
            DebugLogger.log("Started round \(round.id) at \(course.name)")
            startedRoundItem = RoundNavItem(id: round.id)
        } catch {
            DebugLogger.error("Failed to start round", error: error)
            saveErrorMessage = "Your round couldn’t be created. Please try again."
            showingSaveError = true
        }
        isStarting = false
    }
}

#Preview {
    RoundSetupView()
        .modelContainer(for: [Course.self, Round.self, UserProfile.self], inMemory: true)
        .environment(SessionStore())
}
