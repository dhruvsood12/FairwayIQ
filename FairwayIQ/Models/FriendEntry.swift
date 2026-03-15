//
//  FriendEntry.swift
//  FairwayIQ
//

import Foundation
import SwiftData

@Model
final class FriendEntry {
    var id: String
    var displayName: String
    var weeklyBestScore: Int?
    var latestRoundScore: Int?
    var averageScore: Double?
    var handicapEstimate: Double?
    var sortOrder: Int

    init(
        id: String,
        displayName: String,
        weeklyBestScore: Int? = nil,
        latestRoundScore: Int? = nil,
        averageScore: Double? = nil,
        handicapEstimate: Double? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.displayName = displayName
        self.weeklyBestScore = weeklyBestScore
        self.latestRoundScore = latestRoundScore
        self.averageScore = averageScore
        self.handicapEstimate = handicapEstimate
        self.sortOrder = sortOrder
    }
}
