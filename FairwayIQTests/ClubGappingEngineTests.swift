@testable import FairwayIQ
import Foundation
import Testing

@Suite("ClubGappingEngine Tests")
struct ClubGappingEngineTests {
    private func makeShot(club: String, distance: Double?, lie: String = "Tee", result: String? = nil, isPractice: Bool = false) -> ShotRecord {
        ShotRecord(
            club: club,
            lie: lie,
            shotType: "Normal",
            distanceYards: distance,
            result: result,
            date: Date(),
            isPractice: isPractice
        )
    }

    @Test("Empty shots returns empty summaries")
    func emptyShotsReturnsEmpty() {
        let result = ClubGappingEngine.computeClubSummaries(shots: [])
        #expect(result.isEmpty)
    }

    @Test("Single shot produces valid summary")
    func singleShot() {
        let shots = [makeShot(club: "Driver", distance: 250)]
        let result = ClubGappingEngine.computeClubSummaries(shots: shots)
        #expect(result.count == 1)
        #expect(result[0].clubName == "Driver")
        #expect(result[0].sampleSize == 1)
        #expect(result[0].averageDistance == 250)
        #expect(result[0].confidence == .low)
    }

    @Test("Multiple clubs produce separate summaries")
    func multipleClubs() {
        let shots = [
            makeShot(club: "Driver", distance: 250),
            makeShot(club: "Driver", distance: 260),
            makeShot(club: "7-Iron", distance: 150),
            makeShot(club: "7-Iron", distance: 155)
        ]
        let result = ClubGappingEngine.computeClubSummaries(shots: shots)
        #expect(result.count == 2)
    }

    @Test("Average and median computed correctly")
    func averageAndMedian() {
        let shots = [
            makeShot(club: "7-Iron", distance: 140),
            makeShot(club: "7-Iron", distance: 150),
            makeShot(club: "7-Iron", distance: 160)
        ]
        let result = ClubGappingEngine.computeClubSummaries(shots: shots)
        #expect(result.count == 1)
        let club = result[0]
        #expect(club.averageDistance == 150.0)
        #expect(club.medianDistance == 150.0)
        #expect(club.minDistance == 140.0)
        #expect(club.maxDistance == 160.0)
    }

    @Test("Standard deviation is correct")
    func standardDeviation() {
        let shots = [
            makeShot(club: "PW", distance: 100),
            makeShot(club: "PW", distance: 110),
            makeShot(club: "PW", distance: 120)
        ]
        let result = ClubGappingEngine.computeClubSummaries(shots: shots)
        let club = result[0]
        let expectedVariance = (100.0 + 0.0 + 100.0) / 3.0
        let expectedStd = expectedVariance.squareRoot()
        #expect(abs(club.standardDeviation - expectedStd) < 0.01)
    }

    @Test("Confidence levels based on sample size")
    func confidenceLevels() {
        let lowShots = (0 ..< 3).map { _ in makeShot(club: "Driver", distance: 250) }
        let modShots = (0 ..< 8).map { _ in makeShot(club: "5-Iron", distance: 180) }
        let highShots = (0 ..< 20).map { _ in makeShot(club: "PW", distance: 120) }

        let all = lowShots + modShots + highShots
        let result = ClubGappingEngine.computeClubSummaries(shots: all)

        let driver = result.first(where: { $0.clubName == "Driver" })
        let iron5 = result.first(where: { $0.clubName == "5-Iron" })
        let pw = result.first(where: { $0.clubName == "PW" })

        #expect(driver?.confidence == .low)
        #expect(iron5?.confidence == .moderate)
        #expect(pw?.confidence == .high)
    }

    @Test("Miss tendency detected correctly")
    func missTendency() {
        let shots = (0 ..< 10).map { i in
            makeShot(club: "Driver", distance: 250, result: i < 6 ? "Right" : "Straight")
        }
        let result = ClubGappingEngine.computeClubSummaries(shots: shots)
        let club = result[0]
        #expect(club.missRightCount == 6)
        #expect(club.primaryMissTendency?.contains("right") == true)
    }

    @Test("Filter by practice only")
    func filterPracticeOnly() {
        let shots = [
            makeShot(club: "Driver", distance: 250, isPractice: false),
            makeShot(club: "Driver", distance: 260, isPractice: true)
        ]
        let filters = ClubGappingEngine.Filters(includePractice: true, includeRounds: false)
        let result = ClubGappingEngine.computeClubSummaries(shots: shots, filters: filters)
        #expect(result.count == 1)
        #expect(result[0].sampleSize == 1)
        #expect(result[0].averageDistance == 260)
    }

    @Test("Filter by recent days")
    func filterRecentDays() throws {
        let oldDate = try #require(Calendar.current.date(byAdding: .day, value: -60, to: Date()))
        let shots = [
            ShotRecord(club: "Driver", lie: "Tee", shotType: "Normal", distanceYards: 250, result: nil, date: oldDate, isPractice: false),
            makeShot(club: "Driver", distance: 260)
        ]
        let filters = ClubGappingEngine.Filters(recentDays: 30)
        let result = ClubGappingEngine.computeClubSummaries(shots: shots, filters: filters)
        #expect(result.count == 1)
        #expect(result[0].sampleSize == 1)
    }

    @Test("Nil distance handled gracefully")
    func nilDistance() {
        let shots = [
            makeShot(club: "Driver", distance: nil),
            makeShot(club: "Driver", distance: 250)
        ]
        let result = ClubGappingEngine.computeClubSummaries(shots: shots)
        #expect(result[0].averageDistance == 250)
        #expect(result[0].sampleSize == 2)
    }

    @Test("Consistency rating based on CV")
    func consistencyRating() {
        // Very consistent: low std dev relative to mean
        let shots = (0 ..< 10).map { _ in makeShot(club: "PW", distance: 120) }
        let result = ClubGappingEngine.computeClubSummaries(shots: shots)
        #expect(result[0].consistencyRating == "Very consistent")
    }

    @Test("Carry estimate is derived for tee shots")
    func carryEstimate() {
        let shots = (0 ..< 5).map { _ in makeShot(club: "Driver", distance: 250, lie: "Tee") }
        let result = ClubGappingEngine.computeClubSummaries(shots: shots)
        #expect(result[0].carryDistanceEstimate != nil)
        #expect((result[0].carryDistanceEstimate ?? 0) < result[0].totalDistanceEstimate ?? 0)
    }
}
