//
//  FlashcardDetailScreen.swift
//  FlashCardMobile
//

import SwiftUI

struct FlashcardDetailScreen: View {
    let flashcard: Flashcard
    @ObservedObject var listViewModel: FlashcardListViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showEditSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroCard
                if let phonetic = flashcard.displayPhonetic, !phonetic.isEmpty {
                    detailRow(icon: "textformat.phonetic", title: "Phiên âm", content: phonetic)
                }
                detailRow(icon: "checkmark.circle", title: "Nghĩa", content: flashcard.answer)
                if let hint = flashcard.hint, !hint.isEmpty {
                    detailRow(icon: "lightbulb", title: "Gợi ý", content: hint)
                }
                if let radical = flashcard.radical, !radical.isEmpty {
                    detailRow(icon: "square.grid.2x2", title: "Bộ thủ", content: radical)
                }
                if let notes = flashcard.notes, !notes.isEmpty {
                    detailRow(icon: "note.text", title: "Ghi chú", content: notes)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .background(AppTheme.surface)
        .navigationTitle("Chi tiết")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        HapticFeedback.impact()
                        UIPasteboard.general.string = flashcard.copyText
                    } label: {
                        Label("Sao chép từ vựng", systemImage: "doc.on.doc")
                    }
                    Button {
                        HapticFeedback.impact()
                        showEditSheet = true
                    } label: {
                        Label("Sửa", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditFlashcardSheet(flashcard: flashcard, viewModel: listViewModel, onDismiss: {
                showEditSheet = false
            })
        }
    }

    private var heroCard: some View {
        VStack(spacing: 16) {
            Text(flashcard.questionDisplayText)
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
            if let phonetic = flashcard.displayPhonetic, !phonetic.isEmpty {
                Text(phonetic)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.9))
            }
            Text(flashcard.answer)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.95))
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [AppTheme.primary.opacity(0.9), Color(red: 0.56, green: 0.34, blue: 0.89)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: AppTheme.primary.opacity(0.2), radius: 12, x: 0, y: 6)
    }

    private func detailRow(icon: String, title: String, content: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.body.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 24, alignment: .center)
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.textSecondary)
                Text(content)
                    .font(.body)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(AppTheme.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}
