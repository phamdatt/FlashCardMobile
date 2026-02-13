//
//  SettingsScreen.swift
//  FlashCardMobile
//

import SwiftUI
import UIKit

struct SettingsScreen: View {
    @ObservedObject var appViewModel: AppViewModel
    @AppStorage("appearance_mode") private var appearanceModeRaw = AppearanceMode.system.rawValue
    @State private var showBackupSheet = false

    private var appearanceMode: AppearanceMode {
        get { AppearanceMode(rawValue: appearanceModeRaw) ?? .system }
        set { appearanceModeRaw = newValue.rawValue }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        HapticFeedback.impact()
                        showBackupSheet = true
                    } label: {
                        Label {
                            Text("Sao lưu & Xuất SQLite")
                                .foregroundStyle(Color(UIColor.label))
                        } icon: {
                            Image(systemName: "externaldrive.badge.plus")
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("Dữ liệu")
                } footer: {
                    Text("Sao lưu, xuất hoặc khôi phục database.")
                }

                Section {
                    Picker("Giao diện", selection: Binding(
                        get: { appearanceMode },
                        set: { appearanceModeRaw = $0.rawValue }
                    )) {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            Label {
                                Text(mode.rawValue)
                                    .foregroundStyle(Color(UIColor.label))
                            } icon: {
                                Image(systemName: mode.icon)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            .tag(mode)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("Chế độ hiển thị")
                } footer: {
                    Text("Chọn Sáng hoặc Tối để cố định, hoặc Hệ thống để theo cài đặt thiết bị.")
                }
            }
            .navigationTitle("Cài đặt")
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
