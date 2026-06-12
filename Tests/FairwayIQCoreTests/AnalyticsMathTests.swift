@testable import FairwayIQCore
import XCTest

final class AnalyticsMathTests: XCTestCase {
    func testSummaryHandlesEmptyRounds() {
        let s = AnalyticsMath.summary(rounds: [])
        XCTAssertEqual(s.averageScore, 0)
        XCTAssertEqual(s.fairwayPct, 0)
        XCTAssertEqual(s.girPct, 0)
        XCTAssertEqual(s.puttsPerRound, 0)
        XCTAssertEqual(s.penaltiesPerRound, 0)
    }

    func testSummaryUsesHolesPlayedDenominator() {
        let rounds = [
            RoundRollup(totalStrokes: 80, fairwaysHit: 6, fairwaysPossible: 10, girsHit: 8, holesPlayed: 18, totalPutts: 32, totalPenalties: 2),
            RoundRollup(totalStrokes: 40, fairwaysHit: 3, fairwaysPossible: 5, girsHit: 4, holesPlayed: 9, totalPutts: 15, totalPenalties: 1)
        ]
        let s = AnalyticsMath.summary(rounds: rounds)
        XCTAssertEqual(s.averageScore, 60, accuracy: 0.0001)
        XCTAssertEqual(s.fairwayPct, (Double(9) / Double(15)) * 100, accuracy: 0.0001)
        XCTAssertEqual(s.girPct, (Double(12) / Double(27)) * 100, accuracy: 0.0001)
    }

    func testYDomainProvidesPadding() {
        let domain = AnalyticsMath.yDomain(scores: [72, 74, 73, 80])
        XCTAssertLessThan(domain.lowerBound, 72)
        XCTAssertGreaterThan(domain.upperBound, 80)
    }

    func testSummaryHandlesZeroFairwayDenominator() {
        let rounds = [
            RoundRollup(totalStrokes: 76, fairwaysHit: 0, fairwaysPossible: 0, girsHit: 10, holesPlayed: 18, totalPutts: 30, totalPenalties: 0)
        ]
        let s = AnalyticsMath.summary(rounds: rounds)
        XCTAssertEqual(s.fairwayPct, 0)
        XCTAssertEqual(s.girPct, (10.0 / 18.0) * 100, accuracy: 0.0001)
    }
}
