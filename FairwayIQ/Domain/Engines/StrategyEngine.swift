import Foundation

struct HoleInfo {
    let number: Int
    let par: Int
    let yardage: Int?
}

enum StrategyMode: String, CaseIterable, Identifiable {
    case conservative = "Conservative"
    case standard = "Standard"
    case aggressive = "Aggressive"

    var id: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .conservative: return "shield.fill"
        case .standard: return "flag.fill"
        case .aggressive: return "bolt.fill"
        }
    }
}

struct StrategyRecommendation: Identifiable {
    let id = UUID()
    let holeNumber: Int
    let teeSuggestion: ClubRecommendation?
    let approachSuggestion: ClubRecommendation?
    let warnings: [String]
    let overallAdvice: String
    let confidenceSummary: String
}

struct ClubRecommendation {
    let club: String
    let rationale: String
    let confidence: ClubConfidence
    let expectedDistance: Double?
}

struct MissTendency: Identifiable {
    let id = UUID()
    let category: String
    let description: String
    let severity: TendencySeverity
    let frequency: String
    let evidence: String
}

enum TendencySeverity: String {
    case mild = "Mild"
    case moderate = "Moderate"
    case significant = "Significant"

    var color: String {
        switch self {
        case .mild: return "yellow"
        case .moderate: return "orange"
        case .significant: return "red"
        }
    }
}

enum StrategyEngine {
    static func recommend(
        hole: HoleInfo,
        clubSummaries: [ClubSummary],
        missTendencies: [MissTendency],
        mode: StrategyMode
    ) -> StrategyRecommendation {
        guard let yardage = hole.yardage, yardage > 0 else {
            return StrategyRecommendation(
                holeNumber: hole.number,
                teeSuggestion: nil,
                approachSuggestion: nil,
                warnings: ["No yardage data available for this hole."],
                overallAdvice: "Play your standard game plan without yardage guidance.",
                confidenceSummary: "No hole yardage available"
            )
        }

        let usableSummaries = clubSummaries.filter { $0.sampleSize >= 2 && $0.averageDistance > 0 }
        var warnings: [String] = []

        if usableSummaries.isEmpty {
            return StrategyRecommendation(
                holeNumber: hole.number,
                teeSuggestion: nil,
                approachSuggestion: nil,
                warnings: ["Not enough shot data to make recommendations. Keep logging shots!"],
                overallAdvice: "Log more shots to unlock personalized strategy advice.",
                confidenceSummary: "Sparse player data"
            )
        }

        let tee = recommendTeeShot(
            hole: hole,
            yardage: yardage,
            clubs: usableSummaries,
            tendencies: missTendencies,
            mode: mode
        )

        let approach = recommendApproach(
            hole: hole,
            yardage: yardage,
            teeDistance: tee?.expectedDistance,
            clubs: usableSummaries,
            tendencies: missTendencies,
            mode: mode
        )

        if let teeClub = tee, teeClub.confidence < .moderate {
            warnings.append("Tee club recommendation is based on limited data.")
        }
        if let appClub = approach, appClub.confidence < .moderate {
            warnings.append("Approach club recommendation is based on limited data.")
        }

        let driverTendency = missTendencies.first { $0.category == "Driver Miss" && $0.severity == .significant }
        if driverTendency != nil, tee?.club == "Driver" {
            warnings.append("Consider your driver miss tendency on this hole.")
        }

        let advice = buildOverallAdvice(hole: hole, tee: tee, approach: approach, mode: mode, yardage: yardage)
        let confidenceSummary = buildConfidenceSummary(tee: tee, approach: approach, warnings: warnings)

        return StrategyRecommendation(
            holeNumber: hole.number,
            teeSuggestion: tee,
            approachSuggestion: approach,
            warnings: warnings,
            overallAdvice: advice,
            confidenceSummary: confidenceSummary
        )
    }

    static func detectMissTendencies(
        shots: [ShotRecord],
        holeScores: [HoleScore],
        rounds: [Round]
    ) -> [MissTendency] {
        var tendencies: [MissTendency] = []

        let teeShots = shots.filter { $0.lie == "Tee" }
        if teeShots.count >= 5 {
            let missRight = teeShots.filter { $0.result?.lowercased().contains("right") == true }
            let missLeft = teeShots.filter { $0.result?.lowercased().contains("left") == true }
            let rightPct = Double(missRight.count) / Double(teeShots.count)
            let leftPct = Double(missLeft.count) / Double(teeShots.count)

            if rightPct >= 0.4 {
                tendencies.append(MissTendency(
                    category: "Driver Miss",
                    description: "You tend to miss right off the tee",
                    severity: rightPct >= 0.6 ? .significant : .moderate,
                    frequency: "\(Int(rightPct * 100))% of tee shots",
                    evidence: "\(missRight.count) of \(teeShots.count) tee shots missed right"
                ))
            }
            if leftPct >= 0.4 {
                tendencies.append(MissTendency(
                    category: "Driver Miss",
                    description: "You tend to miss left off the tee",
                    severity: leftPct >= 0.6 ? .significant : .moderate,
                    frequency: "\(Int(leftPct * 100))% of tee shots",
                    evidence: "\(missLeft.count) of \(teeShots.count) tee shots missed left"
                ))
            }
        }

        let approachShots = shots.filter { $0.lie == "Fairway" || $0.lie == "Rough" }
        if approachShots.count >= 5 {
            let shortMisses = approachShots.filter { $0.result?.lowercased().contains("short") == true }
            let rightMisses = approachShots.filter { $0.result?.lowercased().contains("right") == true }
            let shortPct = Double(shortMisses.count) / Double(approachShots.count)
            if shortPct >= 0.35 {
                tendencies.append(MissTendency(
                    category: "Approach Pattern",
                    description: "Approach shots often come up short",
                    severity: shortPct >= 0.55 ? .significant : .moderate,
                    frequency: "\(Int(shortPct * 100))% of approaches",
                    evidence: "\(shortMisses.count) of \(approachShots.count) approaches missed short"
                ))
            }
            let rightPct = Double(rightMisses.count) / Double(approachShots.count)
            if rightPct >= 0.35 {
                tendencies.append(MissTendency(
                    category: "Approach Pattern",
                    description: "Approach shots leak right",
                    severity: rightPct >= 0.55 ? .significant : .moderate,
                    frequency: "\(Int(rightPct * 100))% of approaches",
                    evidence: "\(rightMisses.count) of \(approachShots.count) approaches missed right"
                ))
            }
        }

        if !rounds.isEmpty {
            let totalPutts = rounds.reduce(0) { $0 + $1.totalPutts }
            let avgPutts = Double(totalPutts) / Double(rounds.count)
            let threePuttHoles = holeScores.count(where: { $0.putts >= 3 })
            let totalHoles = holeScores.count
            if totalHoles >= 18 {
                let threePuttRate = Double(threePuttHoles) / Double(totalHoles)
                if threePuttRate >= 0.15 {
                    tendencies.append(MissTendency(
                        category: "Putting",
                        description: "High 3-putt rate is costing strokes",
                        severity: threePuttRate >= 0.25 ? .significant : .moderate,
                        frequency: String(format: "%.0f%% of holes", threePuttRate * 100),
                        evidence: "\(threePuttHoles) three-putts across \(totalHoles) holes (avg \(String(format: "%.1f", avgPutts)) putts/round)"
                    ))
                }
            }
        }

        let par4and5Scores = holeScores.filter { score in
            guard let round = score.round, let course = round.course else { return false }
            let holePar = course.holes.first(where: { $0.number == score.holeNumber })?.par ?? 4
            return holePar >= 4
        }
        if par4and5Scores.count >= 10 {
            let penaltyHoles = par4and5Scores.filter { $0.penalties > 0 }
            let penaltyRate = Double(penaltyHoles.count) / Double(par4and5Scores.count)
            if penaltyRate >= 0.2 {
                tendencies.append(MissTendency(
                    category: "Penalties",
                    description: "Penalties are frequent on longer holes",
                    severity: penaltyRate >= 0.35 ? .significant : .moderate,
                    frequency: String(format: "%.0f%% of par 4/5 holes", penaltyRate * 100),
                    evidence: "\(penaltyHoles.count) penalty holes out of \(par4and5Scores.count) par 4/5 holes"
                ))
            }
        }

        return tendencies
    }

    private static func recommendTeeShot(
        hole: HoleInfo,
        yardage: Int,
        clubs: [ClubSummary],
        tendencies: [MissTendency],
        mode: StrategyMode
    ) -> ClubRecommendation? {
        guard hole.par >= 4 else {
            return recommendClubForDistance(Double(yardage), clubs: clubs, mode: mode, context: "tee shot on par 3")
        }

        let driverMiss = tendencies.first { $0.category == "Driver Miss" && $0.severity != .mild }

        switch mode {
        case .conservative:
            let targetDistance = Double(yardage) * 0.6
            if driverMiss != nil {
                let safeClubs = clubs.filter { $0.clubName != "Driver" && $0.averageDistance >= targetDistance * 0.8 }
                if let best = safeClubs.first {
                    return ClubRecommendation(
                        club: best.clubName,
                        rationale: "Avoids your \(driverMiss!.description.lowercased()). Leaves a comfortable approach.",
                        confidence: best.confidence,
                        expectedDistance: best.averageDistance
                    )
                }
            }
            return recommendClubForDistance(targetDistance, clubs: clubs, mode: mode, context: "conservative tee shot")

        case .standard:
            if driverMiss != nil, driverMiss!.severity == .significant {
                let alt = clubs.filter { $0.clubName != "Driver" }
                    .max(by: { $0.averageDistance < $1.averageDistance })
                if let alt {
                    return ClubRecommendation(
                        club: alt.clubName,
                        rationale: "Your safer long option. Driver miss pattern is significant.",
                        confidence: alt.confidence,
                        expectedDistance: alt.averageDistance
                    )
                }
            }
            let driver = clubs.first(where: { $0.clubName == "Driver" })
            if let driver {
                return ClubRecommendation(
                    club: driver.clubName,
                    rationale: "Standard play: maximize distance off the tee.",
                    confidence: driver.confidence,
                    expectedDistance: driver.averageDistance
                )
            }
            let longest = clubs.max(by: { $0.averageDistance < $1.averageDistance })
            return longest.map {
                ClubRecommendation(club: $0.clubName, rationale: "Your longest club with data.", confidence: $0.confidence, expectedDistance: $0.averageDistance)
            }

        case .aggressive:
            let driver = clubs.first(where: { $0.clubName == "Driver" })
                ?? clubs.max(by: { $0.averageDistance < $1.averageDistance })
            return driver.map {
                ClubRecommendation(club: $0.clubName, rationale: "Aggressive: max distance off the tee.", confidence: $0.confidence, expectedDistance: $0.averageDistance)
            }
        }
    }

    private static func recommendApproach(
        hole: HoleInfo,
        yardage: Int,
        teeDistance: Double?,
        clubs: [ClubSummary],
        tendencies _: [MissTendency],
        mode: StrategyMode
    ) -> ClubRecommendation? {
        let remaining = if hole.par >= 4, let teeDist = teeDistance {
            Double(yardage) - teeDist
        } else {
            Double(yardage)
        }
        guard remaining > 5 else { return nil }

        return recommendClubForDistance(remaining, clubs: clubs, mode: mode, context: "approach from \(Int(remaining)) yards")
    }

    private static func recommendClubForDistance(
        _ targetDistance: Double,
        clubs: [ClubSummary],
        mode _: StrategyMode,
        context: String
    ) -> ClubRecommendation? {
        let candidates = clubs.map { club -> (ClubSummary, Double) in
            let diff = abs(club.averageDistance - targetDistance)
            return (club, diff)
        }.sorted { $0.1 < $1.1 }

        guard let best = candidates.first else { return nil }
        let club = best.0

        let overUnder = if club.averageDistance > targetDistance + 5 {
            "slightly more club than needed"
        } else if club.averageDistance < targetDistance - 5 {
            "slightly less club than needed"
        } else {
            "matches the distance well"
        }

        return ClubRecommendation(
            club: club.clubName,
            rationale: "Your \(club.clubName) averages \(Int(club.averageDistance)) yards — \(overUnder) for this \(context).",
            confidence: club.confidence,
            expectedDistance: club.averageDistance
        )
    }

    private static func buildOverallAdvice(
        hole: HoleInfo,
        tee: ClubRecommendation?,
        approach: ClubRecommendation?,
        mode: StrategyMode,
        yardage: Int
    ) -> String {
        var parts: [String] = []

        switch hole.par {
        case 3:
            parts.append("Par 3, \(yardage) yards.")
            if let app = approach {
                parts.append("Your \(app.club) is the best fit here.")
            }
        case 4:
            parts.append("Par 4, \(yardage) yards.")
            if let tee, let app = approach {
                parts.append("Hit \(tee.club) off the tee, then \(app.club) to the green.")
            }
        case 5:
            parts.append("Par 5, \(yardage) yards.")
            if mode == .aggressive {
                parts.append("Going for the green in two is an option with enough distance.")
            } else {
                parts.append("Lay up to a comfortable wedge distance for a birdie putt.")
            }
        default:
            parts.append("Play smart and focus on position.")
        }

        return parts.joined(separator: " ")
    }

    private static func buildConfidenceSummary(
        tee: ClubRecommendation?,
        approach: ClubRecommendation?,
        warnings: [String]
    ) -> String {
        let confidenceLevels = [tee?.confidence, approach?.confidence].compactMap(\.self)
        let lowest = confidenceLevels.min() ?? .noData

        if warnings.isEmpty, lowest >= .moderate {
            return "Built from solid club data"
        }

        switch lowest {
        case .high:
            return "Good fit, but watch the warning notes"
        case .moderate:
            return "Reasonable recommendation with moderate confidence"
        case .low:
            return "Directional only because of limited samples"
        case .noData:
            return "Not enough data for confidence"
        }
    }
}
