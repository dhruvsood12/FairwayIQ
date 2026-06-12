import Foundation
import SwiftData

protocol ProfileRepositorying {
    func fetchProfile(id: UUID) throws -> UserProfile?
    func fetchAnyProfile() throws -> UserProfile?
    func upsertProfile(_ profile: UserProfile) throws
}

final class ProfileRepository: ProfileRepositorying {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchProfile(id: UUID) throws -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func fetchAnyProfile() throws -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try modelContext.fetch(descriptor).first
    }

    func upsertProfile(_ profile: UserProfile) throws {
        modelContext.insert(profile)
        try modelContext.save()
    }
}
