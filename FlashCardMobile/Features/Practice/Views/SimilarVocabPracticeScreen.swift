//
//  SimilarVocabPracticeScreen.swift
//  FlashCardMobile
//

import SwiftUI

struct SimilarVocabPracticeScreen: View {
    let sourceFlashcard: Flashcard
    @Environment(\.dismiss) private var dismiss
    @StateObject private var speechManager = SpeechManager.shared
    @State private var similarCards: [Flashcard] = []
    @State private var currentIndex = 0
    @State private var selectedAnswer: String?
    @State private var showFeedback = false
    @State private var lastCorrect = false
    @State private var score = 0
    @State private var totalAnswered = 0
    @State private var showResult = false
    @State private var isLoading = true
    @AppStorage("practice_show_pinyin") private var showPinyin = true

    var body: some View {
        ZStack {
            AppTheme.surface
                .ignoresSafeArea()

            VStack(spacing: 0) {
                progressBar
                if isLoading {
                    Spacer()
                    ProgressView("Đang tìm từ tương tự...")
                    Spacer()
                } else if similarCards.isEmpty {
                    Spacer()
                    emptyState
                    Spacer()
                } else if currentIndex < similarCards.count {
                    practiceContent
                }
            }
        }
        .onAppear { loadSimilarCards() }
        .sheet(isPresented: $showResult) {
            PracticeResultSheet(score: score, total: totalAnswered) {
                showResult = false
                dismiss()
            }
        }
    }

    private func loadSimilarCards() {
        isLoading = true
        let found = DatabaseManager.shared.findSimilarFlashcards(for: sourceFlashcard)
        // Include source card in the mix for comparison practice
        var allCards = [sourceFlashcard] + found
        allCards.shuffle()
        similarCards = allCards
        isLoading = false
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
                if !similarCards.isEmpty {
                    Text("\(currentIndex + 1) / \(similarCards.count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(AppTheme.textSecondary)
                }
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
            "Không tìm thấy từ tương tự",
            systemImage: "character.book.closed",
            description: Text("Không có từ vựng nào tương tự về hán tự hoặc pinyin.")
        )
    }

    private var practiceContent: some View {
        let card = similarCards[currentIndex]
        let options = generateOptions(for: card)
        return ScrollView {
            VStack(spacing: 20) {
                // Info banner
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(AppTheme.accentOrange)
                    Text("Từ tương tự với: \(sourceFlashcard.questionDisplayText)")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(AppTheme.accentOrange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Question card
                VStack(spacing: 12) {
                    Text(card.questionDisplayText)
                        .font(.system(size: 36, weight: .bold))
                        .multilineTextAlignment(.center)
                    if showPinyin, let phonetic = card.displayPhonetic, !phonetic.isEmpty {
                        Text(phonetic)
                            .font(.title3)
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Button {
                        HapticFeedback.impact()
                        speechManager.speak(text: card.questionDisplayText)
                    } label: {
                        Image(systemName: speechManager.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.primary)
                    }
                    .buttonStyle(HapticButtonStyle())
                }
                .padding(28)
                .frame(maxWidth: .infinity)
                .cardStyle()

                if showFeedback {
                    feedbackSection(card: card)
                } else {
                    // Options
                    VStack(spacing: 12) {
                        ForEach(options, id: \.label) { opt in
                            OptionButton(
                                text: "\(opt.label). \(opt.meaning)",
                                isSelected: selectedAnswer == opt.label,
                                isCorrect: showFeedback && opt.meaning == card.answer,
                                isWrong: showFeedback && selectedAnswer == opt.label && opt.meaning != card.answer
                            ) {
                                guard !showFeedback else { return }
                                selectedAnswer = opt.label
                                let correct = opt.meaning == card.answer
                                lastCorrect = correct
                                showFeedback = true
                                totalAnswered += 1
                                if correct { score += 1 }
                                recordAnswer(card: card, correct: correct)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    private func feedbackSection(card: Flashcard) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: lastCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(lastCorrect ? AppTheme.accentGreen : AppTheme.accentRed)
                Text(lastCorrect ? "Đúng rồi!" : "Sai - Đáp án: \(card.answer)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(lastCorrect ? AppTheme.accentGreen : AppTheme.accentRed)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background((lastCorrect ? AppTheme.accentGreen : AppTheme.accentRed).opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            PracticeHintCard(card: card)

            // Show similarity info
            if card.id != sourceFlashcard.id {
                similarityInfo(card: card)
            }

            Button {
                HapticFeedback.impact()
                if currentIndex + 1 >= similarCards.count {
                    showResult = true
                } else {
                    currentIndex += 1
                    selectedAnswer = nil
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
    }

    private func similarityInfo(card: Flashcard) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("So sánh")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.textSecondary)

            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text(sourceFlashcard.questionDisplayText)
                        .font(.title3)
                        .fontWeight(.bold)
                    if let p = sourceFlashcard.displayPhonetic, !p.isEmpty {
                        Text(p)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Text(sourceFlashcard.answer)
                        .font(.caption)
                        .foregroundStyle(AppTheme.primary)
                }
                .frame(maxWidth: .infinity)

                Image(systemName: "arrow.left.arrow.right")
                    .foregroundStyle(AppTheme.textSecondary)

                VStack(spacing: 4) {
                    Text(card.questionDisplayText)
                        .font(.title3)
                        .fontWeight(.bold)
                    if let p = card.displayPhonetic, !p.isEmpty {
                        Text(p)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Text(card.answer)
                        .font(.caption)
                        .foregroundStyle(AppTheme.primary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func generateOptions(for card: Flashcard) -> [(label: String, meaning: String)] {
        let correct = card.answer
        let others = similarCards.map(\.answer).filter { $0 != correct }.shuffled()
        var wrong = Array(others.prefix(3))
        // If not enough wrong answers from similar cards, pad from all flashcards
        if wrong.count < 3 {
            let allCards = DatabaseManager.shared.loadAllFlashcards()
            let moreWrong = allCards.map(\.answer).filter { $0 != correct && !wrong.contains($0) }.shuffled()
            wrong += Array(moreWrong.prefix(3 - wrong.count))
        }
        var list = (wrong + [correct]).shuffled()
        let labels = ["A", "B", "C", "D"]
        return Array(list.prefix(4)).enumerated().map { (labels[$0], $1) }
    }

    private func recordAnswer(card: Flashcard, correct: Bool) {
        DatabaseManager.shared.ensureProgressExists(flashcardId: card.id)
        if var progress = DatabaseManager.shared.getFlashcardProgress(flashcardId: card.id) {
            progress.totalReviews += 1
            if correct { progress.correctReviews += 1 }
            else {
                progress.incorrectReviews += 1
                DatabaseManager.shared.recordMistake(flashcardId: card.id, practiceType: "Từ tương tự", topicId: 0)
            }
            DatabaseManager.shared.saveFlashcardProgress(progress)
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        DatabaseManager.shared.recordPracticeSession(
            practiceDate: formatter.string(from: Date()),
            practiceType: "Từ tương tự",
            topicId: 0,
            correct: correct ? 1 : 0,
            total: 1
        )
    }
}
