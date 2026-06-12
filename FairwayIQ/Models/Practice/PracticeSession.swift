import Foundation
import SwiftData

@Model
final class PracticeSession {
    var id: UUID
    var date: Date
    var sessionType: String
    var notes: String?
    var player: UserProfile?
    @Relationship(deleteRule: .cascade, inverse: \PracticeShot.session)
    var shots: [PracticeShot] = []

    var shotCount: Int { shots.count }

    var clubsUsed: [String] {
        Array(Set(shots.map(\.club))).sorted()
    }

    var averageDistance: Double? {
        let distances = shots.compactMap(\.distanceYards)
        guard !distances.isEmpty else { return nil }
        return distances.reduce(0, +) / Double(distances.count)
    }

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        sessionType: String = "Range",
        notes: String? = nil,
        player: UserProfile? = nil
    ) {
        self.id = id
        self.date = date
        self.sessionType = sessionType
        self.notes = notes
        self.player = player
    }
}

enum PracticeSessionType: String, CaseIterable, Identifiable {
    case range = "Range"
    case shortGame = "Short Game"
    case putting = "Putting"
    case mixed = "Mixed"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .range: return "figure.golf"
        case .shortGame: return "scope"
        case .putting: return "circle.circle"
        case .mixed: return "square.grid.2x2"
        }
    }
}
