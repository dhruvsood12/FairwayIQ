import Foundation

struct ClubSummary: Identifiable, Hashable {
    var id: String { clubName }
    let clubName: String
    let sampleSize: Int
    let averageDistance: Double
    let carryDistanceEstimate: Double?
    let totalDistanceEstimate: Double?
    let medianDistance: Double
    let minDistance: Double
    let maxDistance: Double
    let standardDeviation: Double
    let missLeftCount: Int
    let missRightCount: Int
    let missShortCount: Int
    let missLongCount: Int
    let totalMissCategorized: Int

    var distanceRange: Double { maxDistance - minDistance }

    var confidence: ClubConfidence {
        switch sampleSize {
        case 0: return .noData
        case 1...4: return .low
        case 5...14: return .moderate
        default: return .high
        }
    }

    var consistencyRating: String {
        guard sampleSize >= 3 else { return "Insufficient data" }
        let cv = averageDistance > 0 ? (standardDeviation / averageDistance * 100) : 0
        switch cv {
        case 0..<5: return "Very consistent"
        case 5..<10: return "Consistent"
        case 10..<15: return "Moderate"
        default: return "Inconsistent"
        }
    }

    var primaryMissTendency: String? {
        guard totalMissCategorized >= 3 else { return nil }
        let tendencies = [
            ("left", missLeftCount),
            ("right", missRightCount),
            ("short", missShortCount),
            ("long", missLongCount)
        ]
        guard let dominant = tendencies.max(by: { $0.1 < $1.1 }),
              dominant.1 > 0 else { return nil }
        let ratio = Double(dominant.1) / Double(totalMissCategorized)
        guard ratio >= 0.35 else { return nil }
        return "Tends to miss \(dominant.0)"
    }

    var trustLabel: String {
        switch confidence {
        case .high:
            return "Trustworthy club"
        case .moderate:
            return "Useful trend line"
        case .low:
            return "Low-confidence"
        case .noData:
            return "No data"
        }
    }
}

enum ClubConfidence: String, Comparable {
    case noData = "No Data"
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"

    var sortOrder: Int {
        switch self {
        case .noData: return 0
        case .low: return 1
        case .moderate: return 2
        case .high: return 3
        }
    }

    static func < (lhs: ClubConfidence, rhs: ClubConfidence) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

struct ShotRecord {
    let club: String
    let lie: String
    let shotType: String
    let distanceYards: Double?
    let result: String?
    let date: Date
    let isPractice: Bool
}

enum ClubGappingEngine {

    struct Filters {
        var lieFilter: String?
        var shotTypeFilter: String?
        var recentDays: Int?
        var includePractice: Bool = true
        var includeRounds: Bool = true
    }

    static func computeClubSummaries(
        shots: [ShotRecord],
        filters: Filters = Filters()
    ) -> [ClubSummary] {
        let filtered = applyFilters(to: shots, filters: filters)
        let grouped = Dictionary(grouping: filtered, by: \.club)

        return grouped.compactMap { club, clubShots in
            buildSummary(clubName: club, shots: clubShots)
        }
        .sorted { lhs, rhs in
            if lhs.confidence == rhs.confidence {
                return lhs.averageDistance > rhs.averageDistance
            }
            return lhs.confidence > rhs.confidence
        }
    }

    static func computeSummary(
        clubName: String,
        shots: [ShotRecord],
        filters: Filters = Filters()
    ) -> ClubSummary? {
        let filtered = applyFilters(to: shots, filters: filters)
            .filter { $0.club == clubName }
        guard !filtered.isEmpty else { return nil }
        return buildSummary(clubName: clubName, shots: filtered)
    }

    private static func applyFilters(to shots: [ShotRecord], filters: Filters) -> [ShotRecord] {
        var result = shots

        if !filters.includePractice {
            result = result.filter { !$0.isPractice }
        }
        if !filters.includeRounds {
            result = result.filter { $0.isPractice }
        }
        if let lie = filters.lieFilter {
            result = result.filter { $0.lie == lie }
        }
        if let shotType = filters.shotTypeFilter {
            result = result.filter { $0.shotType == shotType }
        }
        if let days = filters.recentDays {
            let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            result = result.filter { $0.date >= cutoff }
        }

        return result
    }

    private static func buildSummary(clubName: String, shots: [ShotRecord]) -> ClubSummary {
        let distances = shots.compactMap(\.distanceYards).filter { $0 > 0 }
        let carrySamples = shots.compactMap(estimatedCarryDistance(for:))
        let totalSamples = shots.compactMap(estimatedTotalDistance(for:))

        let avg: Double
        let carryEstimate: Double?
        let totalEstimate: Double?
        let median: Double
        let minD: Double
        let maxD: Double
        let stdDev: Double

        if distances.isEmpty {
            avg = 0; carryEstimate = nil; totalEstimate = nil; median = 0; minD = 0; maxD = 0; stdDev = 0
        } else {
            avg = distances.reduce(0, +) / Double(distances.count)
            carryEstimate = carrySamples.isEmpty ? nil : carrySamples.reduce(0, +) / Double(carrySamples.count)
            totalEstimate = totalSamples.isEmpty ? nil : totalSamples.reduce(0, +) / Double(totalSamples.count)
            let sorted = distances.sorted()
            median = sorted.count % 2 == 0
                ? (sorted[sorted.count / 2 - 1] + sorted[sorted.count / 2]) / 2
                : sorted[sorted.count / 2]
            minD = sorted.first ?? 0
            maxD = sorted.last ?? 0
            let variance = distances.reduce(0.0) { $0 + pow($1 - avg, 2) } / Double(distances.count)
            stdDev = sqrt(variance)
        }

        var leftCount = 0, rightCount = 0, shortCount = 0, longCount = 0, categorized = 0
        for shot in shots {
            guard let result = shot.result?.lowercased() else { continue }
            categorized += 1
            if result.contains("left") { leftCount += 1 }
            else if result.contains("right") { rightCount += 1 }
            if result.contains("short") { shortCount += 1 }
            else if result.contains("long") { longCount += 1 }
        }

        return ClubSummary(
            clubName: clubName,
            sampleSize: shots.count,
            averageDistance: avg,
            carryDistanceEstimate: carryEstimate,
            totalDistanceEstimate: totalEstimate ?? (avg > 0 ? avg : nil),
            medianDistance: median,
            minDistance: minD,
            maxDistance: maxD,
            standardDeviation: stdDev,
            missLeftCount: leftCount,
            missRightCount: rightCount,
            missShortCount: shortCount,
            missLongCount: longCount,
            totalMissCategorized: categorized
        )
    }

    private static func estimatedCarryDistance(for shot: ShotRecord) -> Double? {
        guard let distance = shot.distanceYards, distance > 0 else { return nil }

        switch shot.lie.lowercased() {
        case "tee":
            return distance * 0.88
        case "green":
            return distance
        case "bunker":
            return distance * 0.95
        default:
            return distance * 0.96
        }
    }

    private static func estimatedTotalDistance(for shot: ShotRecord) -> Double? {
        guard let distance = shot.distanceYards, distance > 0 else { return nil }
        return distance
    }
}
