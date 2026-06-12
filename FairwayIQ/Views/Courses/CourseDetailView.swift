import MapKit
import SwiftUI

struct CourseDetailView: View {
    let course: Course

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Layout.sectionSpacing) {
                headerCard
                holesCard
            }
            .padding(Theme.Layout.horizontalPadding)
            .padding(.bottom, 32)
        }
        .background(Theme.Color.background)
        .navigationTitle("Course")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(course.name)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.Color.textPrimary)
            if let location = course.locationName {
                Text(location)
                    .font(.subheadline)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            HStack(spacing: 12) {
                if let kind = course.kind, !kind.isEmpty {
                    pill(kind)
                }
                pill("\(course.holes.count) holes")
                if course.totalPar > 0 {
                    pill("Par \(course.totalPar)")
                }
            }

            if let urlString = course.websiteURL, let url = URL(string: urlString) {
                Link("Website", destination: url)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Color.accent)
            }

            if let coordinate = course.coordinate {
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                ))) {
                    Marker(course.name, coordinate: coordinate)
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
            }
        }
        .padding(Theme.Layout.cardPadding)
        .background(Theme.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
    }

    private func pill(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .foregroundStyle(Theme.Color.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Theme.Color.backgroundSecondary.opacity(0.7))
            .clipShape(Capsule())
    }

    private var holesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Holes")
                .font(.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            VStack(spacing: 0) {
                ForEach(course.holes.sorted(by: { $0.number < $1.number }), id: \.number) { hole in
                    HStack {
                        Text("Hole \(hole.number)")
                            .foregroundStyle(Theme.Color.textPrimary)
                        Spacer()
                        Text("Par \(hole.par)")
                            .foregroundStyle(Theme.Color.textSecondary)
                        if let y = hole.yardage {
                            Text("• \(y) yd")
                                .foregroundStyle(Theme.Color.textSecondary)
                        }
                    }
                    .font(.subheadline)
                    .padding(.vertical, 10)
                    if hole.number != course.holes.count {
                        Divider().background(Theme.Color.textSecondary.opacity(0.25))
                    }
                }
            }
            .padding(Theme.Layout.cardPadding)
            .background(Theme.Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
        }
    }
}
