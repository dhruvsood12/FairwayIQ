import SwiftUI

// MARK: - Spacing Scale

enum Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

// MARK: - Card Style

struct FIQCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(Theme.Layout.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Color.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius)
                    .stroke(.white.opacity(0.04), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
            .shadow(color: .black.opacity(0.18), radius: 16, y: 8)
    }
}

// MARK: - Stat Tile

struct StatTile: View {
    let title: String
    let value: String
    var valueColor: Color = Theme.Color.accent
    var subtitle: String?

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.Color.textSecondary)
                .lineLimit(1)
            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var eyebrow: String?
    var action: String?
    var onAction: (() -> Void)?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                if let eyebrow {
                    Text(eyebrow.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.Color.textPrimary)
            }
            Spacer()
            if let action {
                Button(action) { onAction?() }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.Color.accent)
            }
        }
    }
}

// MARK: - Badge / Chip

struct FIQChip: View {
    let text: String
    var color: Color = Theme.Color.greenPrimary
    var isOutline: Bool = false

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(isOutline ? color : .white)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(isOutline ? Color.clear : color.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(color.opacity(0.5), lineWidth: isOutline ? 1 : 0)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Progress Ring

struct ProgressRing: View {
    let progress: Double
    var size: CGFloat = 44
    var lineWidth: CGFloat = 4
    var color: Color = Theme.Color.accent

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(1.0, max(0, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Trend Badge

struct TrendBadge: View {
    let trend: String
    let isPositive: Bool

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.caption2.weight(.bold))
            Text(trend)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(isPositive ? Theme.Color.positive : Theme.Color.negative)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background((isPositive ? Theme.Color.positive : Theme.Color.negative).opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var onAction: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(Theme.Color.textSecondary.opacity(0.6))
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.Color.textPrimary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xxxl)
            if let actionTitle {
                Button(actionTitle) { onAction?() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Color.background)
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.vertical, Spacing.md)
                    .background(Theme.Color.greenPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadiusSmall))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxxl)
    }
}

// MARK: - Loading State

struct LoadingStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: Spacing.lg) {
            ProgressView()
                .tint(Theme.Color.accent)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxxl)
    }
}

// MARK: - Primary Button

struct FIQPrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.Color.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
                .background(isEnabled ? Theme.Color.greenPrimary : Theme.Color.textSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.7)
    }
}

struct FIQSecondaryButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.Color.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
                .background(Theme.Color.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Layout.cornerRadius))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Confidence Indicator

struct ConfidenceIndicator: View {
    let confidence: ClubConfidence

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0 ..< 3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(i < barCount ? barColor : Theme.Color.textSecondary.opacity(0.3))
                    .frame(width: 4, height: CGFloat(6 + i * 3))
            }
        }
    }

    private var barCount: Int {
        switch confidence {
        case .noData: return 0
        case .low: return 1
        case .moderate: return 2
        case .high: return 3
        }
    }

    private var barColor: Color {
        switch confidence {
        case .noData: return Theme.Color.textSecondary
        case .low: return Theme.Color.negative
        case .moderate: return Color.orange
        case .high: return Theme.Color.positive
        }
    }
}

struct InlineValidationMessage: View {
    let message: String

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption)
            Text(message)
                .font(.caption)
        }
        .foregroundStyle(Theme.Color.negative)
    }
}
