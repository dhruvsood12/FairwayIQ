import CoreLocation
import SwiftData
import SwiftUI

struct PracticeSessionEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SessionStore.self) private var session
    @Query private var profiles: [UserProfile]
    var onDismiss: () -> Void

    @State private var sessionType: PracticeSessionType = .range
    @State private var notes = ""
    @State private var shots: [PracticeShotDraft] = []
    @State private var showShotEntry = false
    @State private var showingSaveError = false
    @State private var saveErrorMessage: String?
    @State private var locationManager = LocationManager()

    private var profile: UserProfile? {
        session.resolvedProfile(in: profiles)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Session Type") {
                    Picker("Type", selection: $sessionType) {
                        ForEach(PracticeSessionType.allCases) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Shots (\(shots.count))") {
                    if shots.isEmpty {
                        Text("Tap + to log practice shots")
                            .foregroundStyle(Theme.Color.textSecondary)
                            .font(.subheadline)
                    } else {
                        ForEach(shots.indices, id: \.self) { idx in
                            shotRow(shots[idx])
                        }
                        .onDelete { indexSet in
                            shots.remove(atOffsets: indexSet)
                        }
                    }
                    Button {
                        showShotEntry = true
                    } label: {
                        Label("Add Shot", systemImage: "plus.circle.fill")
                            .foregroundStyle(Theme.Color.accent)
                    }
                }

                Section("Notes (optional)") {
                    TextField("Session notes", text: $notes, axis: .vertical)
                        .lineLimit(1 ... 3)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Color.background)
            .navigationTitle("New Practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                        .foregroundStyle(Theme.Color.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveSession() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.Color.greenPrimary)
                        .disabled(shots.isEmpty)
                }
            }
            .sheet(isPresented: $showShotEntry) {
                PracticeShotEntrySheet(
                    onSave: { draft in
                        shots.append(draft)
                        showShotEntry = false
                    },
                    onCancel: { showShotEntry = false },
                    locationManager: locationManager
                )
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
        .onDisappear {
            locationManager.stopUpdatingLocation()
        }
        .alert("Couldn't save session", isPresented: $showingSaveError) {
            Button("OK") {}
        } message: {
            Text(saveErrorMessage ?? "")
        }
    }

    private func shotRow(_ draft: PracticeShotDraft) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(draft.club)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.Color.textPrimary)
                if let result = draft.result, !result.isEmpty {
                    Text(result)
                        .font(.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
            Spacer()
            if let dist = draft.distance {
                Text("\(Int(dist))y")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Color.accent)
            }
        }
    }

    private func saveSession() {
        let practiceSession = PracticeSession(
            date: Date(),
            sessionType: sessionType.rawValue,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
            player: profile
        )
        modelContext.insert(practiceSession)

        for draft in shots {
            let shot = PracticeShot(
                club: draft.club,
                lie: draft.lie,
                shotType: draft.shotType,
                distanceYards: draft.distance,
                result: draft.result,
                notes: draft.notes,
                startLatitude: draft.startLatitude,
                startLongitude: draft.startLongitude,
                endLatitude: draft.endLatitude,
                endLongitude: draft.endLongitude
            )
            shot.session = practiceSession
            modelContext.insert(shot)
            practiceSession.shots.append(shot)
        }

        do {
            try modelContext.save()
            onDismiss()
        } catch {
            saveErrorMessage = "Failed to save practice session."
            showingSaveError = true
        }
    }
}

struct PracticeShotDraft {
    var club: String
    var lie: String = "Tee"
    var shotType: String = "Normal"
    var distance: Double?
    var result: String?
    var notes: String?
    var startLatitude: Double?
    var startLongitude: Double?
    var endLatitude: Double?
    var endLongitude: Double?
}

struct PracticeShotEntrySheet: View {
    var onSave: (PracticeShotDraft) -> Void
    var onCancel: () -> Void
    let locationManager: LocationManager

    @State private var club: ShotClub = .iron7
    @State private var lie: ShotLie = .tee
    @State private var shotType: ShotType = .normal
    @State private var distanceText = ""
    @State private var result: PracticeShotResult?
    @State private var notes = ""
    @State private var validationError: String?
    @State private var includeGPS = false
    @State private var startCoordinate: CLLocationCoordinate2D?
    @State private var endCoordinate: CLLocationCoordinate2D?

    var body: some View {
        NavigationStack {
            Form {
                Section("Club & Setup") {
                    Picker("Club", selection: $club) {
                        ForEach(ShotClub.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Lie", selection: $lie) {
                        ForEach(ShotLie.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Shot Type", selection: $shotType) {
                        ForEach(ShotType.allCases) { Text($0.rawValue).tag($0) }
                    }
                }
                Section("Distance (yards)") {
                    TextField("e.g. 150", text: $distanceText)
                        .keyboardType(.decimalPad)
                }
                Section("Capture") {
                    Toggle("Attach GPS points", isOn: $includeGPS)
                    if includeGPS {
                        Button("Use current location as shot start") {
                            locationManager.requestWhenInUseAuthorization()
                            startCoordinate = locationManager.lastLocation?.coordinate
                        }
                        Button("Use current location as landing") {
                            locationManager.requestWhenInUseAuthorization()
                            endCoordinate = locationManager.lastLocation?.coordinate
                        }
                    }
                }
                Section("Result") {
                    Picker("Shot Result", selection: $result) {
                        Text("Not recorded").tag(PracticeShotResult?.none)
                        ForEach(PracticeShotResult.allCases) { r in
                            Text(r.rawValue).tag(PracticeShotResult?.some(r))
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(1 ... 2)
                }
                if let validationError {
                    Section {
                        InlineValidationMessage(message: validationError)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Color.background)
            .navigationTitle("Log Shot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                        .foregroundStyle(Theme.Color.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let dist = InputValidation.parseDouble(distanceText)
                        let distanceValidation = InputValidation.validateDistance(dist)
                        guard distanceValidation.isValid else {
                            validationError = distanceValidation.errorMessage
                            return
                        }

                        let start = startCoordinate ?? locationManager.lastLocation?.coordinate
                        let draft = PracticeShotDraft(
                            club: club.rawValue,
                            lie: lie.rawValue,
                            shotType: shotType.rawValue,
                            distance: dist,
                            result: result?.rawValue,
                            notes: notes.isEmpty ? nil : notes,
                            startLatitude: includeGPS ? start?.latitude : nil,
                            startLongitude: includeGPS ? start?.longitude : nil,
                            endLatitude: includeGPS ? endCoordinate?.latitude : nil,
                            endLongitude: includeGPS ? endCoordinate?.longitude : nil
                        )
                        onSave(draft)
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Color.greenPrimary)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            locationManager.requestWhenInUseAuthorization()
        }
    }
}
