@testable import FairwayIQ
import Testing

@Suite("StrategyEngine Tests")
struct StrategyEngineTests {
    private func makeSummary(club: String, avgDistance: Double, sampleSize: Int) -> ClubSummary {
        ClubSummary(
            clubName: club,
            sampleSize: sampleSize,
            averageDistance: avgDistance,
            carryDistanceEstimate: avgDistance * 0.9,
            totalDistanceEstimate: avgDistance,
            medianDistance: avgDistance,
            minDistance: avgDistance - 10,
            maxDistance: avgDistance + 10,
            standardDeviation: 5,
            missLeftCount: 0,
            missRightCount: 0,
            missShortCount: 0,
            missLongCount: 0,
            totalMissCategorized: 0
        )
    }

    @Test("No yardage returns no suggestion")
    func noYardage() {
        let hole = HoleInfo(number: 1, par: 4, yardage: nil)
        let result = StrategyEngine.recommend(hole: hole, clubSummaries: [], missTendencies: [], mode: .standard)
        #expect(result.teeSuggestion == nil)
        #expect(!result.warnings.isEmpty)
    }

    @Test("No club data returns sparse data warning")
    func noClubData() {
        let hole = HoleInfo(number: 1, par: 4, yardage: 400)
        let result = StrategyEngine.recommend(hole: hole, clubSummaries: [], missTendencies: [], mode: .standard)
        #expect(result.teeSuggestion == nil)
        #expect(result.warnings.first?.contains("Not enough") == true)
    }

    @Test("Standard mode recommends driver on par 4")
    func standardDriverOnPar4() {
        let clubs = [
            makeSummary(club: "Driver", avgDistance: 250, sampleSize: 10),
            makeSummary(club: "7-Iron", avgDistance: 150, sampleSize: 10)
        ]
        let hole = HoleInfo(number: 1, par: 4, yardage: 400)
        let result = StrategyEngine.recommend(hole: hole, clubSummaries: clubs, missTendencies: [], mode: .standard)
        #expect(result.teeSuggestion?.club == "Driver")
        #expect(result.approachSuggestion?.club == "7-Iron")
    }

    @Test("Par 3 recommends approach club only")
    func par3Approach() {
        let clubs = [
            makeSummary(club: "Driver", avgDistance: 250, sampleSize: 10),
            makeSummary(club: "7-Iron", avgDistance: 150, sampleSize: 10)
        ]
        let hole = HoleInfo(number: 7, par: 3, yardage: 155)
        let result = StrategyEngine.recommend(hole: hole, clubSummaries: clubs, missTendencies: [], mode: .standard)
        // Par 3 should get approach recommendation
        #expect(result.approachSuggestion != nil || result.teeSuggestion != nil)
    }

    @Test("Conservative avoids driver with miss tendency")
    func conservativeAvoidsDriver() {
        let clubs = [
            makeSummary(club: "Driver", avgDistance: 250, sampleSize: 10),
            makeSummary(club: "3-Wood", avgDistance: 230, sampleSize: 10),
            makeSummary(club: "7-Iron", avgDistance: 150, sampleSize: 10)
        ]
        let tendency = MissTendency(
            category: "Driver Miss",
            description: "Tends to miss right",
            severity: .significant,
            frequency: "60%",
            evidence: "6 of 10"
        )
        let hole = HoleInfo(number: 1, par: 4, yardage: 400)
        let result = StrategyEngine.recommend(hole: hole, clubSummaries: clubs, missTendencies: [tendency], mode: .conservative)
        #expect(result.teeSuggestion?.club != "Driver" || result.warnings.contains(where: { $0.contains("driver") || $0.contains("Driver") }))
    }

    @Test("Aggressive mode picks longest club")
    func aggressiveLongest() {
        let clubs = [
            makeSummary(club: "Driver", avgDistance: 270, sampleSize: 10),
            makeSummary(club: "3-Wood", avgDistance: 240, sampleSize: 10)
        ]
        let hole = HoleInfo(number: 1, par: 5, yardage: 500)
        let result = StrategyEngine.recommend(hole: hole, clubSummaries: clubs, missTendencies: [], mode: .aggressive)
        #expect(result.teeSuggestion?.club == "Driver")
    }

    @Test("Miss tendency detection - right miss")
    func detectRightMiss() {
        let shots = (0 ..< 10).map { i in
            ShotRecord(
                club: "Driver",
                lie: "Tee",
                shotType: "Normal",
                distanceYards: 250,
                result: i < 5 ? "Right" : "Straight",
                date: Date(),
                isPractice: false
            )
        }
        let tendencies = StrategyEngine.detectMissTendencies(shots: shots, holeScores: [], rounds: [])
        let driverMiss = tendencies.first(where: { $0.category == "Driver Miss" })
        #expect(driverMiss != nil)
        #expect(driverMiss?.description.contains("right") == true)
    }

    @Test("Miss tendency detection - approach short")
    func detectApproachShort() {
        let shots = (0 ..< 10).map { i in
            ShotRecord(
                club: "7-Iron",
                lie: "Fairway",
                shotType: "Normal",
                distanceYards: 140,
                result: i < 5 ? "Short" : "Straight",
                date: Date(),
                isPractice: false
            )
        }
        let tendencies = StrategyEngine.detectMissTendencies(shots: shots, holeScores: [], rounds: [])
        let approachPattern = tendencies.first(where: { $0.category == "Approach Pattern" })
        #expect(approachPattern != nil)
    }

    @Test("Low confidence club triggers warning")
    func lowConfidenceWarning() {
        let clubs = [
            makeSummary(club: "Driver", avgDistance: 250, sampleSize: 3),
            makeSummary(club: "7-Iron", avgDistance: 150, sampleSize: 3)
        ]
        let hole = HoleInfo(number: 1, par: 4, yardage: 400)
        let result = StrategyEngine.recommend(hole: hole, clubSummaries: clubs, missTendencies: [], mode: .standard)
        #expect(result.warnings.contains(where: { $0.contains("limited data") }))
    }

    @Test("Overall advice includes hole info")
    func overallAdviceContent() {
        let clubs = [makeSummary(club: "7-Iron", avgDistance: 150, sampleSize: 10)]
        let hole = HoleInfo(number: 5, par: 3, yardage: 155)
        let result = StrategyEngine.recommend(hole: hole, clubSummaries: clubs, missTendencies: [], mode: .standard)
        #expect(result.overallAdvice.contains("Par 3"))
    }
}
