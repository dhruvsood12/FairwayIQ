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
    var hasCompletedOnboarding: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        playerName: String = "",
        skillLevel: String = "Intermediate",
        handicapEstimate: Double = 18.0,
        preferredUnits: String = "yards",
        homeCourseId: String? = nil,
        hasCompletedOnboarding: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.playerName = playerName
        self.skillLevel = skillLevel
        self.handicapEstimate = handicapEstimate
        self.preferredUnits = preferredUnits
        self.homeCourseId = homeCourseId
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
