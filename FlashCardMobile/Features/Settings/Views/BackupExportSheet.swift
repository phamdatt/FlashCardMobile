//
//  BackupExportSheet.swift
//  FlashCardMobile
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct BackupExportSheet: View {
    let onDismiss: () -> Void
    let onRestoreSuccess: () -> Void

    @State private var shareItem: URL?
    @State private var showShareSheet = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var successMessage: String?
    @State private var showSuccess = false
    @State private var showRestorePicker = false
    @State private var restoreDone = false
    @State private var restoreSuccess = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        HapticFeedback.impact()
                        performBackup()
                    } label: {
                        Label {
                            Text("Sao lưu SQLite")
                                .foregroundStyle(Color(UIColor.label))
                        } icon: {
                            Image(systemName: "externaldrive.badge.plus")
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                    Button {
                        HapticFeedback.impact()
                        performExport()
                    } label: {
                        Label {
                            Text("Xuất SQLite")
                                .foregroundStyle(Color(UIColor.label))
                        } icon: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                    Button {
                        HapticFeedback.impact()
                        showRestorePicker = true
                    } label: {
                        Label {
                            Text("Khôi phục từ backup")
                                .foregroundStyle(Color(UIColor.label))
                        } icon: {
                            Image(systemName: "arrow.uturn.backward.circle")
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("Sao lưu & Khôi phục")
                } footer: {
                    Text("Sao lưu lưu vào Files > FlashCardMobile > Backups. Xuất SQLite chia sẻ file qua iCloud, AirDrop, v.v.")
                }
            }
            .navigationTitle("Sao lưu dữ liệu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Đóng") {
                        HapticFeedback.impact()
                        onDismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = shareItem {
                    ShareSheet(items: [url])
                }
            }
            .fileImporter(
                isPresented: $showRestorePicker,
                allowedContentTypes: [UTType(filenameExtension: "sqlite") ?? .data],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    restoreDone = true
                    restoreSuccess = DatabaseManager.shared.restoreDatabase(from: url)
                    if restoreSuccess {
                        onRestoreSuccess()
                        onDismiss()
                    } else {
                        errorMessage = "Không thể khôi phục file."
                        showError = true
                    }
                case .failure(let err):
                    errorMessage = err.localizedDescription
                    showError = true
                }
            }
            .alert("Lỗi", isPresented: $showError) {
                Button("OK", role: .cancel) {
                    HapticFeedback.impact()
                    showError = false
                }
            } message: {
                Text(errorMessage ?? "Không xác định")
            }
            .alert("Đã sao lưu", isPresented: $showSuccess) {
                Button("OK", role: .cancel) {
                    HapticFeedback.impact()
                    showSuccess = false
                }
            } message: {
                Text(successMessage ?? "Sao lưu thành công.")
            }
        }
    }

    private func performBackup() {
        if let url = DatabaseManager.shared.backupDatabase() {
            successMessage = "Đã lưu vào:\n\(url.lastPathComponent)\n\nMở Files > FlashCardMobile > Backups để xem."
            showSuccess = true
        } else {
            errorMessage = "Không thể sao lưu database."
            showError = true
        }
    }

    private func performExport() {
        if let url = DatabaseManager.shared.createExportCopy() {
            shareItem = url
            showShareSheet = true
        } else {
            errorMessage = "Không thể tạo file xuất."
            showError = true
        }
    }
}
