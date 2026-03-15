//
//  ShotEntryView.swift
//  FairwayIQ
//

import SwiftUI
import SwiftData
import CoreLocation

struct ShotEntryView: View {
    @Environment(\.modelContext) private var modelContext
    var round: Round
    var holeNumber: Int
    var onDismiss: () -> Void

    @State private var club = "7-Iron"
    @State private var lie = "Fairway"
    @State private var shotType = "Normal"
    @State private var startLat: Double?
    @State private var startLon: Double?
    @State private var endLat: Double?
    @State private var endLon: Double?
    @State private var distanceYards: Double?
    @StateObject private var locationManager = LocationManager()

    private let clubs = ["Driver", "3-Wood", "5-Wood", "3-Hybrid", "4-Iron", "5-Iron", "6-Iron", "7-Iron", "8-Iron", "9-Iron", "Pitching Wedge", "Sand Wedge", "Lob Wedge", "Putter"]
    private let lies = ["Tee", "Fairway", "Rough", "Bunker", "Green", "Other"]
    private let shotTypes = ["Normal", "Chip", "Pitch", "Flop", "Punch", "Draw", "Fade"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Club & Lie") {
                    Picker("Club", selection: $club) {
                        ForEach(clubs, id: \.self) { Text($0).tag($0) }
                    }
                    Picker("Lie", selection: $lie) {
                        ForEach(lies, id: \.self) { Text($0).tag($0) }
                    }
                    Picker("Shot type", selection: $shotType) {
                        ForEach(shotTypes, id: \.self) { Text($0).tag($0) }
                    }
                }
                Section("Location") {
                    if let loc = locationManager.lastLocation {
                        Text("Start: \(loc.coordinate.latitude, specifier: "%.5f"), \(loc.coordinate.longitude, specifier: "%.5f")")
                            .font(.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                    } else {
                        Text("Acquiring location…")
                            .font(.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                    if let d = distanceYards {
                        Text("Distance: \(d, specifier: "%.0f") yards")
                            .foregroundStyle(Theme.Color.accent)
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
                        saveShot()
                        onDismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.Color.greenPrimary)
                }
            }
            .onAppear {
                locationManager.requestWhenInUseAuthorization()
                locationManager.startUpdatingLocation()
                if let loc = locationManager.lastLocation {
                    startLat = loc.coordinate.latitude
                    startLon = loc.coordinate.longitude
                }
            }
            .onDisappear {
                locationManager.stopUpdatingLocation()
            }
        }
        .preferredColorScheme(.dark)
    }

    private func saveShot() {
        let lat = startLat ?? locationManager.lastLocation?.coordinate.latitude
        let lon = startLon ?? locationManager.lastLocation?.coordinate.longitude
        var dist: Double? = distanceYards
        if let slat = lat, let slon = lon, let elat = endLat, let elon = endLon {
            let start = CLLocation(latitude: slat, longitude: slon)
            let end = CLLocation(latitude: elat, longitude: elon)
            dist = start.distance(from: end) / 0.9144
        }
        let shot = Shot(
            holeNumber: holeNumber,
            club: club,
            lie: lie,
            shotType: shotType,
            startLatitude: lat,
            startLongitude: lon,
            endLatitude: endLat,
            endLongitude: endLon,
            distanceYards: dist,
            timestamp: Date()
        )
        shot.round = round
        modelContext.insert(shot)
        round.shots.append(shot)
        try? modelContext.save()
    }
}

#Preview {
    ShotEntryView(
        round: Round(courseId: "x", courseName: "Preview", holeScores: []),
        holeNumber: 1,
        onDismiss: {}
    )
    .modelContainer(for: [Round.self, Shot.self], inMemory: true)
}
