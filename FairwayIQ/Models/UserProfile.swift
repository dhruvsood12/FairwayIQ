//
//  UserProfile.swift
//  FairwayIQ
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique)
    var id: UUID
    var playerName: String
    var skillLevel: String
    var handicapEstimate: Double
    var preferredUnits: String
    var homeCourse: Course?
    var clubsInBag: String
    var hasCompletedOnboarding: Bool
    var hideExactLocationInExports: Bool
    var preferManualLocationLogging: Bool
    var preferredStrategyModeRaw: String
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

    var preferredStrategyMode: StrategyMode {
        get { StrategyMode(rawValue: preferredStrategyModeRaw) ?? .standard }
        set { preferredStrategyModeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        playerName: String = "",
        skillLevel: String = "Intermediate",
        handicapEstimate: Double = 18.0,
        preferredUnits: String = "yards",
        homeCourse: Course? = nil,
        clubsInBag: String = "Driver, 3-Wood, 5-Wood, 4-Iron, 5-Iron, 6-Iron, 7-Iron, 8-Iron, 9-Iron, PW, SW, Putter",
        hasCompletedOnboarding: Bool = false,
        hideExactLocationInExports: Bool = true,
        preferManualLocationLogging: Bool = false,
        preferredStrategyModeRaw: String = StrategyMode.standard.rawValue,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.playerName = playerName
        self.skillLevel = skillLevel
        self.handicapEstimate = handicapEstimate
        self.preferredUnits = preferredUnits
        self.homeCourse = homeCourse
        self.clubsInBag = clubsInBag
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hideExactLocationInExports = hideExactLocationInExports
        self.preferManualLocationLogging = preferManualLocationLogging
        self.preferredStrategyModeRaw = preferredStrategyModeRaw
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
