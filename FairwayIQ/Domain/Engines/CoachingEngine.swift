import Foundation

struct CoachingSummary {
    let strengths: [CoachingInsight]
    let weaknesses: [CoachingInsight]
    let strokeCostBreakdown: [StrokeCost]
    let actionItems: [String]
    let overallAssessment: String
}

struct CoachingInsight: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let metric: String?
    let isPositive: Bool
}

struct StrokeCost: Identifiable {
    let id = UUID()
    let category: String
    let estimatedStrokesLost: Double
    let description: String
}

struct RoundBaseline {
    let averageScore: Double
    let averagePutts: Double
    let averageGIR: Double
    let averageFairwayPct: Double
    let averagePenalties: Double
    let roundCount: Int
}

enum CoachingEngine {
    static func analyze(
        round: Round,
        baseline: RoundBaseline?
    ) -> CoachingSummary {
        var strengths: [CoachingInsight] = []
        var weaknesses: [CoachingInsight] = []
        var strokeCosts: [StrokeCost] = []
        var actions: [String] = []

        let scores = round.holeScores.sorted { $0.holeNumber < $1.holeNumber }
        guard !scores.isEmpty else {
            return CoachingSummary(
                strengths: [],
                weaknesses: [],
                strokeCostBreakdown: [],
                actionItems: ["Complete a round to see coaching insights."],
                overallAssessment: "No hole data available for analysis."
            )
        }

        let totalPutts = round.totalPutts
        let totalPenalties = scores.reduce(0) { $0 + $1.penalties }
        let holeCount = scores.count
        let puttsPerHole = Double(totalPutts) / Double(holeCount)
        let threePutts = scores.count(where: { $0.putts >= 3 })
        let onePutts = scores.count(where: { $0.putts == 1 })
        let girCount = scores.filter(\.gir).count
        let girPct = Double(girCount) / Double(holeCount) * 100
        let fairwayScores = scores.filter { $0.fairwayHit != nil }
        let fairwayHits = fairwayScores.count(where: { $0.fairwayHit == true })
        let fairwayPct = fairwayScores.isEmpty ? 0 : Double(fairwayHits) / Double(fairwayScores.count) * 100

        if threePutts >= 3 {
            let cost = Double(threePutts)
            weaknesses.append(CoachingInsight(
                title: "3-putt troubles",
                detail: "\(threePutts) three-putts cost you approximately \(threePutts) strokes.",
                metric: "\(threePutts) three-putts",
                isPositive: false
            ))
            strokeCosts.append(StrokeCost(category: "Three-putts", estimatedStrokesLost: cost, description: "\(threePutts) extra putts from three-putting"))
            actions.append("Focus on lag putting to reduce three-putts. Aim to get first putts within 3 feet.")
        } else if threePutts == 0 {
            strengths.append(CoachingInsight(
                title: "Clean putting",
                detail: "No three-putts this round: solid green reading and distance control.",
                metric: "0 three-putts",
                isPositive: true
            ))
        }

        if onePutts >= 5 {
            strengths.append(CoachingInsight(
                title: "Short game saves",
                detail: "\(onePutts) one-putts shows strong conversion around the green.",
                metric: "\(onePutts) one-putts",
                isPositive: true
            ))
        }

        if let base = baseline, base.roundCount >= 3 {
            let girDiff = girPct - base.averageGIR
            if girDiff > 5 {
                strengths.append(CoachingInsight(
                    title: "Greens in regulation improved",
                    detail: String(format: "%.0f%% GIR this round vs your %.0f%% average. Iron play was sharp.", girPct, base.averageGIR),
                    metric: String(format: "%.0f%%", girPct),
                    isPositive: true
                ))
            } else if girDiff < -10 {
                weaknesses.append(CoachingInsight(
                    title: "GIR below your average",
                    detail: String(format: "%.0f%% GIR vs %.0f%% average. Approach shots let you down.", girPct, base.averageGIR),
                    metric: String(format: "%.0f%%", girPct),
                    isPositive: false
                ))
                let missedGIRCost = abs(girDiff) / 100.0 * Double(holeCount) * 0.5
                strokeCosts.append(StrokeCost(category: "Missed Greens", estimatedStrokesLost: missedGIRCost, description: "Below-average approach accuracy"))
                actions.append("Work on approach distances. Check your club gapping for the 100-150 yard range.")
            }
        } else if girPct < 25, holeCount >= 9 {
            weaknesses.append(CoachingInsight(
                title: "Low GIR",
                detail: String(format: "Only %.0f%% greens in regulation. Focus on approach accuracy.", girPct),
                metric: String(format: "%.0f%%", girPct),
                isPositive: false
            ))
            actions.append("Practice approach shots to your most common yardages.")
        }

        if totalPenalties >= 3 {
            weaknesses.append(CoachingInsight(
                title: "Penalties added up",
                detail: "\(totalPenalties) penalty strokes significantly impacted your score.",
                metric: "\(totalPenalties) penalties",
                isPositive: false
            ))
            strokeCosts.append(StrokeCost(category: "Penalties", estimatedStrokesLost: Double(totalPenalties), description: "\(totalPenalties) penalty strokes"))
            actions.append("Identify where penalties occurred. Consider playing safer off the tee on trouble holes.")
        } else if totalPenalties == 0 {
            strengths.append(CoachingInsight(
                title: "Clean card",
                detail: "No penalties this round. Smart, disciplined play.",
                metric: "0 penalties",
                isPositive: true
            ))
        }

        if fairwayPct >= 65, fairwayScores.count >= 8 {
            strengths.append(CoachingInsight(
                title: "Finding fairways",
                detail: String(format: "%.0f%% fairways hit, giving yourself good looks at greens.", fairwayPct),
                metric: "\(fairwayHits)/\(fairwayScores.count)",
                isPositive: true
            ))
        } else if fairwayPct < 40, fairwayScores.count >= 8 {
            weaknesses.append(CoachingInsight(
                title: "Missing fairways",
                detail: String(format: "Only %.0f%% fairways hit. This makes GIR harder and penalties more likely.", fairwayPct),
                metric: "\(fairwayHits)/\(fairwayScores.count)",
                isPositive: false
            ))
            actions.append("Consider hitting 3-wood or long iron off the tee for better accuracy.")
        }

        let bestStretch = findBestStretch(scores: scores, windowSize: 3, round: round)
        let worstStretch = findWorstStretch(scores: scores, windowSize: 3, round: round)

        if let best = bestStretch {
            strengths.append(CoachingInsight(
                title: "Best stretch: Holes \(best.startHole)-\(best.endHole)",
                detail: "\(best.totalRelativeToPar >= 0 ? "+" : "")\(best.totalRelativeToPar) over \(best.endHole - best.startHole + 1) holes.",
                metric: "\(best.totalRelativeToPar >= 0 ? "+" : "")\(best.totalRelativeToPar)",
                isPositive: true
            ))
        }
        if let worst = worstStretch {
            weaknesses.append(CoachingInsight(
                title: "Worst stretch: Holes \(worst.startHole)-\(worst.endHole)",
                detail: "+\(worst.totalRelativeToPar) over \(worst.endHole - worst.startHole + 1) holes. What went wrong here?",
                metric: "+\(worst.totalRelativeToPar)",
                isPositive: false
            ))
        }

        if let base = baseline, base.roundCount >= 3 {
            let scoreDiff = Double(round.totalStrokes) - base.averageScore
            if scoreDiff < -2 {
                strengths.append(CoachingInsight(
                    title: "Better than your average",
                    detail: String(format: "Shot %d, which is %.1f strokes better than your %.1f average.", round.totalStrokes, abs(scoreDiff), base.averageScore),
                    metric: String(format: "%.1f better", abs(scoreDiff)),
                    isPositive: true
                ))
            } else if scoreDiff > 3 {
                weaknesses.append(CoachingInsight(
                    title: "Above your average",
                    detail: String(format: "Shot %d, which is %.1f strokes above your %.1f average.", round.totalStrokes, scoreDiff, base.averageScore),
                    metric: String(format: "+%.1f strokes", scoreDiff),
                    isPositive: false
                ))
            }
        }

        let assessment = buildAssessment(
            score: round.totalStrokes,
            par: round.totalPar,
            strengths: strengths,
            weaknesses: weaknesses
        )

        let limitedStrengths = Array(strengths.prefix(5))
        let limitedWeaknesses = Array(weaknesses.prefix(5))
        let limitedActions = Array(actions.prefix(5))

        return CoachingSummary(
            strengths: limitedStrengths,
            weaknesses: limitedWeaknesses,
            strokeCostBreakdown: strokeCosts.sorted { $0.estimatedStrokesLost > $1.estimatedStrokesLost },
            actionItems: limitedActions,
            overallAssessment: assessment
        )
    }

    static func computeBaseline(from rounds: [Round]) -> RoundBaseline? {
        guard !rounds.isEmpty else { return nil }
        let count = Double(rounds.count)
        let avgScore = Double(rounds.map(\.totalStrokes).reduce(0, +)) / count
        let avgPutts = Double(rounds.map(\.totalPutts).reduce(0, +)) / count

        let allScores = rounds.flatMap(\.holeScores)
        let girCount = allScores.filter(\.gir).count
        let totalHoles = allScores.count
        let avgGIR = totalHoles > 0 ? Double(girCount) / Double(totalHoles) * 100 : 0

        let fairwayScores = allScores.filter { $0.fairwayHit != nil }
        let fairwayHits = fairwayScores.count(where: { $0.fairwayHit == true })
        let avgFairway = fairwayScores.isEmpty ? 0 : Double(fairwayHits) / Double(fairwayScores.count) * 100

        let totalPens = allScores.reduce(0) { $0 + $1.penalties }
        let avgPen = Double(totalPens) / count

        return RoundBaseline(
            averageScore: avgScore,
            averagePutts: avgPutts,
            averageGIR: avgGIR,
            averageFairwayPct: avgFairway,
            averagePenalties: avgPen,
            roundCount: rounds.count
        )
    }

    private struct StretchResult {
        let startHole: Int
        let endHole: Int
        let totalRelativeToPar: Int
    }

    private static func findBestStretch(scores: [HoleScore], windowSize: Int, round: Round) -> StretchResult? {
        guard scores.count >= windowSize else { return nil }
        var best: StretchResult?
        for i in 0 ... (scores.count - windowSize) {
            let window = Array(scores[i ..< (i + windowSize)])
            let pars = window.map { round.par(forHole: $0.holeNumber) }
            guard !pars.contains(nil) else { continue }
            let relToPar = zip(window, pars).reduce(0) { total, pair in
                total + (pair.0.strokes - (pair.1 ?? 0))
            }
            guard let firstHole = window.first, let lastHole = window.last else { continue }
            if best.map({ relToPar < $0.totalRelativeToPar }) ?? true {
                best = StretchResult(startHole: firstHole.holeNumber, endHole: lastHole.holeNumber, totalRelativeToPar: relToPar)
            }
        }
        return best
    }

    private static func findWorstStretch(scores: [HoleScore], windowSize: Int, round: Round) -> StretchResult? {
        guard scores.count >= windowSize else { return nil }
        var worst: StretchResult?
        for i in 0 ... (scores.count - windowSize) {
            let window = Array(scores[i ..< (i + windowSize)])
            let pars = window.map { round.par(forHole: $0.holeNumber) }
            guard !pars.contains(nil) else { continue }
            let relToPar = zip(window, pars).reduce(0) { total, pair in
                total + (pair.0.strokes - (pair.1 ?? 0))
            }
            guard let firstHole = window.first, let lastHole = window.last else { continue }
            if worst.map({ relToPar > $0.totalRelativeToPar }) ?? true {
                worst = StretchResult(startHole: firstHole.holeNumber, endHole: lastHole.holeNumber, totalRelativeToPar: relToPar)
            }
        }
        return (worst?.totalRelativeToPar ?? 0) > 0 ? worst : nil
    }

    private static func buildAssessment(
        score: Int,
        par: Int?,
        strengths: [CoachingInsight],
        weaknesses: [CoachingInsight]
    ) -> String {
        guard let par else {
            var assessment = "Scored \(score). Par for this course is not on record, so the round is judged against your own history."
            if strengths.count > weaknesses.count {
                assessment += " More positives than negatives today."
            } else if weaknesses.count > strengths.count + 1 {
                assessment += " Focus on the action items below to save strokes next time."
            }
            return assessment
        }
        let diff = score - par
        var assessment = if diff <= 0 {
            "Outstanding round at or under par."
        } else if diff <= 5 {
            "Solid round, staying close to par."
        } else if diff <= 10 {
            "Decent round with room to improve."
        } else if diff <= 18 {
            "Tough round, but there are clear areas to work on."
        } else {
            "A challenging day on the course."
        }

        if strengths.count > weaknesses.count {
            assessment += " More positives than negatives today."
        } else if weaknesses.count > strengths.count + 1 {
            assessment += " Focus on the action items below to save strokes next time."
        }

        return assessment
    }
}
