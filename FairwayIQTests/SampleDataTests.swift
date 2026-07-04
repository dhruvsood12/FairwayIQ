@testable import FairwayIQ
import Foundation
import SwiftData
import Testing

@Suite("SampleData Tests")
struct SampleDataTests {
    private func inMemoryContext() throws -> ModelContext {
        let schema = Schema([UserProfile.self, Course.self, Hole.self, Round.self, HoleScore.self, Shot.self, FriendEntry.self, PracticeSession.self, PracticeShot.self, PlayerGoal.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return ModelContext(container)
    }

    @Test("Seeds sample courses alongside a populated catalog")
    func seedsAlongsideCatalog() throws {
        let context = try inMemoryContext()
        let catalogCourse = Course(id: "osm:way:1", name: "Catalog Course", kind: "Public")
        context.insert(catalogCourse)
        try context.save()

        SampleData.seedIfNeeded(modelContext: context)

        let samples = try context.fetch(FetchDescriptor<Course>(predicate: #Predicate { $0.kind == "Sample" }))
        #expect(samples.count == 3)
    }

    @Test("Does not reseed when sample courses already exist")
    func skipsWhenSamplesExist() throws {
        let context = try inMemoryContext()
        SampleData.seedIfNeeded(modelContext: context)
        let firstCount = try context.fetch(FetchDescriptor<Course>()).count

        SampleData.seedIfNeeded(modelContext: context)
        let secondCount = try context.fetch(FetchDescriptor<Course>()).count
        #expect(firstCount == secondCount)
    }
}
