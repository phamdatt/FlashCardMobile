//
//  L10n.swift
//  FlashCardMobile
//

import Foundation

// MARK: - Language Setting

enum AppLanguage: String, CaseIterable {
    case vi = "vi"
    case en = "en"

    var displayName: String {
        switch self {
        case .vi: return "Tiếng Việt"
        case .en: return "English"
        }
    }

    var icon: String {
        switch self {
        case .vi: return "🇻🇳"
        case .en: return "🇬🇧"
        }
    }
}

// MARK: - Localization Manager

final class L10nManager {
    static let shared = L10nManager()
    private var bundle: Bundle = .main

    var currentLanguage: AppLanguage {
        let raw = UserDefaults.standard.string(forKey: "app_language") ?? "vi"
        return AppLanguage(rawValue: raw) ?? .vi
    }

    init() {
        loadBundle()
    }

    func setLanguage(_ lang: AppLanguage) {
        UserDefaults.standard.set(lang.rawValue, forKey: "app_language")
        loadBundle()
    }

    private func loadBundle() {
        let lang = currentLanguage.rawValue
        if let path = Bundle.main.path(forResource: lang, ofType: "lproj"),
           let b = Bundle(path: path) {
            bundle = b
        } else {
            bundle = .main
        }
    }

    func string(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: key, table: nil)
    }

    func string(_ key: String, _ args: CVarArg...) -> String {
        let fmt = bundle.localizedString(forKey: key, value: key, table: nil)
        return String(format: fmt, arguments: args)
    }
}

// MARK: - Convenience

func L(_ key: String) -> String {
    L10nManager.shared.string(key)
}

func L(_ key: String, _ args: CVarArg...) -> String {
    let fmt = L10nManager.shared.string(key)
    return String(format: fmt, arguments: args)
}
