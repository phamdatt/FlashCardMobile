//
//  SettingsScreen.swift
//  FlashCardMobile
//

import SwiftUI
import UIKit
import Combine

struct SettingsScreen: View {
    @ObservedObject var appViewModel: AppViewModel
    @AppStorage("appearance_mode") private var appearanceModeRaw = AppearanceMode.system.rawValue
    @State private var showBackupSheet = false
    @State private var currentLanguage = L10nManager.shared.currentLanguage

    private var appearanceMode: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceModeRaw) ?? .system }
        set { appearanceModeRaw = newValue.rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Language section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L("settings.language_section"))
                            .font(.headline)
                            .fontWeight(.semibold)

                        VStack(spacing: 0) {
                            ForEach(Array(AppLanguage.allCases.enumerated()), id: \.element) { index, lang in
                                Button {
                                    HapticFeedback.impact()
                                    L10nManager.shared.setLanguage(lang)
                                    currentLanguage = lang
                                    appViewModel.objectWillChange.send()
                                } label: {
                                    HStack(spacing: 12) {
                                        Text(lang.icon)
                                            .font(.title2)
                                        Text(lang.displayName)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if currentLanguage == lang {
                                            Image(systemName: "checkmark.seal.fill")
                                                .foregroundStyle(AppTheme.accentGreen)
                                        }
                                    }
                                    .padding(16)
                                }
                                .buttonStyle(.plain)

                                if index < AppLanguage.allCases.count - 1 {
                                    Divider().padding(.leading, 16)
                                }
                            }
                        }
                        .cardStyle()
                    }

                    // Data section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L("settings.data_section"))
                            .font(.headline)
                            .fontWeight(.semibold)

                        Button {
                            HapticFeedback.impact()
                            showBackupSheet = true
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "externaldrive.badge.plus")
                                    .font(.title2)
                                    .foregroundStyle(AppTheme.iconTint)
                                    .frame(width: 32, alignment: .center)
                                Text(L("settings.backup_title"))
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            .padding(16)
                            .cardStyle()
                        }
                        .buttonStyle(.plain)

                        Text(L("settings.data_footer"))
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    // Appearance section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L("settings.appearance_section"))
                            .font(.headline)
                            .fontWeight(.semibold)

                        VStack(spacing: 0) {
                            ForEach(Array(AppearanceMode.allCases.enumerated()), id: \.element) { index, mode in
                                Button {
                                    HapticFeedback.impact()
                                    appearanceModeRaw = mode.rawValue
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: mode.icon)
                                            .font(.title2)
                                            .foregroundStyle(AppTheme.iconTint)
                                            .frame(width: 32, alignment: .center)
                                        Text(mode.localizedName)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if appearanceMode == mode {
                                            Image(systemName: "checkmark.seal.fill")
                                                .foregroundStyle(AppTheme.accentGreen)
                                        }
                                    }
                                    .padding(16)
                                }
                                .buttonStyle(.plain)

                                if index < AppearanceMode.allCases.count - 1 {
                                    Divider().padding(.leading, 16)
                                }
                            }
                        }
                        .cardStyle()

                        Text(L("settings.appearance_footer"))
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .padding()
            }
            .background(AppTheme.surface)
            .navigationTitle(L("settings.title"))
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showBackupSheet) {
                BackupExportSheet(
                    onDismiss: { showBackupSheet = false },
                    onRestoreSuccess: { appViewModel.loadData() }
                )
            }
        }
    }
}
