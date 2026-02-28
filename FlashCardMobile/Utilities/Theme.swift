//
//  Theme.swift
//  FlashCardMobile
//

import SwiftUI

enum AppearanceMode: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var localizedName: String {
        switch self {
        case .system: return L("appearance.system")
        case .light: return L("appearance.light")
        case .dark: return L("appearance.dark")
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
    // MARK: - Primary (Indigo)
    static let primary = Color(red: 0.35, green: 0.34, blue: 0.84)
    static let primaryGradient = LinearGradient(
        colors: [Color(red: 0.35, green: 0.34, blue: 0.84), Color(red: 0.56, green: 0.45, blue: 0.95)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    /// Hero card / practice card gradient
    static let heroGradient = LinearGradient(
        colors: [Color(red: 0.35, green: 0.34, blue: 0.84), Color(red: 0.68, green: 0.42, blue: 0.96)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Surface & Cards
    static let surface = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.07, green: 0.07, blue: 0.10, alpha: 1)
        : UIColor(red: 0.96, green: 0.96, blue: 0.98, alpha: 1)
    })
    static let cardBg = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.11, green: 0.11, blue: 0.16, alpha: 1)
        : .white
    })

    // MARK: - Shadows
    static let cardShadow = Color.black.opacity(0.06)
    static let cardShadowDark = Color.black.opacity(0.18)

    // MARK: - Accents
    static let accentGreen = Color(red: 0.20, green: 0.78, blue: 0.48)
    static let accentRed = Color(red: 0.94, green: 0.30, blue: 0.35)
    static let accentOrange = Color(red: 1.0, green: 0.58, blue: 0.22)
    static let accentViolet = Color(red: 0.68, green: 0.42, blue: 0.96)

    // MARK: - Text & Icons
    static let textSecondary = Color(UIColor.secondaryLabel)
    static let iconTint = Color(UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.62, green: 0.65, blue: 0.72, alpha: 1)
        : UIColor(red: 0.38, green: 0.42, blue: 0.50, alpha: 1)
    })
    static let tabBarInactive = Color(UIColor.secondaryLabel)
}

// MARK: - Speaking Ripple Effect

struct SpeakingRippleEffect: View {
    let isActive: Bool
    let color: Color

    @State private var ripple1: Bool = false
    @State private var ripple2: Bool = false

    var body: some View {
        ZStack {
            if isActive {
                Circle()
                    .stroke(color.opacity(ripple1 ? 0 : 0.5), lineWidth: 2)
                    .scaleEffect(ripple1 ? 2.2 : 0.8)
                    .animation(
                        .easeOut(duration: 1.4).repeatForever(autoreverses: false),
                        value: ripple1
                    )

                Circle()
                    .stroke(color.opacity(ripple2 ? 0 : 0.35), lineWidth: 1.5)
                    .scaleEffect(ripple2 ? 2.6 : 0.8)
                    .animation(
                        .easeOut(duration: 1.4).repeatForever(autoreverses: false).delay(0.5),
                        value: ripple2
                    )
            }
        }
        .onChange(of: isActive) { _, active in
            if active {
                ripple1 = false
                ripple2 = false
                withAnimation {
                    ripple1 = true
                    ripple2 = true
                }
            } else {
                ripple1 = false
                ripple2 = false
            }
        }
    }
}

// MARK: - Practice Settings Drawer

struct PracticeSettingsDrawer: View {
    @AppStorage("practice_show_pinyin") var showPinyin = true
    @AppStorage("sound_effects_enabled") var soundEnabled = true

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: $showPinyin) {
                        Label(L("practice.show_pinyin"), systemImage: "textformat.phonetic")
                    }
                    .tint(AppTheme.primary)
                    Toggle(isOn: $soundEnabled) {
                        Label(L("practice.sound_toggle"), systemImage: "speaker.wave.2.fill")
                    }
                    .tint(AppTheme.primary)
                }
            }
            .navigationTitle(L("practice.settings"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.height(200)])
        .presentationDragIndicator(.visible)
    }
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
