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
    @State private var showSettings = false
    @State private var currentOptions: [(label: String, meaning: String)] = []
    @State private var wrongAnswerPool: [String] = []
    @State private var phoneticRevealed = false
    @AppStorage("practice_show_pinyin") private var showPinyin = true

    var body: some View {
        ZStack {
            AppTheme.surface
                .ignoresSafeArea()

            VStack(spacing: 0) {
                progressBar
                if isLoading {
                    Spacer()
                    ProgressView(L("similar.loading"))
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
        .task { await loadSimilarCards() }
        .onChange(of: currentIndex) { _, newIndex in
            if newIndex < similarCards.count {
                currentOptions = computeOptions(for: similarCards[newIndex])
            }
        }
        .sheet(isPresented: $showResult) {
            PracticeResultSheet(score: score, total: totalAnswered, practiceType: "Từ tương tự", topicId: 0) {
                showResult = false
                dismiss()
            }
        }
    }

    private func loadSimilarCards() async {
        isLoading = true
        let source = sourceFlashcard
        let (found, pool) = await Task.detached {
            let similar = DatabaseManager.shared.findSimilarFlashcards(for: source)
            let extra = DatabaseManager.shared.loadAllFlashcards(limit: 30).map(\.answer)
            return (similar, extra)
        }.value
        var allCards = [sourceFlashcard] + found
        allCards.shuffle()
        similarCards = allCards
        wrongAnswerPool = pool
        if !allCards.isEmpty {
            currentOptions = computeOptions(for: allCards[currentIndex])
        }
        isLoading = false
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
            if !similarCards.isEmpty {
                Text("\(currentIndex + 1) / \(similarCards.count)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(AppTheme.textSecondary)
            }
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
            L("similar.not_found"),
            systemImage: "character.book.closed",
            description: Text(L("similar.not_found_desc"))
        )
    }

    private var practiceContent: some View {
        let card = similarCards[currentIndex]
        return ScrollView {
            VStack(spacing: 20) {
                // Info banner
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(AppTheme.accentOrange)
                    Text(L("similar.banner", sourceFlashcard.questionDisplayText))
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
                    if showPinyin || phoneticRevealed, let phonetic = card.displayPhonetic, !phonetic.isEmpty {
                        Text(phonetic)
                            .font(.title3)
                            .foregroundStyle(AppTheme.textSecondary)
                            .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    }
                    if !showPinyin, !phoneticRevealed, card.displayPhonetic != nil {
                        Image(systemName: "hand.tap")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textSecondary.opacity(0.4))
                    }

                    Button {
                        HapticFeedback.impact()
                        speechManager.speak(text: card.questionDisplayText)
                    } label: {
                        Image(systemName: speechManager.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                            .font(.title3)
                            .symbolEffect(.variableColor.iterative, isActive: speechManager.isSpeaking)
                            .foregroundStyle(AppTheme.primary)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(AppTheme.primary.opacity(0.1))
                                    .overlay(
                                        SpeakingRippleEffect(isActive: speechManager.isSpeaking, color: AppTheme.primary)
                                    )
                            )
                    }
                    .buttonStyle(HapticButtonStyle())
                }
                .padding(28)
                .frame(maxWidth: .infinity)
                .cardStyle()
                .onTapGesture {
                    if !showPinyin {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            phoneticRevealed.toggle()
                        }
                    }
                }

                if showFeedback {
                    feedbackSection(card: card)
                } else {
                    // Options
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
                                if correct { SoundEffect.playCorrect() } else { SoundEffect.playWrong() }
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
                Text(lastCorrect ? L("practice.correct") : L("practice.wrong_answer", card.answer))
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
                    phoneticRevealed = false
                }
            } label: {
                HStack(spacing: 8) {
                    Text(L("common.continue"))
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
            // Show similarity reason tags
            HStack(spacing: 6) {
                Text(L("similar.compare"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                ForEach(similarityReasons(card: card), id: \.self) { reason in
                    Text(reason)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(AppTheme.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.primary.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

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

    private func similarityReasons(card: Flashcard) -> [String] {
        var reasons: [String] = []
        let srcPinyin = DatabaseManager.normalizePinyin(sourceFlashcard.displayPhonetic ?? "")
        let cardPinyin = DatabaseManager.normalizePinyin(card.displayPhonetic ?? "")
        if !srcPinyin.isEmpty && !cardPinyin.isEmpty {
            if srcPinyin == cardPinyin {
                reasons.append(L("similar.same_pinyin"))
            } else {
                let srcSyl = Set(srcPinyin.split(separator: " ").map(String.init))
                let cardSyl = Set(cardPinyin.split(separator: " ").map(String.init))
                if !srcSyl.intersection(cardSyl).isEmpty {
                    reasons.append(L("similar.similar_pinyin"))
                }
            }
        }
        let srcHanzi = sourceFlashcard.questionDisplayText
        let cardHanzi = card.questionDisplayText
        let groups = SimilarLookingGroup.findAllGroups(for: srcHanzi)
        for group in groups {
            if group.characters.contains(where: { cardHanzi.contains($0) && !srcHanzi.contains($0) }) {
                reasons.append(L("similar.similar_char"))
                break
            }
        }
        if reasons.isEmpty {
            let srcChars = Set(srcHanzi.unicodeScalars.filter { $0.value >= 0x4E00 && $0.value <= 0x9FFF }.map(String.init))
            let cardChars = Set(cardHanzi.unicodeScalars.filter { $0.value >= 0x4E00 && $0.value <= 0x9FFF }.map(String.init))
            if !srcChars.intersection(cardChars).isEmpty {
                reasons.append(L("similar.shared_component"))
            }
        }
        return reasons
    }

    private func computeOptions(for card: Flashcard) -> [(label: String, meaning: String)] {
        let correct = card.answer
        let others = similarCards.map(\.answer).filter { $0 != correct }.shuffled()
        var wrong = Array(others.prefix(3))
        if wrong.count < 3 {
            let moreWrong = wrongAnswerPool.filter { $0 != correct && !wrong.contains($0) }.shuffled()
            wrong += Array(moreWrong.prefix(3 - wrong.count))
        }
        let list = (wrong + [correct]).shuffled()
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
    }
}
