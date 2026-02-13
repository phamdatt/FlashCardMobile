//
//  ListeningPracticeScreen.swift
//  FlashCardMobile
//

import SwiftUI

struct ListeningPracticeScreen: View {
    let topic: Topic
    let subject: Subject
    @Environment(\.dismiss) private var dismiss
    @StateObject private var speechManager = SpeechManager.shared
    @State private var cards: [Flashcard] = []
    @State private var currentIndex = 0
    @State private var selectedAnswer: String?
    @State private var showFeedback = false
    @State private var lastCorrect = false
    @State private var score = 0
    @State private var totalAnswered = 0
    @State private var showResult = false
    @State private var currentOptions: [(label: String, meaning: String)] = []
    @AppStorage("practice_show_pinyin") private var showPinyin = true

    private var languageForTTS: String? {
        subject.name == "Tiếng Trung" ? "zh" : "en"
    }

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
                    listeningContent
                } else {
                    Spacer()
                    doneView
                }
            }
        }
        .onAppear {
            cards = topic.flashcards.shuffled()
            if !cards.isEmpty {
                currentOptions = computeOptions(for: cards[currentIndex])
            }
        }
        .onChange(of: currentIndex) { _, newIndex in
            if newIndex < cards.count {
                currentOptions = computeOptions(for: cards[newIndex])
            }
        }
        .sheet(isPresented: $showResult) {
            PracticeResultSheet(score: score, total: totalAnswered) {
                showResult = false
                dismiss()
            }
        }
    }

    private var progressBar: some View {
        VStack(spacing: 12) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Text("\(currentIndex + 1) / \(cards.count)")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
            }
            pinyinToggle
        }
        .padding()
    }

    private var pinyinToggle: some View {
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

    private var emptyState: some View {
        ContentUnavailableView(
            "Không có thẻ",
            systemImage: "speaker.slash",
            description: Text("Chủ đề này chưa có từ để luyện nghe.")
        )
    }

    private var doneView: some View {
        VStack(spacing: 16) {
            Text("Hoàn thành!")
                .font(.title2)
                .fontWeight(.bold)
            Button("Đóng") {
                HapticFeedback.impact()
                dismiss()
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.primaryGradient)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 40)
        }
    }

    private var listeningContent: some View {
        let card = cards[currentIndex]
        return ScrollView {
            VStack(spacing: 24) {
                Text("Nghe và chọn nghĩa đúng")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textSecondary)

                Button {
                    HapticFeedback.impact()
                    speechManager.speak(text: card.questionDisplayText, language: languageForTTS)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: speechManager.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 28))
                        Text(speechManager.isSpeaking ? "Đang phát..." : "Phát âm")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(HapticButtonStyle())
                .disabled(speechManager.isSpeaking)

                if showFeedback {
                    VStack(spacing: 6) {
                        HStack {
                            Image(systemName: lastCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(lastCorrect ? AppTheme.accentGreen : AppTheme.accentRed)
                            Text(lastCorrect ? "Đúng rồi!" : "Sai - Đáp án: \(card.answer)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(lastCorrect ? AppTheme.accentGreen : AppTheme.accentRed)
                        }
                        if !lastCorrect, showPinyin, let phonetic = card.displayPhonetic, !phonetic.isEmpty {
                            Text("\(card.questionDisplayText) — \(phonetic)")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background((lastCorrect ? AppTheme.accentGreen : AppTheme.accentRed).opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    PracticeHintCard(card: card)

                    Button {
                        HapticFeedback.impact()
                        if currentIndex + 1 >= cards.count {
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
                } else {
                    VStack(spacing: 12) {
                        ForEach(currentOptions, id: \.label) { opt in
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

    private func computeOptions(for card: Flashcard) -> [(label: String, meaning: String)] {
        let correct = card.answer
        let others = cards.map(\.answer).filter { $0 != correct }.shuffled()
        let wrong = Array(others.prefix(3))
        var list = (wrong + [correct]).shuffled()
        let labels = ["A", "B", "C", "D"]
        return list.prefix(4).enumerated().map { (labels[$0], $1) }
    }

    private func recordAnswer(card: Flashcard, correct: Bool) {
        DatabaseManager.shared.ensureProgressExists(flashcardId: card.id)
        if var progress = DatabaseManager.shared.getFlashcardProgress(flashcardId: card.id) {
            progress.totalReviews += 1
            if correct { progress.correctReviews += 1 }
            else {
                progress.incorrectReviews += 1
                DatabaseManager.shared.recordMistake(flashcardId: card.id, practiceType: "Nghe → chọn", topicId: topic.id)
            }
            DatabaseManager.shared.saveFlashcardProgress(progress)
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        DatabaseManager.shared.recordPracticeSession(
            practiceDate: formatter.string(from: Date()),
            practiceType: "Nghe → chọn",
            topicId: topic.id,
            correct: correct ? 1 : 0,
            total: 1
        )
    }
}
