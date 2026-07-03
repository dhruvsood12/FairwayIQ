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

enum CourseSeed {
    /// Small bundled dataset for MVP/demo. Scales later via ingestion pipeline.
    static let starterUS: [CourseSeedRecord] = [
        .init(
            id: "seed-torrey-pines-south",
            name: "Torrey Pines (South)",
            city: "San Diego",
            state: "CA",
            kind: "Municipal",
            websiteURL: "https://www.sandiego.gov/torreypines",
            latitude: 32.9019,
            longitude: -117.2512,
            holes: standard18(pars: [4, 4, 3, 4, 4, 5, 4, 3, 5, 4, 4, 3, 4, 5, 4, 3, 4, 5])
        ),
        .init(
            id: "seed-bethpage-black",
            name: "Bethpage State Park (Black)",
            city: "Farmingdale",
            state: "NY",
            kind: "Public",
            websiteURL: "https://parks.ny.gov/golf-courses/11/details.aspx",
            latitude: 40.7408,
            longitude: -73.4565,
            holes: standard18(pars: [4, 4, 3, 4, 5, 4, 4, 3, 5, 4, 4, 3, 4, 4, 5, 3, 4, 4])
        ),
        .init(
            id: "seed-arcadia-bluffs",
            name: "Arcadia Bluffs Golf Club",
            city: "Arcadia",
            state: "MI",
            kind: "Resort",
            websiteURL: "https://www.arcadiabluffs.com/",
            latitude: 44.5246,
            longitude: -86.2320,
            holes: standard18(pars: [4, 4, 3, 5, 4, 4, 5, 3, 4, 4, 5, 3, 4, 4, 3, 5, 4, 4])
        ),
        .init(
            id: "seed-pinehurst-no2",
            name: "Pinehurst No. 2",
            city: "Pinehurst",
            state: "NC",
            kind: "Resort",
            websiteURL: "https://www.pinehurst.com/golf/pinehurst-no-2/",
            latitude: 35.1888,
            longitude: -79.4677,
            holes: standard18(pars: [4, 4, 3, 4, 4, 5, 3, 4, 4, 4, 5, 3, 4, 4, 5, 3, 4, 4])
        ),
        .init(
            id: "seed-tpc-sawgrass",
            name: "TPC Sawgrass (Stadium)",
            city: "Ponte Vedra Beach",
            state: "FL",
            kind: "Resort",
            websiteURL: "https://tpcsawgrass.com/",
            latitude: 30.1975,
            longitude: -81.3955,
            holes: standard18(pars: [4, 4, 5, 3, 4, 4, 4, 3, 5, 4, 4, 5, 3, 4, 4, 5, 3, 4])
        ),
        .init(
            id: "seed-chambers-bay",
            name: "Chambers Bay",
            city: "University Place",
            state: "WA",
            kind: "Public",
            websiteURL: "https://chambersbaygolf.com/",
            latitude: 47.2131,
            longitude: -122.5508,
            holes: standard18(pars: [4, 4, 3, 4, 4, 3, 5, 4, 4, 4, 3, 4, 4, 5, 3, 4, 5, 4])
        ),
        .init(
            id: "seed-whistling-straits",
            name: "Whistling Straits (Straits)",
            city: "Haven",
            state: "WI",
            kind: "Resort",
            websiteURL: "https://www.destinationkohler.com/golf/whistling-straits",
            latitude: 43.8504,
            longitude: -87.7161,
            holes: standard18(pars: [4, 4, 3, 4, 4, 3, 5, 4, 4, 4, 5, 3, 4, 4, 3, 5, 4, 4])
        ),
        .init(
            id: "seed-bandondunes",
            name: "Bandon Dunes",
            city: "Bandon",
            state: "OR",
            kind: "Resort",
            websiteURL: "https://bandondunesgolf.com/",
            latitude: 43.1112,
            longitude: -124.4081,
            holes: standard18(pars: [4, 4, 3, 5, 4, 4, 3, 5, 4, 4, 4, 3, 5, 4, 4, 3, 5, 4])
        )
    ]

    private static func standard18(pars: [Int]) -> [CourseSeedRecord.HoleSeed] {
        (1 ... 18).map { i in
            .init(number: i, par: pars.indices.contains(i - 1) ? pars[i - 1] : 4, yardage: nil)
        }
    }
}
