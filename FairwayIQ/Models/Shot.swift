//
//  Shot.swift
//  FairwayIQ
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class Shot {
    var holeNumber: Int
    var club: String
    var lie: String
    var shotType: String
    var notes: String?
    var startLatitude: Double?
    var startLongitude: Double?
    var endLatitude: Double?
    var endLongitude: Double?
    var distanceYards: Double?
    var timestamp: Date
    var round: Round?

    var startCoordinate: CLLocationCoordinate2D? {
        guard let lat = startLatitude, let lon = startLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var endCoordinate: CLLocationCoordinate2D? {
        guard let lat = endLatitude, let lon = endLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    init(
        holeNumber: Int,
        club: String,
        lie: String,
        shotType: String,
        notes: String? = nil,
        startLatitude: Double? = nil,
        startLongitude: Double? = nil,
        endLatitude: Double? = nil,
        endLongitude: Double? = nil,
        distanceYards: Double? = nil,
        timestamp: Date = Date()
    ) {
        self.holeNumber = holeNumber
        self.club = club
        self.lie = lie
        self.shotType = shotType
        self.notes = notes
        self.startLatitude = startLatitude
        self.startLongitude = startLongitude
        self.endLatitude = endLatitude
        self.endLongitude = endLongitude
        self.distanceYards = distanceYards
        self.timestamp = timestamp
    }
}
