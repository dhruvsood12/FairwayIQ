import SwiftUI

struct CourseRowView: View {
    let course: Course

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(course.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Color.textPrimary)
                HStack(spacing: 8) {
                    if let location = course.locationName {
                        Text(location)
                    }
                    if let kind = course.kind, !kind.isEmpty {
                        Text("• \(kind)")
                    }
                }
                .font(.caption)
                .foregroundStyle(Theme.Color.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if !course.holes.isEmpty {
                    Text("\(course.holes.count) holes")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.Color.textSecondary)
                } else if let holeCount = course.sourceHoleCount {
                    Text("\(holeCount) holes")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                if let par = course.parIfKnown {
                    Text("Par \(par)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.Color.accent)
                } else {
                    Text("Par unavailable")
                        .font(.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
        }
        .padding(Theme.Layout.cardPadding)
        .background(Theme.Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
    }
}
