import Foundation

public struct HoleScoreInput: Hashable {
    public let strokes: Int
    public let par: Int
    public let strokesReceived: Int

    public init(strokes: Int, par: Int, strokesReceived: Int) {
        self.strokes = strokes
        self.par = par
        self.strokesReceived = strokesReceived
    }
}

public enum HandicapMath {
    /// Rule 5.1a of the Rules of Handicapping (USGA and R&A, 2024): an
    /// 18-hole score differential is (113 / slope) x (adjusted gross score
    /// minus course rating minus the PCC adjustment), rounded to the nearest
    /// tenth with halves rounded upward, which Rule 5.1c shows rounding
    /// negative halves toward zero. PCC defaults to zero per Rule 5.6, which
    /// sets zero whenever the day-level score pool is unavailable. Returns
    /// nil for a non-positive slope rating.
    public static func scoreDifferential(
        adjustedGrossScore: Int,
        courseRating: Double,
        slopeRating: Int,
        pccAdjustment: Double = 0
    ) -> Double? {
        guard slopeRating > 0 else { return nil }
        let raw = (113.0 / Double(slopeRating)) * (Double(adjustedGrossScore) - courseRating - pccAdjustment)
        return roundedToTenthHalfUpward(raw)
    }

    /// Rule 3.1 adjusted gross score. With an established index the per-hole
    /// cap is net double bogey (par + 2 + strokes received, Rule 3.1b);
    /// without one the cap is par + 5 (Rule 3.1a). Returns nil for an empty
    /// round.
    public static func adjustedGrossScore(holes: [HoleScoreInput], hasEstablishedIndex: Bool) -> Int? {
        guard !holes.isEmpty else { return nil }
        return holes.reduce(0) { total, hole in
            let cap = hasEstablishedIndex ? hole.par + 2 + hole.strokesReceived : hole.par + 5
            return total + Swift.min(hole.strokes, cap)
        }
    }

    /// Rules 5.2a and 5.2b: the handicap index from score differentials
    /// ordered most recent first. Uses at most the latest 20, applies the
    /// fewer-than-20 schedule with its adjustments, caps the result at 54.0
    /// per Rule 5.3, and rounds to the nearest tenth. Returns nil below the
    /// three-differential minimum.
    public static func handicapIndex(latestFirstDifferentials: [Double]) -> Double? {
        let record = Array(latestFirstDifferentials.prefix(20))
        guard record.count >= 3 else { return nil }

        let entry = scheduleEntry(for: record.count)
        let lowest = record.sorted().prefix(entry.lowestCount)
        let average = lowest.reduce(0, +) / Double(entry.lowestCount)
        let rounded = roundedToTenthHalfUpward(average + entry.adjustment)
        return Swift.min(rounded, 54.0)
    }

    private static func scheduleEntry(for count: Int) -> (lowestCount: Int, adjustment: Double) {
        switch count {
        case 3: (1, -2.0)
        case 4: (1, -1.0)
        case 5: (1, 0)
        case 6: (2, -1.0)
        case 7, 8: (2, 0)
        case 9 ... 11: (3, 0)
        case 12 ... 14: (4, 0)
        case 15, 16: (5, 0)
        case 17, 18: (6, 0)
        case 19: (7, 0)
        default: (8, 0)
        }
    }

    private static let halfTieRepresentationEpsilon = 1e-9

    private static func roundedToTenthHalfUpward(_ value: Double) -> Double {
        let scaled = value * 10
        let floorValue = scaled.rounded(.down)
        let fraction = scaled - floorValue
        let units = fraction >= 0.5 - halfTieRepresentationEpsilon ? floorValue + 1 : floorValue
        return units / 10
    }
}
