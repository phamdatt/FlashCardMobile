//
//  MultipleChoicePracticeScreen.swift
//  FlashCardMobile
//

import SwiftUI
import UIKit

struct MultipleChoicePracticeScreen: View {
    let topic: Topic
    let subject: Subject
    @Environment(\.dismiss) private var dismiss
    @State private var cards: [Flashcard] = []
    @State private var currentIndex = 0
    @State private var selectedOption: String?
    @State private var showFeedback = false
    @State private var lastCorrect = false
    @State private var score = 0
    @State private var totalAnswered = 0
    @State private var showResult = false
    @AppStorage("practice_show_pinyin") private var showPinyin = true

    var body: some View {
        ZStack {
            AppTheme.surface
                .ignoresSafeArea()

            VStack(spacing: 0) {
                progressBar
                if cards.isEmpty {
                    Spacer()
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            questionCard
                            if showFeedback {
                                feedbackBanner
                                PracticeHintCard(card: cards[currentIndex])
                                continueButton
                            } else {
                                optionsGrid
                            }
                        }
                        .padding()
                    }
                }
                Spacer()
            }
        }
        .onAppear {
            cards = topic.flashcards.shuffled()
        }
        .sheet(isPresented: $showResult) {
            PracticeResultSheet(
                score: score,
                total: totalAnswered,
                onDismiss: {
                    showResult = false
                    dismiss()
                }
            )
        }
    }

    private var progressBar: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    HapticFeedback.impact()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Text("\(currentIndex + 1) / \(cards.count)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
            }
            HStack {
                Label("Pinyin", systemImage: "textformat.phonetic")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Toggle("", isOn: $showPinyin)
                    .labelsHidden()
                    .tint(AppTheme.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(AppTheme.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding()
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Không có thẻ",
            systemImage: "rectangle.stack",
            description: Text("Cần ít nhất 4 từ để luyện trắc nghiệm.")
        )
    }

    private var questionCard: some View {
        let card = cards[currentIndex]
        return VStack(spacing: 12) {
            Text(card.questionDisplayText)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            if showPinyin, let phonetic = card.displayPhonetic, !phonetic.isEmpty {
                Text(phonetic)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .cardStyle()
    }

    private var feedbackBanner: some View {
        HStack {
            Image(systemName: lastCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(lastCorrect ? AppTheme.accentGreen : AppTheme.accentRed)
            Text(lastCorrect ? "Đúng rồi!" : "Sai rồi - Đáp án: \(cards[currentIndex].answer)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(lastCorrect ? AppTheme.accentGreen : AppTheme.accentRed)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background((lastCorrect ? AppTheme.accentGreen : AppTheme.accentRed).opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var continueButton: some View {
        Button {
            HapticFeedback.impact()
            if currentIndex + 1 >= cards.count {
                showResult = true
            } else {
                currentIndex += 1
                selectedOption = nil
                showFeedback = false
            }
        } label: {
            HStack(spacing: 8) {
                Text("Tiếp tục")
                Image(systemName: "arrow.right")
                    .font(.body.weight(.semibold))
            }
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(HapticButtonStyle())
    }

    private var optionsGrid: some View {
        let card = cards[currentIndex]
        let options = card.options ?? [card.answer]
        return VStack(spacing: 12) {
            ForEach(options, id: \.self) { option in
                OptionButton(
                    text: option,
                    isSelected: selectedOption == option,
                    isCorrect: showFeedback && optionAnswer(from: option) == card.answer,
                    isWrong: showFeedback && selectedOption == option && optionAnswer(from: option) != card.answer
                ) {
                    guard !showFeedback else { return }
                    selectedOption = option
                    let correct = optionAnswer(from: option) == card.answer
                    lastCorrect = correct
                    showFeedback = true
                    totalAnswered += 1
                    if correct { score += 1 }

                    DatabaseManager.shared.ensureProgressExists(flashcardId: card.id)
                    if var progress = DatabaseManager.shared.getFlashcardProgress(flashcardId: card.id) {
                        progress.totalReviews += 1
                        if correct { progress.correctReviews += 1 }
                        else {
                            progress.incorrectReviews += 1
                            DatabaseManager.shared.recordMistake(flashcardId: card.id, practiceType: "Trắc nghiệm", topicId: topic.id)
                        }
                        DatabaseManager.shared.saveFlashcardProgress(progress)
                    }

                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    DatabaseManager.shared.recordPracticeSession(
                        practiceDate: formatter.string(from: Date()),
                        practiceType: "Trắc nghiệm",
                        topicId: topic.id,
                        correct: correct ? 1 : 0,
                        total: 1
                    )
                }
            }
        }
        .padding(.horizontal, 4)
    }

    private func optionAnswer(from option: String) -> String {
        let parts = option.split(separator: ". ", maxSplits: 1)
        return parts.count > 1 ? String(parts[1]) : String(option)
    }
}

struct OptionButton: View {
    let text: String
    let isSelected: Bool
    let isCorrect: Bool
    let isWrong: Bool
    let action: () -> Void

    private var backgroundColor: Color {
        if isWrong { return AppTheme.accentRed.opacity(0.2) }
        if isCorrect { return AppTheme.accentGreen.opacity(0.2) }
        if isSelected { return AppTheme.primary.opacity(0.2) }
        return AppTheme.cardBg
    }

    private var borderColor: Color {
        if isWrong { return AppTheme.accentRed }
        if isCorrect { return AppTheme.accentGreen }
        if isSelected { return AppTheme.primary }
        return Color.clear
    }

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected || isCorrect || isWrong ? borderColor : Color.clear,
                            lineWidth: isSelected || isCorrect || isWrong ? 2 : 0
                        )
                )
        }
        .buttonStyle(HapticButtonStyle())
        .disabled(isCorrect || isWrong)
    }
}
