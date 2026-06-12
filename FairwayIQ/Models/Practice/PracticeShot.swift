import Foundation
import SwiftData
import CoreLocation

@Model
final class PracticeShot {
    var id: UUID
    var club: String
    var lie: String
    var shotType: String
    var distanceYards: Double?
    var result: String?
    var notes: String?
    var startLatitude: Double?
    var startLongitude: Double?
    var endLatitude: Double?
    var endLongitude: Double?
    var timestamp: Date
    var session: PracticeSession?

    var startCoordinate: CLLocationCoordinate2D? {
        guard let lat = startLatitude, let lon = startLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var endCoordinate: CLLocationCoordinate2D? {
        guard let lat = endLatitude, let lon = endLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    init(
        id: UUID = UUID(),
        club: String,
        lie: String = "Tee",
        shotType: String = "Normal",
        distanceYards: Double? = nil,
        result: String? = nil,
        notes: String? = nil,
        startLatitude: Double? = nil,
        startLongitude: Double? = nil,
        endLatitude: Double? = nil,
        endLongitude: Double? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.club = club
        self.lie = lie
        self.shotType = shotType
        self.distanceYards = distanceYards
        self.result = result
        self.notes = notes
        self.startLatitude = startLatitude
        self.startLongitude = startLongitude
        self.endLatitude = endLatitude
        self.endLongitude = endLongitude
        self.timestamp = timestamp
    }
}

enum PracticeShotResult: String, CaseIterable, Identifiable {
    case straight = "Straight"
    case slightLeft = "Slight Left"
    case left = "Left"
    case slightRight = "Slight Right"
    case right = "Right"
    case short = "Short"
    case long = "Long"
    case topped = "Topped"
    case thinned = "Thinned"
    case fatShot = "Fat"

    var id: String { rawValue }
}
