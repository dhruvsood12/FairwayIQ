import SwiftData
import SwiftUI

@main
struct FairwayIQApp: App {
    @State private var session = SessionStore()
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            Course.self,
            Hole.self,
            Round.self,
            HoleScore.self,
            Shot.self,
            FriendEntry.self,
            PracticeSession.self,
            PracticeShot.self,
            PlayerGoal.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try makeModelContainer(schema: schema, configuration: modelConfiguration)
        } catch {
            DebugLogger.error("Persistent store unavailable, falling back to in-memory store", error: error)

            do {
                let inMemoryConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: true
                )
                return try ModelContainer(
                    for: schema,
                    configurations: [inMemoryConfiguration]
                )
            } catch {
                fatalError("Could not create fallback ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
        }
        .modelContainer(sharedModelContainer)
    }
}

private func makeModelContainer(schema: Schema, configuration: ModelConfiguration) throws -> ModelContainer {
    try ModelContainer(
        for: schema,
        configurations: [configuration]
    )
}
