//
//  Theme.swift
//  FairwayIQ
//

import SwiftUI

enum Theme {
    enum Color {
        static let background = SwiftUI.Color(red: 0.08, green: 0.10, blue: 0.11)
        static let backgroundSecondary = SwiftUI.Color(red: 0.12, green: 0.14, blue: 0.16)
        static let cardBackground = SwiftUI.Color(red: 0.14, green: 0.17, blue: 0.19)
        static let greenPrimary = SwiftUI.Color(red: 0.22, green: 0.55, blue: 0.33)
        static let greenMuted = SwiftUI.Color(red: 0.20, green: 0.45, blue: 0.28)
        static let textPrimary = SwiftUI.Color(red: 0.95, green: 0.95, blue: 0.97)
        static let textSecondary = SwiftUI.Color(red: 0.65, green: 0.68, blue: 0.72)
        static let accent = SwiftUI.Color(red: 0.30, green: 0.75, blue: 0.48)
        static let positive = SwiftUI.Color(red: 0.35, green: 0.78, blue: 0.50)
        static let negative = SwiftUI.Color(red: 0.95, green: 0.40, blue: 0.40)
    }

    enum Layout {
        static let cornerRadius: CGFloat = 16
        static let cornerRadiusSmall: CGFloat = 10
        static let cardPadding: CGFloat = 20
        static let horizontalPadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 24
    }
}
