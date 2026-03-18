import Foundation

enum ShotClub: String, CaseIterable, Identifiable {
    case driver = "Driver"
    case threeWood = "3-Wood"
    case fiveWood = "5-Wood"
    case hybrid3 = "3-Hybrid"
    case hybrid4 = "4-Hybrid"
    case iron4 = "4-Iron"
    case iron5 = "5-Iron"
    case iron6 = "6-Iron"
    case iron7 = "7-Iron"
    case iron8 = "8-Iron"
    case iron9 = "9-Iron"
    case pw = "Pitching Wedge"
    case gw = "Gap Wedge"
    case sw = "Sand Wedge"
    case lw = "Lob Wedge"
    case putter = "Putter"

    var id: String { rawValue }
}

enum ShotLie: String, CaseIterable, Identifiable {
    case tee = "Tee"
    case fairway = "Fairway"
    case rough = "Rough"
    case bunker = "Bunker"
    case green = "Green"
    case other = "Other"

    var id: String { rawValue }
}

enum ShotType: String, CaseIterable, Identifiable {
    case normal = "Normal"
    case chip = "Chip"
    case pitch = "Pitch"
    case flop = "Flop"
    case punch = "Punch"
    case draw = "Draw"
    case fade = "Fade"

    var id: String { rawValue }
}

