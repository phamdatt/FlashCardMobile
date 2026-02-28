//
//  CSVSheet.swift
//  FlashCardMobile
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct CSVExportSheet: View {
    let topicId: Int
    let topicName: String
    let onDismiss: () -> Void
    @State private var shareItem: URL?
    @State private var showShareSheet = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AppTheme.primary)
                Text(L("csv.export_title"))
                    .font(.headline)
                Text(L("csv.export_topic", topicName))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                Button {
                    HapticFeedback.impact()
                    exportAndShare()
                } label: {
                    Label(L("csv.export_action"), systemImage: "square.and.arrow.up")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.primaryGradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
            }
            .padding(32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.surface)
            .navigationTitle(L("csv.export_nav"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("common.close")) {
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
            .alert(L("csv.export_error"), isPresented: $showError) {
                Button("OK", role: .cancel) {
                    HapticFeedback.impact()
                    showError = false
                }
            } message: {
                Text(errorMessage ?? "Không xác định")
            }
        }
    }

    private func exportAndShare() {
        errorMessage = nil
        let csv = DatabaseManager.shared.exportFlashcardsToCSV(topicId: topicId)
        if csv.isEmpty {
            errorMessage = L("csv.no_data")
            showError = true
            return
        }
        let safeName = topicName
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
        let fileName = "flashcards_\(safeName)_\(Int(Date().timeIntervalSince1970)).csv"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        do {
            let csvWithBOM = "\u{FEFF}" + csv
            try csvWithBOM.write(to: fileURL, atomically: true, encoding: .utf8)
            shareItem = fileURL
            showShareSheet = true
        } catch {
            errorMessage = "Không thể tạo file: \(error.localizedDescription)"
            showError = true
        }
    }
}

struct CSVImportSheet: View {
    let topicId: Int
    let topicName: String
    let onDismiss: () -> Void
    @State private var importedCount = 0
    @State private var importErrors: [String] = []
    @State private var showFilePicker = false
    @State private var importDone = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "doc.text.badge.plus")
                    .font(.system(size: 56))
                    .foregroundStyle(AppTheme.primary)
                Text(L("csv.import_title"))
                    .font(.headline)
                Text(L("csv.import_topic", topicName))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                if importDone {
                    VStack(spacing: 8) {
                        Text(L("csv.import_success", importedCount))
                            .font(.headline)
                            .foregroundStyle(AppTheme.accentGreen)
                        if !importErrors.isEmpty {
                            Text(L("csv.import_errors", importErrors.count))
                                .font(.caption)
                                .foregroundStyle(AppTheme.accentRed)
                        }
                    }
                } else {
                    Button {
                        HapticFeedback.impact()
                        showFilePicker = true
                    } label: {
                        Label(L("csv.import_pick"), systemImage: "folder.badge.plus")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.primaryGradient)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.surface)
            .navigationTitle(L("csv.import_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("common.close")) {
                        HapticFeedback.impact()
                        onDismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.plainText, .commaSeparatedText, UTType(filenameExtension: "csv") ?? .plainText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    guard url.startAccessingSecurityScopedResource() else { return }
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let csv = try? String(contentsOf: url, encoding: .utf8) {
                        let (count, errors) = DatabaseManager.shared.importFlashcardsFromCSV(csv, topicId: topicId)
                        importedCount = count
                        importErrors = errors
                        importDone = true
                    }
                case .failure:
                    break
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if UIDevice.current.userInterfaceIdiom == .pad,
           let popover = vc.popoverPresentationController,
           let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }),
           let rootView = window.rootViewController?.view {
            popover.sourceView = rootView
            popover.sourceRect = CGRect(x: rootView.bounds.midX, y: rootView.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
