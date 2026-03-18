import Foundation
import SwiftData

enum CourseSeedLoader {
    static func seedIfNeeded(modelContext: ModelContext, records: [CourseSeedRecord] = CourseSeed.starterUS) {
        let existing = (try? modelContext.fetch(FetchDescriptor<Course>())) ?? []
        guard existing.isEmpty else { return }

        for record in records {
            let course = Course(
                id: record.id,
                name: record.name,
                city: record.city,
                state: record.state,
                kind: record.kind,
                websiteURL: record.websiteURL,
                latitude: record.latitude,
                longitude: record.longitude,
                holes: []
            )
            modelContext.insert(course)

            for holeSeed in record.holes {
                let hole = Hole(number: holeSeed.number, par: holeSeed.par, handicapIndex: holeSeed.number, yardage: holeSeed.yardage)
                hole.course = course
                modelContext.insert(hole)
                course.holes.append(hole)
            }
        }

        do {
            try modelContext.save()
        } catch {
            // Seeding failure should never block app startup; course list can be empty.
        }
    }
}

