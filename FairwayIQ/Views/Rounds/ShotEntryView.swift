//
//  ShotEntryView.swift
//  FairwayIQ
//

import CoreLocation
import MapKit
import SwiftData
import SwiftUI

struct ShotEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Environment(SessionStore.self) private var session
    var round: Round
    var holeNumber: Int
    var onDismiss: () -> Void

    @State private var club: ShotClub = .iron7
    @State private var lie: ShotLie = .fairway
    @State private var shotType: ShotType = .normal
    @State private var notes = ""
    @State private var startLat: Double?
    @State private var startLon: Double?
    @State private var endLat: Double?
    @State private var endLon: Double?
    @State private var distanceYards: Double?
    @State private var locationManager = LocationManager()
    @State private var showingSaveError = false
    @State private var saveErrorMessage: String?
    @State private var validationMessage: String?

    private var profile: UserProfile? {
        session.resolvedProfile(in: profiles)
    }

    private var startCoordinate: CLLocationCoordinate2D? {
        if let startLat, let startLon { return CLLocationCoordinate2D(latitude: startLat, longitude: startLon) }
        return locationManager.lastLocation?.coordinate
    }

    private var endCoordinate: CLLocationCoordinate2D? {
        guard let endLat, let endLon else { return nil }
        return CLLocationCoordinate2D(latitude: endLat, longitude: endLon)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Club & Lie") {
                    Picker("Club", selection: $club) {
                        ForEach(ShotClub.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Lie", selection: $lie) {
                        ForEach(ShotLie.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Shot type", selection: $shotType) {
                        ForEach(ShotType.allCases) { Text($0.rawValue).tag($0) }
                    }
                }
                Section("Location") {
                    Text(
                        profile?.preferManualLocationLogging == true
                            ? "Manual mode is enabled. GPS is optional for this shot."
                            : "Location is only used for this shot log and stays on device."
                    )
                    .font(.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
                    if let loc = locationManager.lastLocation {
                        Text("Start: \(loc.coordinate.latitude, specifier: "%.5f"), \(loc.coordinate.longitude, specifier: "%.5f")")
                            .font(.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                    } else {
                        Text("Location unavailable — you can still log the shot and add landing later.")
                            .font(.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                    if let d = distanceYards {
                        Text("Distance: \(d, specifier: "%.0f") yards")
                            .foregroundStyle(Theme.Color.accent)
                    }

                    Button("Use current location as start") {
                        if let loc = locationManager.lastLocation {
                            startLat = loc.coordinate.latitude
                            startLon = loc.coordinate.longitude
                            recalcDistance()
                        }
                    }
                    .foregroundStyle(Theme.Color.greenPrimary)

                    Button("Use current location as landing") {
                        if let loc = locationManager.lastLocation {
                            endLat = loc.coordinate.latitude
                            endLon = loc.coordinate.longitude
                            recalcDistance()
                        }
                    }
                    .foregroundStyle(Theme.Color.greenPrimary)

                    MapReader { proxy in
                        Map(initialPosition: initialMapPosition) {
                            if let start = startCoordinate {
                                Marker("Start", coordinate: start)
                            }
                            if let end = endCoordinate {
                                Marker("Landing", coordinate: end)
                            }
                        }
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                                .stroke(Theme.Color.textSecondary.opacity(0.2), lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { point in
                            if let coord = proxy.convert(point, from: .local) {
                                endLat = coord.latitude
                                endLon = coord.longitude
                                recalcDistance()
                            }
                        }
                    }
                }

                Section("Notes (optional)") {
                    TextField("e.g. wind, miss, target", text: $notes, axis: .vertical)
                        .lineLimit(1 ... 3)
                }
                if let validationMessage {
                    Section {
                        InlineValidationMessage(message: validationMessage)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Color.background)
            .navigationTitle("Shot — Hole \(holeNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                        .foregroundStyle(Theme.Color.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if saveShot() {
                            onDismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Color.greenPrimary)
                }
            }
            .onAppear {
                if profile?.preferManualLocationLogging == false {
                    locationManager.requestWhenInUseAuthorization()
                    locationManager.startUpdatingLocation()
                    if let loc = locationManager.lastLocation {
                        startLat = loc.coordinate.latitude
                        startLon = loc.coordinate.longitude
                    }
                }
            }
            .onDisappear {
                locationManager.stopUpdatingLocation()
            }
        }
        .preferredColorScheme(.dark)
        .alert("Couldn’t save shot", isPresented: $showingSaveError) {
            Button("OK") {
                saveErrorMessage = nil
                showingSaveError = false
            }
        } message: {
            Text(saveErrorMessage ?? "")
        }
    }

    private var initialMapPosition: MapCameraPosition {
        if let start = startCoordinate {
            return .region(MKCoordinateRegion(center: start, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
        }
        return .automatic
    }

    private func recalcDistance() {
        guard
            let start = startCoordinate,
            let end = endCoordinate
        else {
            distanceYards = nil
            return
        }
        let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let endLocation = CLLocation(latitude: end.latitude, longitude: end.longitude)
        distanceYards = startLocation.distance(from: endLocation) / 0.9144
    }

    private func saveShot() -> Bool {
        let lat = startLat ?? locationManager.lastLocation?.coordinate.latitude
        let lon = startLon ?? locationManager.lastLocation?.coordinate.longitude
        recalcDistance()

        let distanceValidation = InputValidation.validateDistance(distanceYards)
        guard distanceValidation.isValid else {
            validationMessage = distanceValidation.errorMessage
            return false
        }
        let coordinateValidation = InputValidation.validateCoordinate(latitude: lat, longitude: lon)
        guard coordinateValidation.isValid else {
            validationMessage = coordinateValidation.errorMessage
            return false
        }

        let shot = Shot(
            holeNumber: holeNumber,
            club: club.rawValue,
            lie: lie.rawValue,
            shotType: shotType.rawValue,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
            startLatitude: lat,
            startLongitude: lon,
            endLatitude: endLat,
            endLongitude: endLon,
            distanceYards: distanceYards,
            timestamp: Date()
        )
        shot.round = round
        modelContext.insert(shot)
        round.shots.append(shot)
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

#Preview {
    ShotEntryView(
        round: Round(courseNameSnapshot: "Preview", holeScores: []),
        holeNumber: 1,
        onDismiss: {}
    )
    .modelContainer(for: [Round.self, Shot.self], inMemory: true)
}
