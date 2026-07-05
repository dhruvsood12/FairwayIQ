@testable import FairwayIQCore
import XCTest

/// Golden parity against the app's pre-refactor AnalyticsCalculators.
/// Every expected value below was captured by running the original
/// implementation over these exact fixtures through a throwaway harness on
/// 2026-06-25. The trivial fixture doubles as a hand-derived guard: an
/// 18-hole round of 4 strokes, 2 putts, and 0 penalties per hole must
/// average 72.0 strokes, 36.0 putts, and 0.0 penalties by arithmetic alone.
final class AnalyticsParityTests: XCTestCase {
    private struct HoleSpec {
        let number: Int
        let strokes: Int
        let putts: Int
        let fairway: Bool?
        let gir: Bool
        let penalties: Int
    }

    private func snapshot(name: String, epoch: TimeInterval, holes: [HoleSpec]) -> RoundSnapshot {
        let rollup = RoundRollup(
            totalStrokes: holes.reduce(0) { $0 + $1.strokes },
            fairwaysHit: holes.count(where: { $0.fairway == true }),
            fairwaysPossible: holes.count(where: { $0.fairway != nil }),
            girsHit: holes.count(where: \.gir),
            holesPlayed: holes.count,
            totalPutts: holes.reduce(0) { $0 + $1.putts },
            totalPenalties: holes.reduce(0) { $0 + $1.penalties }
        )
        return RoundSnapshot(
            date: Date(timeIntervalSince1970: epoch),
            courseName: name,
            rollup: rollup,
            holeLines: holes.map { HoleLine(number: $0.number, strokes: $0.strokes) }
        )
    }

    private func uniform(_ range: ClosedRange<Int>, strokes: Int, putts: Int, fairway: Bool?, gir: Bool, penalties: Int) -> [HoleSpec] {
        range.map { HoleSpec(number: $0, strokes: strokes, putts: putts, fairway: fairway, gir: gir, penalties: penalties) }
    }

    private func pattern(_ perHole: [Int]) -> [HoleSpec] {
        perHole.enumerated().map { HoleSpec(number: $0.offset + 1, strokes: $0.element, putts: 2, fairway: nil, gir: false, penalties: 0) }
    }

    private var fixtureNational: RoundSnapshot {
        snapshot(name: "Fixture National", epoch: 1_740_787_200, holes: uniform(1 ... 18, strokes: 4, putts: 2, fairway: true, gir: true, penalties: 0))
    }

    private var nineHoleMuni: RoundSnapshot {
        snapshot(name: "Nine Hole Muni", epoch: 1_741_392_000, holes: uniform(1 ... 9, strokes: 5, putts: 2, fairway: nil, gir: false, penalties: 1))
    }

    private var backNineClub: RoundSnapshot {
        snapshot(name: "Back Nine Club", epoch: 1_741_996_800, holes: uniform(10 ... 18, strokes: 5, putts: 2, fairway: true, gir: false, penalties: 0))
    }

    func testTrivialRoundSummaryMatchesGoldenAndHandDerivation() {
        let summary = AnalyticsMath.summary(rounds: [fixtureNational.rollup])
        XCTAssertEqual(summary.averageScore, 72.0)
        XCTAssertEqual(summary.fairwayPct, 100.0)
        XCTAssertEqual(summary.girPct, 100.0)
        XCTAssertEqual(summary.puttsPerRound, 36.0)
        XCTAssertEqual(summary.penaltiesPerRound, 0.0)
        XCTAssertEqual(summary.bestRoundScore, 72)
        XCTAssertEqual(summary.worstRoundScore, 72)
    }

    func testNineHoleSummaryMatchesGolden() {
        let summary = AnalyticsMath.summary(rounds: [nineHoleMuni.rollup])
        XCTAssertEqual(summary.averageScore, 45.0)
        XCTAssertEqual(summary.fairwayPct, 0.0)
        XCTAssertEqual(summary.girPct, 0.0)
        XCTAssertEqual(summary.puttsPerRound, 18.0)
        XCTAssertEqual(summary.penaltiesPerRound, 9.0)
        XCTAssertEqual(summary.bestRoundScore, 45)
        XCTAssertEqual(summary.worstRoundScore, 45)
    }

    func testMixedSummaryMatchesGolden() {
        let summary = AnalyticsMath.summary(rounds: [fixtureNational.rollup, nineHoleMuni.rollup])
        XCTAssertEqual(summary.averageScore, 58.5)
        XCTAssertEqual(summary.fairwayPct, 100.0)
        XCTAssertEqual(summary.girPct, 66.66666666666666)
        XCTAssertEqual(summary.puttsPerRound, 27.0)
        XCTAssertEqual(summary.penaltiesPerRound, 4.5)
        XCTAssertEqual(summary.bestRoundScore, 45)
        XCTAssertEqual(summary.worstRoundScore, 72)
    }

    func testBackOnlyRoundExcludesZeroFrontNineFromSplit() {
        let split = AnalyticsMath.frontBackSplit(rounds: [backNineClub])
        XCTAssertEqual(split.frontNineAverage, 0.0)
        XCTAssertEqual(split.backNineAverage, 45.0)
    }

    func testSplitAveragesOnlyNonZeroNinesMatchesGolden() {
        let split = AnalyticsMath.frontBackSplit(rounds: [fixtureNational, backNineClub])
        XCTAssertEqual(split.frontNineAverage, 36.0)
        XCTAssertEqual(split.backNineAverage, 40.5)
    }

    func testScoreTrendSortsByDateMatchesGolden() {
        let april10 = snapshot(name: "Trend Links", epoch: 1_744_243_200, holes: pattern(Array(repeating: 5, count: 18)))
        let april1 = snapshot(name: "Trend Links", epoch: 1_743_465_600, holes: pattern(Array(repeating: 5, count: 12) + Array(repeating: 4, count: 6)))
        let april5 = snapshot(name: "Trend Links", epoch: 1_743_811_200, holes: pattern(Array(repeating: 5, count: 15) + Array(repeating: 4, count: 3)))

        let trend = AnalyticsMath.scoreTrend(rounds: [april10, april1, april5])

        XCTAssertEqual(trend.map(\.score), [84, 87, 90])
        XCTAssertEqual(
            trend.map(\.date),
            [Date(timeIntervalSince1970: 1_743_465_600), Date(timeIntervalSince1970: 1_743_811_200), Date(timeIntervalSince1970: 1_744_243_200)]
        )
    }

    func testCoursePerformanceMatchesGolden() {
        let alpha1 = snapshot(name: "Alpha Dunes", epoch: 1_746_057_600, holes: pattern(Array(repeating: 5, count: 10) + Array(repeating: 4, count: 8)))
        let alpha2 = snapshot(name: "Alpha Dunes", epoch: 1_746_144_000, holes: pattern(Array(repeating: 5, count: 6) + Array(repeating: 4, count: 12)))
        let bravo1 = snapshot(name: "Bravo Park", epoch: 1_746_230_400, holes: pattern(Array(repeating: 5, count: 2) + Array(repeating: 4, count: 16)))
        let bravo2 = snapshot(name: "Bravo Park", epoch: 1_746_316_800, holes: pattern(Array(repeating: 5, count: 4) + Array(repeating: 4, count: 14)))
        let charlie1 = snapshot(name: "Charlie Point", epoch: 1_746_403_200, holes: pattern(Array(repeating: 4, count: 16) + Array(repeating: 3, count: 2)))

        let performance = AnalyticsMath.coursePerformance(rounds: [alpha1, bravo1, charlie1, alpha2, bravo2])

        XCTAssertEqual(performance.map(\.courseName), ["Bravo Park", "Alpha Dunes", "Charlie Point"])
        XCTAssertEqual(performance.map(\.roundsPlayed), [2, 2, 1])
        XCTAssertEqual(performance.map(\.averageScore), [75.0, 80.0, 70.0])
    }

    func testCoursePerformanceBreaksFullTiesByName() {
        let firstTie = snapshot(name: "Zulu Bay", epoch: 1_746_057_600, holes: pattern(Array(repeating: 4, count: 18)))
        let secondTie = snapshot(name: "Yankee Ridge", epoch: 1_746_144_000, holes: pattern(Array(repeating: 4, count: 18)))

        let performance = AnalyticsMath.coursePerformance(rounds: [firstTie, secondTie])

        XCTAssertEqual(performance.map(\.courseName), ["Yankee Ridge", "Zulu Bay"])
    }
}
