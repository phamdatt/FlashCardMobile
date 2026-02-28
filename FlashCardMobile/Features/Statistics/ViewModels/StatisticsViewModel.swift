//
//  StatisticsViewModel.swift
//  FlashCardMobile
//

import Foundation
import Combine

@MainActor
final class StatisticsViewModel: ObservableObject {
    private let appViewModel: AppViewModel
    private let db = DatabaseManager.shared

    @Published private(set) var masteredCount = 0
    @Published private(set) var learningCount = 0
    @Published private(set) var newCount = 0
    @Published private(set) var masteredCards: [Flashcard] = []
    @Published private(set) var frequentlyWrongCards: [(flashcard: Flashcard, count: Int)] = []

    var subjects: [Subject] { appViewModel.subjects }
    var streakInfo: StreakInfo { appViewModel.streakInfo }
    var totalCards: Int {
        appViewModel.subjects.reduce(0) { $0 + $1.topics.reduce(0) { $0 + $1.flashcards.count } }
    }
    var dueCount: Int { db.getDueFlashcards().count }

    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
    }

    func loadData() {
        appViewModel.loadData()
        let masteredIds = db.getMasteredFlashcardIds()
        let learningIds = db.getLearningFlashcardIds()
        masteredCount = masteredIds.count
        learningCount = learningIds.count
        newCount = max(0, totalCards - masteredCount - learningCount)
    }

    func loadMasteredCards() {
        let ids = db.getMasteredFlashcardIds()
        masteredCards = ids.compactMap { db.loadFlashcard(byId: $0) }
    }

    func loadFrequentlyWrongCards() {
        let wrongIds = db.getFrequentlyWrongFlashcardIds()
        frequentlyWrongCards = wrongIds.compactMap { item in
            guard let card = db.loadFlashcard(byId: item.id) else { return nil }
            return (flashcard: card, count: item.count)
        }
    }
}
