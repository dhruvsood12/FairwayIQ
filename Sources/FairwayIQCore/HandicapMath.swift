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
    /// tenth with halves rounded upward. PCC defaults to zero per Rule 5.6,
    /// which sets zero whenever the day-level score pool is unavailable.
    public static func scoreDifferential(
        adjustedGrossScore _: Int,
        courseRating _: Double,
        slopeRating _: Int,
        pccAdjustment _: Double = 0
    ) -> Double? {
        nil
    }

    /// Rule 3.1 adjusted gross score. With an established index the per-hole
    /// cap is net double bogey (par + 2 + strokes received); without one the
    /// cap is par + 5.
    public static func adjustedGrossScore(holes _: [HoleScoreInput], hasEstablishedIndex _: Bool) -> Int? {
        nil
    }

    /// Rule 5.2a and 5.2b: the handicap index from score differentials
    /// ordered most recent first. Uses at most the latest 20, applies the
    /// fewer-than-20 schedule with its adjustments, caps at 54.0, and rounds
    /// to the nearest tenth. Returns nil below the 3-differential minimum.
    public static func handicapIndex(latestFirstDifferentials _: [Double]) -> Double? {
        nil
    }
}
