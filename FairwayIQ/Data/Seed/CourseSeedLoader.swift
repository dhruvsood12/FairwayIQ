import Foundation
import SwiftData

enum CourseSeedLoader {
    /// Increment when replacing `courses_catalog.json` so installs pick up the new dataset.
    private static let bundledCatalogVersion = 2

    private enum DefaultsKey {
        static let appliedCatalogVersion = "fairwayiq.catalog.bundledVersion"
    }

    /// Loads the bundled national/regional catalog (OSM-derived JSON) and upserts into SwiftData.
    static func applyBundledCatalogIfNeeded(modelContext: ModelContext) {
        let last = UserDefaults.standard.integer(forKey: DefaultsKey.appliedCatalogVersion)
        guard last < bundledCatalogVersion else { return }

        guard let url = Bundle.main.url(forResource: "courses_catalog", withExtension: "json") else {
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let records = try JSONDecoder().decode([CourseSeedRecord].self, from: data)
            try upsert(records: records, modelContext: modelContext)
            UserDefaults.standard.set(bundledCatalogVersion, forKey: DefaultsKey.appliedCatalogVersion)
        } catch {
            DebugLogger.error("Bundled course catalog import failed", error: error)
        }
    }

    /// Legacy small starter set when the store is empty and no catalog was applied.
    static func seedIfNeeded(modelContext: ModelContext, records: [CourseSeedRecord] = CourseSeed.starterUS) {
        let existing = (try? modelContext.fetch(FetchDescriptor<Course>())) ?? []
        guard existing.isEmpty else { return }

        for record in records {
            insertCourse(record, modelContext: modelContext)
        }

        do {
            try modelContext.save()
        } catch {
            // Seeding failure should never block app startup; course list can be empty.
        }
    }

    private static func upsert(records: [CourseSeedRecord], modelContext: ModelContext) throws {
        let existing = try modelContext.fetch(FetchDescriptor<Course>())
        var byId = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })

        for record in records {
            if let course = byId[record.id] {
                course.name = record.name
                course.city = mapUnknown(record.city)
                course.state = mapUnknown(record.state)
                course.kind = record.kind
                course.websiteURL = record.websiteURL
                course.latitude = record.latitude
                course.longitude = record.longitude
                course.sourcePar = record.coursePar
                course.sourceHoleCount = record.holeCount
                replaceHoles(from: record, course: course, modelContext: modelContext)
            } else {
                let course = insertCourse(record, modelContext: modelContext)
                byId[record.id] = course
            }
        }

        try modelContext.save()
    }

    @discardableResult
    private static func insertCourse(_ record: CourseSeedRecord, modelContext: ModelContext) -> Course {
        let course = Course(
            id: record.id,
            name: record.name,
            city: mapUnknown(record.city),
            state: mapUnknown(record.state),
            kind: record.kind,
            websiteURL: record.websiteURL,
            latitude: record.latitude,
            longitude: record.longitude,
            sourcePar: record.coursePar,
            sourceHoleCount: record.holeCount,
            holes: []
        )
        modelContext.insert(course)
        insertHoles(from: record, course: course, modelContext: modelContext)
        return course
    }

    private static func replaceHoles(from record: CourseSeedRecord, course: Course, modelContext: ModelContext) {
        for hole in course.holes {
            modelContext.delete(hole)
        }
        course.holes.removeAll()
        insertHoles(from: record, course: course, modelContext: modelContext)
    }

    private static func insertHoles(from record: CourseSeedRecord, course: Course, modelContext: ModelContext) {
        for holeSeed in record.holes {
            let hole = Hole(number: holeSeed.number, par: holeSeed.par, handicapIndex: holeSeed.number, yardage: holeSeed.yardage)
            hole.course = course
            modelContext.insert(hole)
            course.holes.append(hole)
        }
    }

    private static func mapUnknown(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        if trimmed.caseInsensitiveCompare("Unknown") == .orderedSame { return nil }
        return trimmed
    }
}
