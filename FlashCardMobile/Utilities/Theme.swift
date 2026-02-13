//
//  Theme.swift
//  FlashCardMobile
//

import SwiftUI

enum AppearanceMode: String, CaseIterable {
    case system = "Hệ thống"
    case light = "Sáng"
    case dark = "Tối"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

enum AppTheme {
    /// Màu xanh dương từ flash-card (soft blue)
    static let primary = Color(red: 0.25, green: 0.47, blue: 1.0)
    static let primaryGradient = LinearGradient(
        colors: [Color(red: 0.25, green: 0.47, blue: 1.0), Color(red: 0.35, green: 0.65, blue: 1.0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let cardBg = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.12, alpha: 1) : .white })
    static let cardShadow = Color.black.opacity(0.08)
    static let cardShadowDark = Color.black.opacity(0.2)
    static let surface = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.08, alpha: 1) : UIColor(white: 0.97, alpha: 1) })
    static let accentGreen = Color(red: 0.2, green: 0.78, blue: 0.35)
    static let accentRed = Color(red: 0.96, green: 0.32, blue: 0.32)
    static let accentOrange = Color(red: 1.0, green: 0.6, blue: 0.2)
    static let textSecondary = Color(UIColor.secondaryLabel)
    /// Màu icon tab khi không chọn — hài hòa với primary
    static let tabBarInactive = Color(UIColor.secondaryLabel)
}

extension View {
    func cardStyle() -> some View {
        self
            .background(AppTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    func subtleCard() -> some View {
        self
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
