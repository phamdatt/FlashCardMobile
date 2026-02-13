//
//  ReviewViewModel.swift
//  FlashCardMobile
//

import Foundation
import Combine

@MainActor
final class ReviewViewModel: ObservableObject {
    @Published private(set) var dueIds: [Int] = []
    @Published private(set) var cards: [Flashcard] = []
    @Published var currentIndex = 0
    @Published var showAnswer = false
    @Published var showQualityButtons = false
    @Published var showComplete = false

    private let db = DatabaseManager.shared
    private weak var appViewModel: AppViewModel?

    var currentCard: Flashcard? {
        guard currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    var hasCards: Bool { !cards.isEmpty }
    var isEmpty: Bool { dueIds.isEmpty && !showComplete }

    init(appViewModel: AppViewModel? = nil) {
        self.appViewModel = appViewModel
    }

    func loadDue() {
        dueIds = db.getDueFlashcards()
        cards = dueIds.compactMap { db.loadFlashcard(byId: $0) }
        currentIndex = 0
        showAnswer = false
        showQualityButtons = false
        showComplete = false
    }

    func refreshStreak() {
        appViewModel?.refreshStreak()
    }

    func submitQuality(card: Flashcard, quality: Double) {
        db.ensureProgressExists(flashcardId: card.id)
        if var progress = db.getFlashcardProgress(flashcardId: card.id) {
            progress.totalReviews += 1
            if quality >= 0.8 {
                progress.correctReviews += 1
            } else {
                progress.incorrectReviews += 1
                if let topic = findTopic(for: card) {
                    db.recordMistake(flashcardId: card.id, practiceType: "SRS", topicId: topic.id)
                }
            }
            if quality >= 0.8 {
                progress.interval = max(1, progress.interval + 1)
                progress.nextReviewDate = Calendar.current.date(byAdding: .day, value: progress.interval, to: Date()) ?? Date()
            } else {
                progress.interval = 1
                progress.nextReviewDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            }
            progress.lastReviewDate = Date()
            db.saveFlashcardProgress(progress)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let topic = findTopic(for: card) {
            db.recordPracticeSession(
                practiceDate: formatter.string(from: Date()),
                practiceType: "SRS",
                topicId: topic.id,
                correct: quality >= 0.8 ? 1 : 0,
                total: 1
            )
        }

        if currentIndex + 1 >= cards.count {
            showComplete = true
        } else {
            currentIndex += 1
            showAnswer = false
            showQualityButtons = false
        }
    }

    func revealAnswer() {
        showAnswer = true
        showQualityButtons = true
    }

    private func findTopic(for card: Flashcard) -> Topic? {
        appViewModel?.subjects.flatMap { $0.topics }.first { topic in
            topic.flashcards.contains { $0.id == card.id }
        }
    }
}
