//
//  Course.swift
//  FairwayIQ
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class Course {
    var id: String
    var name: String
    var locationName: String?
    var latitude: Double?
    var longitude: Double?
    @Relationship(deleteRule: .cascade, inverse: \Hole.course)
    var holes: [Hole] = []

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var totalPar: Int {
        holes.reduce(0) { $0 + $1.par }
    }

    init(
        id: String,
        name: String,
        locationName: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        holes: [Hole] = []
    ) {
        self.id = id
        self.name = name
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.holes = holes
    }
}
