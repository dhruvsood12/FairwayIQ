//
//  UserProfile.swift
//  FairwayIQ
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    var playerName: String
    var skillLevel: String
    var handicapEstimate: Double
    var preferredUnits: String
    var homeCourseId: String?
    var clubsInBag: String
    var hasCompletedOnboarding: Bool
    var createdAt: Date
    var updatedAt: Date

    var clubsList: [String] {
        get {
            guard !clubsInBag.isEmpty else { return [] }
            return clubsInBag.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }.filter { !$0.isEmpty }
        }
        set {
            clubsInBag = newValue.joined(separator: ", ")
        }
    }

    init(
        playerName: String = "",
        skillLevel: String = "Intermediate",
        handicapEstimate: Double = 18.0,
        preferredUnits: String = "yards",
        homeCourseId: String? = nil,
        clubsInBag: String = "Driver, 3-Wood, 5-Wood, 4-Iron, 5-Iron, 6-Iron, 7-Iron, 8-Iron, 9-Iron, PW, SW, Putter",
        hasCompletedOnboarding: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.playerName = playerName
        self.skillLevel = skillLevel
        self.handicapEstimate = handicapEstimate
        self.preferredUnits = preferredUnits
        self.homeCourseId = homeCourseId
        self.clubsInBag = clubsInBag
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
