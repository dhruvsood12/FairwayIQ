//
//  LeaderboardService.swift
//  FairwayIQ
//

import Foundation
import SwiftData

@Observable
final class LeaderboardService {
    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        modelContext = context
    }

    func fetchFriends() -> [FriendEntry] {
        var descriptor = FetchDescriptor<FriendEntry>(sortBy: [SortDescriptor(\.sortOrder)])
        guard let context = modelContext else { return [] }
        return (try? context.fetch(descriptor)) ?? []
    }
}
