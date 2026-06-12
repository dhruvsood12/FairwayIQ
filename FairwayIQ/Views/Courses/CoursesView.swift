import SwiftData
import SwiftUI

struct CoursesView: View {
    @Query(sort: \Course.name, order: .forward) private var courses: [Course]
    @State private var searchText = ""
    @State private var selectedState: String = "All"

    private var states: [String] {
        let values = Set(courses.compactMap { $0.state?.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
        return ["All"] + values.sorted()
    }

    private var filteredCourses: [Course] {
        courses.filter { course in
            let matchesState = selectedState == "All" || course.state == selectedState
            guard matchesState else { return false }
            guard !searchText.isEmpty else { return true }
            let query = searchText.lowercased()
            return course.name.lowercased().contains(query)
                || (course.city?.lowercased().contains(query) ?? false)
                || (course.state?.lowercased().contains(query) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Color.background.ignoresSafeArea()
                if courses.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            filterBar
                            VStack(spacing: 12) {
                                ForEach(filteredCourses, id: \.id) { course in
                                    NavigationLink {
                                        CourseDetailView(course: course)
                                    } label: {
                                        CourseRowView(course: course)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(Theme.Layout.horizontalPadding)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Courses")
            .preferredColorScheme(.dark)
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic))
    }

    private var filterBar: some View {
        HStack {
            Menu {
                ForEach(states, id: \.self) { stateName in
                    Button(stateName) { selectedState = stateName }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(selectedState)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.Color.textPrimary)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Theme.Color.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
            }
            Spacer()
            Text("\(filteredCourses.count)")
                .font(.caption.weight(.medium))
                .foregroundStyle(Theme.Color.textSecondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 54))
                .foregroundStyle(Theme.Color.greenMuted)
            Text("No courses yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.Color.textPrimary)
            Text("We’ll populate a starter course catalog on first launch. If you’re in a fresh simulator, try restarting the app.")
                .font(.subheadline)
                .foregroundStyle(Theme.Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.Layout.horizontalPadding)
    }
}

#Preview {
    CoursesView()
        .modelContainer(for: [Course.self, Hole.self], inMemory: true)
}
