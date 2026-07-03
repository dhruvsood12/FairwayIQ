//
//  SampleData.swift
//  FairwayIQ
//

import Foundation
import SwiftData

enum SampleData {
    static func createSampleHoles(count: Int = 18) -> [Hole] {
        let pars = [4, 4, 3, 5, 4, 4, 3, 5, 4, 4, 4, 3, 5, 4, 4, 3, 5, 4]
        return (0 ..< min(count, pars.count)).map { i in
            Hole(number: i + 1, par: pars[i], handicapIndex: i + 1)
        }
    }

    static func createSampleCourses(modelContext: ModelContext) -> [Course] {
        let holes1 = createSampleHoles(count: 18)
        let links = Course(
            id: "sample-links",
            name: "Sample Links",
            city: "Sampleton",
            state: "CA",
            kind: "Sample",
            holes: []
        )
        modelContext.insert(links)
        for hole in holes1 {
            modelContext.insert(hole)
            links.holes.append(hole)
        }

        let holes2 = createSampleHoles(count: 18)
        let parkland = Course(
            id: "sample-parkland",
            name: "Sample Parkland",
            city: "Sampleton",
            state: "GA",
            kind: "Sample",
            holes: []
        )
        modelContext.insert(parkland)
        for hole in holes2 {
            modelContext.insert(hole)
            parkland.holes.append(hole)
        }

        let holes3 = createSampleHoles(count: 9)
        let local = Course(
            id: "sample-muni-nine",
            name: "Sample Muni Nine",
            city: "Sampleton",
            state: "CA",
            kind: "Sample",
            holes: []
        )
        modelContext.insert(local)
        for hole in holes3 {
            modelContext.insert(hole)
            local.holes.append(hole)
        }

        try? modelContext.save()
        return [links, parkland, local]
    }

    static func createSampleRounds(modelContext: ModelContext, course: Course) -> Round {
        let holeCount = max(1, course.holes.count)
        let holeScores: [HoleScore] = (1 ... holeCount).map { num in
            let par = [4, 4, 3, 5, 4, 4, 3, 5, 4, 4, 4, 3, 5, 4, 4, 3, 5, 4][num - 1]
            let strokes = par + Int.random(in: -1 ... 2)
            let putts = min(strokes, Int.random(in: 1 ... 3))
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
            course: course,
            courseNameSnapshot: course.name,
            teeBox: "Blue",
            date: Date().addingTimeInterval(-Double.random(in: 1 ... 14) * 86400),
            weather: "Sunny",
            playingPartners: nil,
            holeScores: holeScores,
            shots: [],
            createdAt: Date()
        )
        modelContext.insert(round)
        try? modelContext.save()
        return round
    }

    static func createOrUpdateSampleUser(modelContext: ModelContext) -> UserProfile {
        var descriptor = FetchDescriptor<UserProfile>()
        descriptor.fetchLimit = 1
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let homeCourse = (try? modelContext.fetch(FetchDescriptor<Course>(
            predicate: #Predicate { $0.id == "sample-links" }
        )))?.first
        let profile = UserProfile(
            playerName: "Demo Player",
            skillLevel: "Intermediate",
            handicapEstimate: 12.0,
            preferredUnits: "yards",
            homeCourse: homeCourse,
            hasCompletedOnboarding: true
        )
        modelContext.insert(profile)
        try? modelContext.save()
        return profile
    }

    static func seedIfNeeded(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Course>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        if existing.isEmpty {
            _ = createSampleCourses(modelContext: modelContext)
            let courses = (try? modelContext.fetch(FetchDescriptor<Course>())) ?? []
            for course in courses.prefix(2) {
                _ = createSampleRounds(modelContext: modelContext, course: course)
            }
        }
    }

    /// Call when you want demo data with a pre-filled profile (e.g. for screenshots).
    static func ensureDemoProfile(modelContext: ModelContext) {
        _ = createOrUpdateSampleUser(modelContext: modelContext)
    }
}
