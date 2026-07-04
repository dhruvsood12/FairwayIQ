@testable import FairwayIQCore
import XCTest

/// Every expected value is a published figure from the Rules of Handicapping
/// (USGA and R&A, 2024 revision) or the GB&I national unions' guidance
/// (v2.0), recomputed by hand before being pinned here. Sources are cited in
/// DATA.md.
final class HandicapMathTests: XCTestCase {
    // MARK: Rule 5.1a score differential

    func testGBIWorkedDifferentialNorma() {
        // GB&I guidance pp. 33-35: AGS 88, CR 72.0, slope 129, PCC +1 -> 13.1
        XCTAssertEqual(
            HandicapMath.scoreDifferential(adjustedGrossScore: 88, courseRating: 72.0, slopeRating: 129, pccAdjustment: 1),
            13.1
        )
    }

    func testGBIWorkedDifferentialNorman() {
        // GB&I guidance pp. 33-35: AGS 82, CR 67.2, slope 113, PCC +1 -> 13.8
        XCTAssertEqual(
            HandicapMath.scoreDifferential(adjustedGrossScore: 82, courseRating: 67.2, slopeRating: 113, pccAdjustment: 1),
            13.8
        )
    }

    func testNegativeDifferentialRoundingPerRule51c() {
        // Rule 5.1c official examples: -1.54 -> -1.5, -1.55 -> -1.5, -1.56 -> -1.6
        XCTAssertEqual(HandicapMath.scoreDifferential(adjustedGrossScore: 70, courseRating: 71.54, slopeRating: 113), -1.5)
        XCTAssertEqual(HandicapMath.scoreDifferential(adjustedGrossScore: 70, courseRating: 71.55, slopeRating: 113), -1.5)
        XCTAssertEqual(HandicapMath.scoreDifferential(adjustedGrossScore: 70, courseRating: 71.56, slopeRating: 113), -1.6)
    }

    func testDegenerateSlopeIsGuarded() {
        XCTAssertNil(HandicapMath.scoreDifferential(adjustedGrossScore: 90, courseRating: 72.0, slopeRating: 0))
        XCTAssertNil(HandicapMath.scoreDifferential(adjustedGrossScore: 90, courseRating: 72.0, slopeRating: -5))
    }

    // MARK: Rule 3.1 adjusted gross score

    func testNetDoubleBogeyCapsMatchGBINorma() {
        // Norma, Course Handicap 18, one stroke on every hole; a gross 89
        // whose only blowup is a 9 on the par-5 17th caps that hole at
        // 5 + 2 + 1 = 8, so the adjusted gross score is 88.
        let holes = (1 ... 17).map { number in
            HoleScoreInput(strokes: number == 17 ? 9 : 5, par: number == 17 ? 5 : 4, strokesReceived: 1)
        }
        XCTAssertEqual(holes.reduce(0) { $0 + $1.strokes }, 89)
        XCTAssertEqual(HandicapMath.adjustedGrossScore(holes: holes, hasEstablishedIndex: true), 88)
    }

    func testNetDoubleBogeyUsesStrokesReceivedPerHole() {
        // A 9 on a par 4 with one stroke received caps at 7; a 9 on a par 3
        // with one stroke caps at 6; a 9 on a par 5 with none caps at 7.
        let holes = [
            HoleScoreInput(strokes: 9, par: 4, strokesReceived: 1),
            HoleScoreInput(strokes: 9, par: 3, strokesReceived: 1),
            HoleScoreInput(strokes: 9, par: 5, strokesReceived: 0)
        ]
        XCTAssertEqual(HandicapMath.adjustedGrossScore(holes: holes, hasEstablishedIndex: true), 7 + 6 + 7)
    }

    func testNoIndexCapIsParPlusFive() {
        // Rule 3.1a: first scores cap each hole at par + 5.
        let holes = [
            HoleScoreInput(strokes: 12, par: 4, strokesReceived: 0),
            HoleScoreInput(strokes: 4, par: 4, strokesReceived: 0)
        ]
        XCTAssertEqual(HandicapMath.adjustedGrossScore(holes: holes, hasEstablishedIndex: false), 9 + 4)
    }

    func testEmptyHolesReturnsNil() {
        XCTAssertNil(HandicapMath.adjustedGrossScore(holes: [], hasEstablishedIndex: true))
    }

    // MARK: Rule 5.2a schedule and Rule 5.2b best 8 of 20

    func testFewerThanThreeDifferentialsIsUnavailable() {
        XCTAssertNil(HandicapMath.handicapIndex(latestFirstDifferentials: []))
        XCTAssertNil(HandicapMath.handicapIndex(latestFirstDifferentials: [15.3]))
        XCTAssertNil(HandicapMath.handicapIndex(latestFirstDifferentials: [15.3, 15.2]))
    }

    func testThreeScoresUsesLowestMinusTwoPerClarification52a1() {
        // Clarification 5.2a/1: 15.3, 15.2, 16.6 -> 15.2 - 2.0 = 13.2
        XCTAssertEqual(HandicapMath.handicapIndex(latestFirstDifferentials: [15.3, 15.2, 16.6]), 13.2)
    }

    func testHighIndexProgressionPerClarification52a2() {
        // Clarification 5.2a/2: 40.7, 42.4, 36.1 -> 36.1 - 2.0 = 34.1;
        // with 45.9, 43.6, 45.0 added (six scores) -> (36.1 + 40.7) / 2 - 1.0 = 37.4
        XCTAssertEqual(HandicapMath.handicapIndex(latestFirstDifferentials: [40.7, 42.4, 36.1]), 34.1)
        XCTAssertEqual(
            HandicapMath.handicapIndex(latestFirstDifferentials: [45.9, 43.6, 45.0, 40.7, 42.4, 36.1]),
            37.4
        )
    }

    func testGBIJohnProgressionThroughTheSchedule() {
        // GB&I guidance pp. 30-32, John's first nine differentials.
        var record: [Double] = [26.4, 25.0, 22.1].reversed()
        func index(after newDifferential: Double? = nil) -> Double? {
            if let newDifferential { record.insert(newDifferential, at: 0) }
            return HandicapMath.handicapIndex(latestFirstDifferentials: record)
        }
        XCTAssertEqual(index(), 20.1)
        XCTAssertEqual(index(after: 22.0), 21.0)
        XCTAssertEqual(index(after: 24.0), 22.0)
        XCTAssertEqual(index(after: 21.7), 20.9)
        XCTAssertEqual(index(after: 21.2), 21.5)
        XCTAssertEqual(index(after: 22.0), 21.5)
        XCTAssertEqual(index(after: 19.4), 20.8)
    }

    func testGBITwentyScoreExampleAveragesLowestEight() {
        // GB&I guidance p. 32: twenty differentials -> 12.8.
        let twenty: [Double] = [
            18.5, 19.4, 25.8, 16.7, 18.4, 12.8, 24.0, 15.8, 13.5, 24.0,
            15.6, 11.0, 10.4, 21.2, 18.3, 24.0, 13.1, 20.3, 21.2, 10.1
        ]
        XCTAssertEqual(HandicapMath.handicapIndex(latestFirstDifferentials: twenty), 12.8)
    }

    func testGBITwentyOneScoreExampleDropsTheOldest() {
        // GB&I guidance p. 32: a new 11.8 arrives, the 10.1 ages out, and the
        // index rises to 13.0 despite the good score.
        let twentyOne: [Double] = [
            11.8, 18.5, 19.4, 25.8, 16.7, 18.4, 12.8, 24.0, 15.8, 13.5,
            24.0, 15.6, 11.0, 10.4, 21.2, 18.3, 24.0, 13.1, 20.3, 21.2, 10.1
        ]
        XCTAssertEqual(HandicapMath.handicapIndex(latestFirstDifferentials: twentyOne), 13.0)
    }

    func testIndexIsCappedAtFiftyFour() {
        // Rule 5.3: the maximum handicap index is 54.0.
        XCTAssertEqual(HandicapMath.handicapIndex(latestFirstDifferentials: [60.0, 61.0, 59.0, 58.0, 62.0]), 54.0)
    }
}
