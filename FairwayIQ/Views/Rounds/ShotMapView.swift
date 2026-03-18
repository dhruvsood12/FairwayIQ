//
//  ShotMapView.swift
//  FairwayIQ
//

import SwiftUI
import MapKit
import SwiftData

struct ShotMapView: View {
    var shots: [Shot]

    private var coordinates: [CLLocationCoordinate2D] {
        shots.compactMap { $0.startCoordinate } + shots.compactMap { $0.endCoordinate }
    }
    private var region: MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.5, longitude: -122),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
        let lats = coordinates.map(\.latitude)
        let lons = coordinates.map(\.longitude)
        let minLat = lats.min() ?? 0
        let maxLat = lats.max() ?? 0
        let minLon = lons.min() ?? 0
        let maxLon = lons.max() ?? 0
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.01, (maxLat - minLat) * 1.4),
            longitudeDelta: max(0.01, (maxLon - minLon) * 1.4)
        )
        return MKCoordinateRegion(center: center, span: span)
    }

    var body: some View {
        Group {
            if shots.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "map")
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.Color.textSecondary)
                    Text("No shot locations yet")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text("Add shots during a round to build a map and distance history.")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.Color.textSecondary)
                        .padding(.horizontal, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.Color.cardBackground)
            } else {
                Map(initialPosition: .region(region)) {
                    ForEach(Array(shots.enumerated()), id: \.offset) { _, shot in
                        if let start = shot.startCoordinate {
                            Annotation("Start", coordinate: start) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(Theme.Color.greenPrimary)
                            }
                        }
                        if let end = shot.endCoordinate {
                            Annotation("End", coordinate: end) {
                                Image(systemName: "flag.checkered")
                                    .foregroundStyle(Theme.Color.accent)
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
            }
        }
    }
}

#Preview {
    ShotMapView(shots: [])
        .frame(height: 200)
}
