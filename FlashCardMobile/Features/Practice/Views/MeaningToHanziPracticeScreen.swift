//
//  MeaningToHanziPracticeScreen.swift
//  FlashCardMobile
//

import SwiftUI

struct MeaningToHanziPracticeScreen: View {
    let topic: Topic
    let subject: Subject
    @Environment(\.dismiss) private var dismiss
    @State private var cards: [Flashcard] = []
    @State private var currentIndex = 0
    @State private var userHanzi = ""
    @State private var showFeedback = false
    @State private var lastCorrect = false
    @State private var score = 0
    @State private var totalAnswered = 0
    @State private var showResult = false
    @State private var showSettings = false
    @State private var phoneticRevealed = false
    @FocusState private var isTextFieldFocused: Bool
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
                } else if currentIndex < cards.count {
                    practiceContent
                }
            }
        }
        .onAppear {
            cards = topic.flashcards.shuffled()
        }
        .sheet(isPresented: $showResult) {
            PracticeResultSheet(score: score, total: totalAnswered, practiceType: "Nghĩa → Hán tự", topicId: topic.id) {
                showResult = false
                dismiss()
            }
        }
    }

    private var progressBar: some View {
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
                .foregroundStyle(AppTheme.textSecondary)
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .sheet(isPresented: $showSettings) {
                PracticeSettingsDrawer()
            }
        }
        .padding()
    }

    private var emptyState: some View {
        ContentUnavailableView(
            L("practice.no_cards"),
            systemImage: "character.book.closed",
            description: Text(L("hanzi.no_vocab"))
        )
    }

    private var practiceContent: some View {
        let card = cards[currentIndex]
        return ScrollView {
            VStack(spacing: 24) {
                Text(L("hanzi.instruction"))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                Text(card.answer)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .cardStyle()

                VStack(alignment: .leading, spacing: 8) {
                    Text(L("hanzi.your_answer"))
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    TextField(L("hanzi.placeholder"), text: $userHanzi)
                        .font(.title2)
                        .padding()
                        .background(AppTheme.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isTextFieldFocused ? AppTheme.primary : Color.gray.opacity(0.3), lineWidth: 2)
                        )
                        .focused($isTextFieldFocused)
                        .disabled(showFeedback)
                }
                .padding(.horizontal)

                if showFeedback {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: lastCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(lastCorrect ? AppTheme.accentGreen : AppTheme.accentRed)
                            Text(lastCorrect ? L("hanzi.correct") : L("hanzi.wrong"))
                                .font(.headline)
                                .foregroundStyle(lastCorrect ? AppTheme.accentGreen : AppTheme.accentRed)
                        }
                        if !lastCorrect {
                            VStack(spacing: 4) {
                                Text(L("hanzi.correct_answer", card.questionDisplayText))
                                    .font(.title3)
                                    .foregroundStyle(AppTheme.primary)
                                if showPinyin || phoneticRevealed, let phonetic = card.displayPhonetic, !phonetic.isEmpty {
                                    Text(phonetic)
                                        .font(.subheadline)
                                        .foregroundStyle(AppTheme.textSecondary)
                                        .transition(.opacity)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background((lastCorrect ? AppTheme.accentGreen : AppTheme.accentRed).opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onTapGesture {
                        if !showPinyin, !lastCorrect {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                phoneticRevealed.toggle()
                            }
                        }
                    }

                    PracticeHintCard(card: card)
                }

                Button {
                    HapticFeedback.impact()
                    if showFeedback {
                        if currentIndex + 1 >= cards.count {
                            currentIndex = cards.count
                            showResult = true
                        } else {
                            currentIndex += 1
                            userHanzi = ""
                            showFeedback = false
                            phoneticRevealed = false
                        }
                    } else {
                        checkAnswer()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(showFeedback ? L("common.continue") : L("common.check"))
                        if showFeedback {
                            Image(systemName: "arrow.right")
                                .font(.body.weight(.semibold))
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background((!showFeedback && userHanzi.isEmpty) ? Color.gray : AppTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(!showFeedback && userHanzi.isEmpty)
            }
            .padding()
        }
        .onAppear { isTextFieldFocused = true }
    }

    private func checkAnswer() {
        guard !userHanzi.isEmpty else { return }
        let card = cards[currentIndex]
        let userNorm = userHanzi.trimmingCharacters(in: .whitespacesAndNewlines)
        let correctNorm = card.questionDisplayText.trimmingCharacters(in: .whitespacesAndNewlines)
        lastCorrect = userNorm == correctNorm

        totalAnswered += 1
        if lastCorrect { score += 1 }
        if lastCorrect { SoundEffect.playCorrect() } else { SoundEffect.playWrong() }

        DatabaseManager.shared.ensureProgressExists(flashcardId: card.id)
        if var progress = DatabaseManager.shared.getFlashcardProgress(flashcardId: card.id) {
            progress.totalReviews += 1
            if lastCorrect { progress.correctReviews += 1 }
            else {
                progress.incorrectReviews += 1
                DatabaseManager.shared.recordMistake(flashcardId: card.id, practiceType: "Nghĩa → Hán tự", topicId: topic.id)
            }
            DatabaseManager.shared.saveFlashcardProgress(progress)
        }
        showFeedback = true
        isTextFieldFocused = false
    }
}
