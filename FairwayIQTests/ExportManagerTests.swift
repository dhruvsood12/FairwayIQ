import Testing
@testable import FairwayIQ

@Suite("ExportManager Tests")
struct ExportManagerTests {

    @Test("Round summary text contains key fields")
    func roundSummaryText() {
        let summary = ExportableRoundSummary(
            courseName: "Pebble Beach",
            date: "March 15, 2025",
            totalScore: 82,
            relativeToPar: 10,
            totalPutts: 34,
            fairwaysHit: "8/14",
            gir: "7/18",
            penalties: 2,
            holeScores: [
                (1, 4, 5, 2),
                (2, 3, 3, 1),
            ],
            coachingHighlights: ["Reduce three-putts", "Strength: Clean card"],
            locationPrivacyNote: nil
        )
        let text = ExportManager.roundSummaryText(summary: summary)

        #expect(text.contains("Pebble Beach"))
        #expect(text.contains("82"))
        #expect(text.contains("+10"))
        #expect(text.contains("34"))
        #expect(text.contains("8/14"))
        #expect(text.contains("7/18"))
        #expect(text.contains("Reduce three-putts"))
        #expect(text.contains("FairwayIQ"))
    }

    @Test("Club gapping text contains club data")
    func clubGappingText() {
        let clubs = [
            ExportableClubSummary(clubName: "Driver", averageDistance: 250, medianDistance: 248, sampleSize: 20, consistency: "Consistent", confidence: "High"),
            ExportableClubSummary(clubName: "7-Iron", averageDistance: 155, medianDistance: 153, sampleSize: 15, consistency: "Moderate", confidence: "Moderate"),
        ]
        let text = ExportManager.clubGappingText(clubs: clubs, playerName: "Test Player")

        #expect(text.contains("Driver"))
        #expect(text.contains("250"))
        #expect(text.contains("7-Iron"))
        #expect(text.contains("155"))
        #expect(text.contains("Test Player"))
        #expect(text.contains("FairwayIQ"))
    }

    @Test("Stats snapshot text includes all fields")
    func statsSnapshotText() {
        let snapshot = ExportableStatsSnapshot(
            playerName: "Demo Player",
            handicapEstimate: 12.5,
            roundsPlayed: 10,
            averageScore: 85.3,
            fairwayPct: 55.0,
            girPct: 35.0,
            puttsPerRound: 33.2,
            bestScore: 78,
            generatedDate: "March 15, 2025"
        )
        let text = ExportManager.statsSnapshotText(snapshot: snapshot)

        #expect(text.contains("Demo Player"))
        #expect(text.contains("12.5"))
        #expect(text.contains("10"))
        #expect(text.contains("85.3"))
        #expect(text.contains("55%"))
        #expect(text.contains("35%"))
        #expect(text.contains("33.2"))
        #expect(text.contains("78"))
    }

    @Test("Stats snapshot handles nil best score")
    func statsSnapshotNilBest() {
        let snapshot = ExportableStatsSnapshot(
            playerName: "Test",
            handicapEstimate: 18.0,
            roundsPlayed: 0,
            averageScore: 0,
            fairwayPct: 0,
            girPct: 0,
            puttsPerRound: 0,
            bestScore: nil,
            generatedDate: "Test"
        )
        let text = ExportManager.statsSnapshotText(snapshot: snapshot)
        #expect(text.contains("—"))
    }

    @Test("Build club exports from summaries")
    func buildClubExports() {
        let summaries = [
            ClubSummary(
                clubName: "Driver",
                sampleSize: 20,
                averageDistance: 250,
                carryDistanceEstimate: 220,
                totalDistanceEstimate: 250,
                medianDistance: 248,
                minDistance: 230,
                maxDistance: 270,
                standardDeviation: 8,
                missLeftCount: 3,
                missRightCount: 5,
                missShortCount: 1,
                missLongCount: 2,
                totalMissCategorized: 11
            ),
        ]
        let exports = ExportManager.buildClubExports(summaries: summaries)
        #expect(exports.count == 1)
        #expect(exports[0].clubName == "Driver")
        #expect(exports[0].averageDistance == 250)
        #expect(exports[0].sampleSize == 20)
    }

    @Test("Round summary text scorecard is formatted")
    func scorecardFormatting() {
        let holes = (1...18).map { (hole: $0, par: $0 % 3 == 0 ? 3 : 4, score: 4 + ($0 % 3 == 0 ? -1 : 0), putts: 2) }
        let summary = ExportableRoundSummary(
            courseName: "Test Course",
            date: "Jan 1, 2025",
            totalScore: 72,
            relativeToPar: 0,
            totalPutts: 36,
            fairwaysHit: "10/14",
            gir: "12/18",
            penalties: 0,
            holeScores: holes,
            coachingHighlights: [],
            locationPrivacyNote: nil
        )
        let text = ExportManager.roundSummaryText(summary: summary)
        #expect(text.contains("Hole"))
        #expect(text.contains("Par"))
        #expect(text.contains("Score"))
    }

    @Test("Round export includes privacy note when location is hidden")
    func roundExportPrivacyNote() {
        let scores = (1...9).map { HoleScore(holeNumber: $0, strokes: 4, putts: 2, gir: $0 % 2 == 0, penalties: 0) }
        let round = Round(courseNameSnapshot: "Privacy Test", holeScores: scores)
        for score in scores { score.round = round }

        let export = ExportManager.buildRoundExport(
            round: round,
            coaching: nil,
            privacy: ExportPrivacyOptions(hideExactLocation: true, includeCoachingNotes: false)
        )

        #expect(export.locationPrivacyNote != nil)
        #expect(ExportManager.roundSummaryText(summary: export).contains("excluded"))
    }
}
