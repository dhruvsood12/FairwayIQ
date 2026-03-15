//
//  CourseService.swift
//  FairwayIQ
//

import Foundation
import SwiftData

@Observable
final class CourseService {
    private var modelContext: ModelContext?

    func setModelContext(_ context: ModelContext) {
        modelContext = context
    }

    func fetchAllCourses() -> [Course] {
        let descriptor = FetchDescriptor<Course>()
        guard let context = modelContext else { return [] }
        return (try? context.fetch(descriptor)) ?? []
    }

    func course(byId courseId: String) -> Course? {
        var descriptor = FetchDescriptor<Course>(predicate: #Predicate<Course> { course in
            course.id == courseId
        })
        descriptor.fetchLimit = 1
        guard let context = modelContext else { return nil }
        return try? context.fetch(descriptor).first
    }

    func saveCourse(_ course: Course) {
        modelContext?.insert(course)
        try? modelContext?.save()
    }
}
