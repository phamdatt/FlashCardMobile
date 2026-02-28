//
//  ReviewScreen.swift
//  FlashCardMobile
//

import SwiftUI

struct ReviewScreen: View {
    @ObservedObject var viewModel: ReviewViewModel
    @ObservedObject var appViewModel: AppViewModel

    @State private var showSRSReview = false
    @State private var showRandomPractice = false
    @State private var showMistakesPractice = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    streakCard
                    srsSection
                    randomDailySection
                    mistakesSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(AppTheme.surface)
            .navigationTitle(L("review.title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        appViewModel.selectedTabIndex = 2
                    } label: {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            }
            .onAppear {
                viewModel.loadDue()
                viewModel.loadMistakes()
                viewModel.refreshStreak()
            }
            .fullScreenCover(isPresented: $showSRSReview) {
                SRSReviewSession(viewModel: viewModel)
            }
            .fullScreenCover(isPresented: $showRandomPractice) {
                RandomPracticeSession(appViewModel: appViewModel)
            }
            .fullScreenCover(isPresented: $showMistakesPractice) {
                MistakesPracticeSession(appViewModel: appViewModel)
            }
        }
    }

    // MARK: - Streak Card (compact, tap to see detail)

    private var streakCard: some View {
        Button {
            appViewModel.selectedTabIndex = 3 // Navigate to Statistics tab
        } label: {
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: appViewModel.streakInfo.didPracticeToday ? "flame.fill" : "flame")
                        .font(.title3)
                        .foregroundStyle(appViewModel.streakInfo.didPracticeToday ? AppTheme.accentOrange : AppTheme.textSecondary)
                    Text(L("review.streak_days", appViewModel.streakInfo.currentStreak))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }

                Divider()
                    .frame(height: 20)

                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.primary)
                    Text(L("review.due_count", viewModel.dueCount))
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }

                Spacer()

                Image(systemName: "chart.bar.fill")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    // MARK: - SRS Section

    private var srsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L("review.srs_title"), systemImage: "calendar.badge.clock")
                .font(.headline)

            Button {
                HapticFeedback.impact()
                showSRSReview = true
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(AppTheme.heroGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.dueCount > 0 ? L("review.srs_due", viewModel.dueCount) : L("review.srs_done"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Text(L("review.srs_subtitle"))
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    if viewModel.dueCount > 0 {
                        Text(L("common.start"))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.primary)
                            .clipShape(Capsule())
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.accentGreen)
                            .font(.title3)
                    }
                }
                .padding(16)
                .cardStyle()
            }
            .buttonStyle(HapticButtonStyle())
            .disabled(viewModel.dueCount == 0)
        }
    }

    // MARK: - Random Daily Section

    private var randomDailySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L("review.daily_title"), systemImage: "sparkles")
                .font(.headline)

            Button {
                HapticFeedback.impact()
                showRandomPractice = true
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "shuffle")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(
                            LinearGradient(
                                colors: [AppTheme.accentGreen, Color(red: 0.15, green: 0.65, blue: 0.55)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("review.daily_words"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Text(L("review.daily_subtitle"))
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(16)
                .cardStyle()
            }
            .buttonStyle(HapticButtonStyle())
        }
    }

    // MARK: - Mistakes Section

    private var mistakesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L("review.mistakes_title"), systemImage: "exclamationmark.triangle.fill")
                .font(.headline)

            if viewModel.mistakeCount == 0 {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.accentGreen)
                    Text(L("review.no_mistakes"))
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
            } else {
                Button {
                    HapticFeedback.impact()
                    showMistakesPractice = true
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(
                                LinearGradient(
                                    colors: [AppTheme.accentRed, AppTheme.accentOrange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L("review.mistakes_count", viewModel.mistakeCount))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            Text(L("review.mistakes_subtitle"))
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(16)
                    .cardStyle()
                }
                .buttonStyle(HapticButtonStyle())
            }
        }
    }
}

// MARK: - SRS Review Session (Full Screen)

struct SRSReviewSession: View {
    @ObservedObject var viewModel: ReviewViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.surface
                .ignoresSafeArea()

            VStack(spacing: 0) {
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
                    Text("\(viewModel.currentIndex + 1) / \(viewModel.cards.count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(AppTheme.textSecondary)
                    Spacer()
                }
                .padding()

                if viewModel.showComplete {
                    Spacer()
                    VStack(spacing: 24) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(AppTheme.accentOrange)
                            .onAppear { SoundEffect.playComplete() }
                        Text(L("review.complete_title"))
                            .font(.title)
                            .fontWeight(.bold)
                        Text(L("review.complete_message"))
                            .font(.body)
                            .foregroundStyle(AppTheme.textSecondary)
                        Button {
                            HapticFeedback.impact()
                            dismiss()
                        } label: {
                            Text(L("common.close"))
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.primaryGradient)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal, 40)
                    }
                    Spacer()
                } else if let card = viewModel.currentCard {
                    Spacer()
                    VStack(spacing: 24) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(AppTheme.heroGradient)
                                .shadow(color: AppTheme.primary.opacity(0.15), radius: 12, x: 0, y: 4)
                                .frame(height: 280)

                            VStack(spacing: 12) {
                                if viewModel.showAnswer {
                                    Text(card.answer)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                } else {
                                    Text(card.questionDisplayText)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                        .multilineTextAlignment(.center)
                                        .padding()
                                    if let phonetic = card.displayPhonetic, !phonetic.isEmpty {
                                        Text(phonetic)
                                            .font(.subheadline)
                                            .foregroundStyle(.white.opacity(0.9))
                                    }
                                }
                            }
                        }
                        .onTapGesture {
                            HapticFeedback.impact()
                            if viewModel.showAnswer {
                                viewModel.submitQuality(card: card, quality: 1.0)
                            } else {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    viewModel.revealAnswer()
                                }
                            }
                        }

                        Text(viewModel.showAnswer ? L("review.tap_continue") : L("review.tap_reveal"))
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    Spacer()
                }
            }
        }
        .onAppear {
            viewModel.loadDue()
        }
    }
}

// MARK: - Random Practice Session

struct RandomPracticeSession: View {
    @ObservedObject var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var cards: [Flashcard] = []
    @State private var currentIndex = 0
    @State private var selectedAnswer: String?
    @State private var showFeedback = false
    @State private var lastCorrect = false
    @State private var score = 0
    @State private var totalAnswered = 0
    @State private var showResult = false
    @State private var currentOptions: [(label: String, meaning: String)] = []

    var body: some View {
        ZStack {
            AppTheme.surface
                .ignoresSafeArea()

            VStack(spacing: 0) {
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
                    if !cards.isEmpty {
                        Text("\(currentIndex + 1) / \(cards.count)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                }
                .padding()

                if cards.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        L("review.no_vocab"),
                        systemImage: "rectangle.stack",
                        description: Text(L("review.no_vocab_desc"))
                    )
                    Spacer()
                } else if currentIndex < cards.count {
                    practiceContent
                }
            }
        }
        .onAppear {
            cards = DatabaseManager.shared.loadAllFlashcards(limit: 20)
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
            PracticeResultSheet(score: score, total: totalAnswered, practiceType: L("review.random_daily"), topicId: 0) {
                showResult = false
                dismiss()
            }
        }
    }

    private var practiceContent: some View {
        let card = cards[currentIndex]
        return ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text(card.questionDisplayText)
                        .font(.system(size: 36, weight: .bold))
                        .multilineTextAlignment(.center)
                    if let phonetic = card.displayPhonetic, !phonetic.isEmpty {
                        Text(phonetic)
                            .font(.title3)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .padding(28)
                .frame(maxWidth: .infinity)
                .cardStyle()

                if showFeedback {
                    VStack(spacing: 6) {
                        HStack {
                            Image(systemName: lastCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(lastCorrect ? AppTheme.accentGreen : AppTheme.accentRed)
                            Text(lastCorrect ? L("practice.correct") : L("practice.wrong_answer", card.answer))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(lastCorrect ? AppTheme.accentGreen : AppTheme.accentRed)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background((lastCorrect ? AppTheme.accentGreen : AppTheme.accentRed).opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

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

    private func computeOptions(for card: Flashcard) -> [(label: String, meaning: String)] {
        let correct = card.answer
        let others = cards.map(\.answer).filter { $0 != correct }.shuffled()
        let wrong = Array(others.prefix(3))
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
                DatabaseManager.shared.recordMistake(flashcardId: card.id, practiceType: L("review.random_daily"), topicId: 0)
            }
            DatabaseManager.shared.saveFlashcardProgress(progress)
        }
    }
}

// MARK: - Mistakes Practice Session

struct MistakesPracticeSession: View {
    @ObservedObject var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var cards: [Flashcard] = []
    @State private var currentIndex = 0
    @State private var selectedAnswer: String?
    @State private var showFeedback = false
    @State private var lastCorrect = false
    @State private var score = 0
    @State private var totalAnswered = 0
    @State private var showResult = false
    @State private var currentOptions: [(label: String, meaning: String)] = []
    @State private var allCards: [Flashcard] = []

    var body: some View {
        ZStack {
            AppTheme.surface
                .ignoresSafeArea()

            VStack(spacing: 0) {
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
                    if !cards.isEmpty {
                        Text("\(currentIndex + 1) / \(cards.count)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                }
                .padding()

                if cards.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        L("review.no_mistakes_title"),
                        systemImage: "checkmark.seal",
                        description: Text(L("review.no_mistakes_desc"))
                    )
                    Spacer()
                } else if currentIndex < cards.count {
                    practiceContent
                }
            }
        }
        .onAppear {
            let mistakeIds = DatabaseManager.shared.getMistakeFlashcards(days: 30)
            cards = mistakeIds.prefix(20).compactMap { DatabaseManager.shared.loadFlashcard(byId: $0) }.shuffled()
            allCards = DatabaseManager.shared.loadAllFlashcards(limit: 50)
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
            PracticeResultSheet(score: score, total: totalAnswered, practiceType: L("review.mistakes_type"), topicId: 0) {
                showResult = false
                dismiss()
            }
        }
    }

    private var practiceContent: some View {
        let card = cards[currentIndex]
        return ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text(card.questionDisplayText)
                        .font(.system(size: 36, weight: .bold))
                        .multilineTextAlignment(.center)
                    if let phonetic = card.displayPhonetic, !phonetic.isEmpty {
                        Text(phonetic)
                            .font(.title3)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .padding(28)
                .frame(maxWidth: .infinity)
                .cardStyle()

                if showFeedback {
                    VStack(spacing: 6) {
                        HStack {
                            Image(systemName: lastCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(lastCorrect ? AppTheme.accentGreen : AppTheme.accentRed)
                            Text(lastCorrect ? L("practice.correct") : L("practice.wrong_answer", card.answer))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(lastCorrect ? AppTheme.accentGreen : AppTheme.accentRed)
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

    private func computeOptions(for card: Flashcard) -> [(label: String, meaning: String)] {
        let correct = card.answer
        let pool = (allCards + cards).map(\.answer).filter { $0 != correct }
        let wrong = Array(Set(pool).shuffled().prefix(3))
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
                DatabaseManager.shared.recordMistake(flashcardId: card.id, practiceType: L("review.mistakes_type"), topicId: 0)
            }
            DatabaseManager.shared.saveFlashcardProgress(progress)
        }
    }
}
