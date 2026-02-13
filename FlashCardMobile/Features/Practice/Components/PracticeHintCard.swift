//
//  PracticeHintCard.swift
//  FlashCardMobile
//

import SwiftUI

/// Hiển thị gợi ý, bộ thủ, ghi chú, phiên âm sau khi trả lời.
struct PracticeHintCard: View {
    let card: Flashcard

    private var hasAnyHint: Bool {
        (card.hint != nil && !(card.hint ?? "").isEmpty)
            || (card.radical != nil && !(card.radical ?? "").isEmpty)
            || (card.notes != nil && !(card.notes ?? "").isEmpty)
            || (card.displayPhonetic != nil && !(card.displayPhonetic ?? "").isEmpty)
    }

    var body: some View {
        if hasAnyHint {
            VStack(alignment: .leading, spacing: 12) {
                Text("Thông tin thêm")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.textSecondary)

                VStack(alignment: .leading, spacing: 10) {
                    if let phonetic = card.displayPhonetic, !phonetic.isEmpty {
                        hintRow(icon: "textformat.phonetic", title: "Phiên âm", content: phonetic)
                    }
                    if let hint = card.hint, !hint.isEmpty {
                        hintRow(icon: "lightbulb", title: "Gợi ý", content: hint)
                    }
                    if let radical = card.radical, !radical.isEmpty {
                        hintRow(icon: "square.grid.2x2", title: "Bộ thủ", content: radical)
                    }
                    if let notes = card.notes, !notes.isEmpty {
                        hintRow(icon: "note.text", title: "Ghi chú", content: notes)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func hintRow(icon: String, title: String, content: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 24, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.textSecondary)
                Text(content)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
