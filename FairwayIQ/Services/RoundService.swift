//
//  RoundService.swift
//  FairwayIQ
//

import Foundation
import SwiftData

@Observable
final class RoundService {
    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        modelContext = context
    }

    func fetchAllRounds() -> [Round] {
        var descriptor = FetchDescriptor<Round>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = 100
        guard let context = modelContext else { return [] }
        return (try? context.fetch(descriptor)) ?? []
    }

    func saveRound(_ round: Round) {
        modelContext?.insert(round)
        try? modelContext?.save()
    }

    func deleteRound(_ round: Round) {
        modelContext?.delete(round)
        try? modelContext?.save()
    }
}
