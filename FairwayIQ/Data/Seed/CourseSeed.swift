import Foundation

struct CourseSeedRecord: Codable, Hashable {
    struct HoleSeed: Codable, Hashable {
        var number: Int
        var par: Int
        var yardage: Int?
    }

    var id: String
    var name: String
    var city: String
    var state: String
    var kind: String?
    var websiteURL: String?
    var latitude: Double?
    var longitude: Double?
    var coursePar: Int?
    var holeCount: Int?
    var holes: [HoleSeed]

    init(
        id: String,
        name: String,
        city: String,
        state: String,
        kind: String? = nil,
        websiteURL: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        coursePar: Int? = nil,
        holeCount: Int? = nil,
        holes: [HoleSeed]
    ) {
        self.id = id
        self.name = name
        self.city = city
        self.state = state
        self.kind = kind
        self.websiteURL = websiteURL
        self.latitude = latitude
        self.longitude = longitude
        self.coursePar = coursePar
        self.holeCount = holeCount
        self.holes = holes
    }
}
