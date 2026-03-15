//
//  SampleData.swift
//  FairwayIQ
//

import Foundation
import SwiftData

enum SampleData {

    static func createSampleHoles(count: Int = 18) -> [Hole] {
        let pars = [4, 4, 3, 5, 4, 4, 3, 5, 4, 4, 4, 3, 5, 4, 4, 3, 5, 4]
        return (0..<min(count, pars.count)).map { i in
            Hole(number: i + 1, par: pars[i], handicapIndex: i + 1)
        }
    }

    static func createSampleCourses(modelContext: ModelContext) -> [Course] {
        let holes1 = createSampleHoles(18)
        let pebble = Course(
            id: "pebble-beach",
            name: "Pebble Beach Golf Links",
            locationName: "Pebble Beach, CA",
            latitude: 36.5674,
            longitude: -121.9500,
            holes: []
        )
        modelContext.insert(pebble)
        for h in holes1 {
            modelContext.insert(h)
            h.course = pebble
            pebble.holes.append(h)
        }

        let holes2 = createSampleHoles(18)
        let augusta = Course(
            id: "augusta-national",
            name: "Augusta National",
            locationName: "Augusta, GA",
            latitude: 33.5023,
            longitude: -82.0197,
            holes: []
        )
        modelContext.insert(augusta)
        for h in holes2 {
            modelContext.insert(h)
            h.course = augusta
            augusta.holes.append(h)
        }

        let holes3 = createSampleHoles(9)
        let local = Course(
            id: "local-muni",
            name: "Riverside Municipal",
            locationName: "Local",
            latitude: nil,
            longitude: nil,
            holes: []
        )
        modelContext.insert(local)
        for h in holes3 {
            modelContext.insert(h)
            h.course = local
            local.holes.append(h)
        }

        try? modelContext.save()
        return [pebble, augusta, local]
    }

    static func createSampleRounds(modelContext: ModelContext, courseId: String, courseName: String) -> Round {
        let holeScores: [HoleScore] = (1...18).map { num in
            let par = [4, 4, 3, 5, 4, 4, 3, 5, 4, 4, 4, 3, 5, 4, 4, 3, 5, 4][num - 1]
            let strokes = par + Int.random(in: -1...2)
            let putts = min(strokes, Int.random(in: 1...3))
            let fairway: Bool? = (par >= 4) ? Bool.random() : nil
            let gir = strokes <= par && Bool.random()
            let score = HoleScore(
                holeNumber: num,
                strokes: strokes,
                putts: putts,
                fairwayHit: fairway,
                gir: gir,
                penalties: Bool.random() ? 1 : 0
            )
            modelContext.insert(score)
            return score
        }
        let round = Round(
            courseId: courseId,
            courseName: courseName,
            teeBox: "Blue",
            date: Date().addingTimeInterval(-Double.random(in: 1...14) * 86400),
            weather: "Sunny",
            playingPartners: nil,
            holeScores: holeScores,
            shots: [],
            createdAt: Date()
        )
        for s in holeScores { s.round = round }
        modelContext.insert(round)
        try? modelContext.save()
        return round
    }

    static func createSampleFriendEntries(modelContext: ModelContext) -> [FriendEntry] {
        let names = [
            ("Alex Chen", 72, 75, 76.2, 8.5),
            ("Jordan Smith", 74, 78, 77.8, 12.0),
            ("Sam Williams", 71, 73, 74.5, 6.2),
            ("Casey Davis", 76, 79, 78.0, 14.0),
            ("Riley Brown", 73, 76, 75.5, 10.0)
        ]
        var entries: [FriendEntry] = []
        for (index, n) in names.enumerated() {
            let e = FriendEntry(
                id: "friend-\(index)",
                displayName: n.0,
                weeklyBestScore: n.1,
                latestRoundScore: n.2,
                averageScore: n.3,
                handicapEstimate: n.4,
                sortOrder: index
            )
            modelContext.insert(e)
            entries.append(e)
        }
        try? modelContext.save()
        return entries
    }

    static func createOrUpdateSampleUser(modelContext: ModelContext) -> UserProfile {
        var descriptor = FetchDescriptor<UserProfile>()
        descriptor.fetchLimit = 1
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let profile = UserProfile(
            playerName: "Demo Player",
            skillLevel: "Intermediate",
            handicapEstimate: 12.0,
            preferredUnits: "yards",
            homeCourseId: "pebble-beach",
            hasCompletedOnboarding: true
        )
        modelContext.insert(profile)
        try? modelContext.save()
        return profile
    }

    static func seedIfNeeded(modelContext: ModelContext) {
        var descriptor = FetchDescriptor<Course>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        if existing.isEmpty {
            _ = createSampleCourses(modelContext: modelContext)
            _ = createSampleFriendEntries(modelContext: modelContext)
            let courses = (try? modelContext.fetch(FetchDescriptor<Course>())) ?? []
            for c in courses.prefix(2) {
                _ = createSampleRounds(modelContext: modelContext, courseId: c.id, courseName: c.name)
            }
        }
    }

    /// Call when you want demo data with a pre-filled profile (e.g. for screenshots).
    static func ensureDemoProfile(modelContext: ModelContext) {
        _ = createOrUpdateSampleUser(modelContext: modelContext)
    }
}
