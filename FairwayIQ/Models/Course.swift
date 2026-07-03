//
//  Course.swift
//  FairwayIQ
//

import CoreLocation
import Foundation
import SwiftData

@Model
final class Course {
    @Attribute(.unique)
    var id: String
    var name: String
    var city: String?
    var state: String?
    var kind: String?
    var websiteURL: String?
    var latitude: Double?
    var longitude: Double?
    var sourcePar: Int?
    var sourceHoleCount: Int?
    @Relationship(deleteRule: .cascade, inverse: \Hole.course)
    var holes: [Hole] = []

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var locationName: String? {
        switch (city?.isEmpty == false ? city : nil, state?.isEmpty == false ? state : nil) {
        case let (cityName?, stateName?): return "\(cityName), \(stateName)"
        case let (cityName?, nil): return cityName
        case let (nil, stateName?): return stateName
        default: return nil
        }
    }

    var totalPar: Int {
        holes.reduce(0) { $0 + $1.par }
    }

    /// The course par when it is actually known: summed from per-hole data
    /// when holes exist, otherwise the source-stated course par, otherwise nil.
    var parIfKnown: Int? {
        if !holes.isEmpty {
            return totalPar
        }
        return sourcePar
    }

    init(
        id: String,
        name: String,
        city: String? = nil,
        state: String? = nil,
        kind: String? = nil,
        websiteURL: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        sourcePar: Int? = nil,
        sourceHoleCount: Int? = nil,
        holes: [Hole] = []
    ) {
        self.id = id
        self.name = name
        self.city = city
        self.state = state
        self.kind = kind
        self.websiteURL = websiteURL
        self.latitude = latitude
        self.longitude = longitude
        self.sourcePar = sourcePar
        self.sourceHoleCount = sourceHoleCount
        self.holes = holes
    }
}
